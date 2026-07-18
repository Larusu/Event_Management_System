import 'dart:convert';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/firebase_config.dart';
import 'package:backend/services/firebase_event_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Review-queue and status-moderation logic (Feature 4, Dev C).
///
/// Kept in a dedicated service so edit/delete work in
/// [FirebaseEventService] can merge independently.
class EventModerationService {
  EventModerationService._();

  static const _batchSize = 100;
  static const _defaultPageSize = 20;

  static const _validActions = {'approve', 'reject', 'reopen'};

  /// Faculty and super_admin may access the review queue and change status.
  static bool canModerate(String? role) =>
      role == 'faculty' || role == 'super_admin';

  /// Throws [AuthException] with EVT004 when [role] cannot moderate.
  static void requireModeratorRole(String? role) {
    if (!canModerate(role)) {
      throw AuthException(
        EventErrorCode.permissionDenied,
        'You do not have permission to perform this action.',
      );
    }
  }

  /// Returns a page of pending, non-deleted events sorted by `created_at`
  /// ascending (oldest first).
  static Future<PendingEventPage> fetchPending({
    String? cursor,
    int limit = _defaultPageSize,
  }) async {
    final startAfter = _decodePendingCursor(cursor);

    final matched = <Map<String, dynamic>>[];
    Map<String, String>? batchStartAfter = startAfter;
    Map<String, String>? lastMatched;
    var exhausted = false;

    while (matched.length < limit && !exhausted) {
      final batch = await _fetchPendingBatch(startAfter: batchStartAfter);

      if (batch.docCount < _batchSize) {
        exhausted = true;
      }
      if (batch.lastDoc != null) {
        batchStartAfter = batch.lastDoc;
      }

      for (final entry in batch.entries) {
        matched.add(entry);
        lastMatched = {
          'created_at': entry['created_at'] as String? ?? '',
          'eventId': entry['event_id'] as String,
        };
        if (matched.length == limit) {
          break;
        }
      }
    }

    final nextCursor = matched.length == limit ? lastMatched : null;
    return PendingEventPage(events: matched, nextCursor: nextCursor);
  }

  /// Applies approve / reject / reopen per the 4.8 transition table.
  ///
  /// Returns the moderation summary fields for the API response.
  static Future<Map<String, dynamic>> changeStatus({
    required String eventId,
    required String reviewerUid,
    required String action,
    String? reason,
  }) async {
    if (!_validActions.contains(action)) {
      throw AuthException(
        EventErrorCode.invalidQueryParam,
        'Invalid action. Must be approve, reject, or reopen.',
      );
    }

    final doc = await FirebaseEventService.getEventDocument(eventId);
    if (doc == null) {
      throw AuthException(EventErrorCode.notFound, 'Event not found.');
    }

    final isDeleted = doc['is_deleted'] as bool? ?? false;
    if (isDeleted) {
      throw AuthException(EventErrorCode.notFound, 'Event not found.');
    }

    final currentStatus = doc['status'] as String? ?? '';
    final newStatus = _resolveNewStatus(currentStatus, action);
    if (newStatus == null) {
      throw AuthException(
        EventErrorCode.invalidStatusTransition,
        'That status change is not allowed.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final patch = <String, dynamic>{
      'status': newStatus,
      'reviewed_by': reviewerUid,
      'reviewed_at': now,
      'updated_at': now,
    };

    if (action == 'reject') {
      patch['rejection_reason'] = reason;
    } else {
      // Clear stale reason on approve/reopen.
      patch['rejection_reason'] = null;
    }

    await FirebaseEventService.patchEvent(eventId, patch);

    return {
      'event_id': eventId,
      'status': newStatus,
      'rejection_reason': action == 'reject' ? reason : null,
      'reviewed_by': reviewerUid,
      'reviewed_at': now,
    };
  }

  /// Maps (currentStatus, action) to the new status, or null if disallowed.
  static String? resolveTransition(String currentStatus, String action) {
    return _resolveNewStatus(currentStatus, action);
  }

  static String? _resolveNewStatus(String currentStatus, String action) {
    switch (action) {
      case 'approve':
        return currentStatus == 'pending' ? 'approved' : null;
      case 'reject':
        return currentStatus == 'pending' ? 'rejected' : null;
      case 'reopen':
        return currentStatus == 'rejected' ? 'pending' : null;
      default:
        return null;
    }
  }

  static Map<String, String>? _decodePendingCursor(String? cursor) {
    if (cursor == null || cursor.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(utf8.decode(base64.decode(cursor)));
      if (decoded is! Map<String, dynamic> ||
          decoded['eventId'] is! String ||
          (decoded['eventId'] as String).isEmpty ||
          decoded['created_at'] is! String) {
        throw AuthException(EventErrorCode.invalidQueryParam, 'Invalid cursor.');
      }
      return {
        'created_at': decoded['created_at'] as String,
        'eventId': decoded['eventId'] as String,
      };
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(EventErrorCode.invalidQueryParam, 'Invalid cursor.');
    }
  }

  static Future<_PendingBatch> _fetchPendingBatch({
    Map<String, String>? startAfter,
  }) async {
    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();

    final structuredQuery = _buildPendingQuery(
      projectId: projectId,
      startAfter: startAfter,
      limit: _batchSize,
    );

    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents:runQuery',
    );

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'structuredQuery': structuredQuery}),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Firestore pending query failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    final entries = <Map<String, dynamic>>[];
    var docCount = 0;
    Map<String, String>? lastDoc;

    for (final row in decoded) {
      final entry = row as Map<String, dynamic>?;
      final document = entry?['document'] as Map<String, dynamic>?;
      if (document == null) {
        continue;
      }

      docCount++;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};
      final resourceName = document['name'] as String? ?? '';
      final eventId = resourceName.split('/').last;
      final parsed = _decodeFirestoreFields(fields);

      final createdAt = parsed['created_at'] as String? ?? '';
      lastDoc = {'created_at': createdAt, 'eventId': eventId};

      final status = parsed['status'] as String? ?? '';
      final isDeleted = parsed['is_deleted'] as bool? ?? false;
      if (status != 'pending' || isDeleted) {
        continue;
      }

      entries.add({
        'event_id': eventId,
        'title': parsed['title'] as String? ?? '',
        'cover_image_url': parsed['cover_image_url'] as String? ?? '',
        'date': parsed['date'] as String? ?? '',
        'start_time': parsed['start_time'] as String? ?? '',
        'end_time': parsed['end_time'] as String? ?? '',
        'organizer_uid': parsed['organizer_uid'] as String? ?? '',
        'created_at': createdAt,
      });
    }

    return _PendingBatch(
      entries: entries,
      docCount: docCount,
      lastDoc: lastDoc,
    );
  }

  static Map<String, dynamic> _buildPendingQuery({
    required String projectId,
    Map<String, String>? startAfter,
    required int limit,
  }) {
    final query = <String, dynamic>{
      'from': [
        {'collectionId': 'events'},
      ],
      'orderBy': [
        {
          'field': {'fieldPath': 'created_at'},
          'direction': 'ASCENDING',
        },
        {
          'field': {'fieldPath': '__name__'},
          'direction': 'ASCENDING',
        },
      ],
      'limit': limit,
    };

    if (startAfter != null) {
      final docPath = 'projects/$projectId/databases/(default)'
          '/documents/events/${startAfter['eventId']}';
      query['startAt'] = {
        'values': [
          {'stringValue': startAfter['created_at']},
          {'referenceValue': docPath},
        ],
        'before': false,
      };
    }

    return query;
  }

  static Map<String, dynamic> _decodeFirestoreFields(
    Map<String, dynamic> fields,
  ) {
    String? stringField(String key) =>
        (fields[key] as Map<String, dynamic>?)?['stringValue'] as String?;

    bool? boolField(String key) =>
        (fields[key] as Map<String, dynamic>?)?['booleanValue'] as bool?;

    return {
      'title': stringField('title'),
      'cover_image_url': stringField('cover_image_url'),
      'date': stringField('date'),
      'start_time': stringField('start_time'),
      'end_time': stringField('end_time'),
      'organizer_uid': stringField('organizer_uid'),
      'created_at': stringField('created_at'),
      'status': stringField('status'),
      'is_deleted': boolField('is_deleted'),
    };
  }

  static Future<http.Client> _firestoreClient() async {
    final envMap = FirebaseConfig.envMap;
    final projectId = envMap['FIREBASE_PROJECT_ID'];
    if (projectId == null || projectId.isEmpty) {
      throw StateError('FIREBASE_PROJECT_ID missing from .env');
    }

    final credentials = ServiceAccountCredentials.fromJson({
      'type': 'service_account',
      'project_id': projectId,
      'private_key_id': envMap['FIREBASE_PRIVATE_KEY_ID'],
      'private_key':
          envMap['FIREBASE_SERVICE_ACCOUNT_KEY']?.replaceAll(r'\n', '\n'),
      'client_email': envMap['FIREBASE_CLIENT_EMAIL'],
      'client_id': envMap['FIREBASE_CLIENT_ID'],
    });

    const scopes = [
      'https://www.googleapis.com/auth/datastore',
      'https://www.googleapis.com/auth/cloud-platform',
    ];
    final authClient = await obtainAccessCredentialsViaServiceAccount(
      credentials,
      scopes,
      http.Client(),
    );
    return authenticatedClient(http.Client(), authClient);
  }

  static String _firestoreProjectId() {
    final projectId = FirebaseConfig.envMap['FIREBASE_PROJECT_ID'];
    if (projectId == null || projectId.isEmpty) {
      throw StateError('FIREBASE_PROJECT_ID missing from .env');
    }
    return projectId;
  }
}

/// A page of pending events for the review queue.
class PendingEventPage {
  PendingEventPage({required this.events, this.nextCursor});

  final List<Map<String, dynamic>> events;
  final Map<String, String>? nextCursor;
}

class _PendingBatch {
  _PendingBatch({
    required this.entries,
    required this.docCount,
    this.lastDoc,
  });

  final List<Map<String, dynamic>> entries;
  final int docCount;
  final Map<String, String>? lastDoc;
}
