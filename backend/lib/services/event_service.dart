import 'dart:async';
import 'dart:convert';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/firebase_config.dart';
import 'package:backend/models/event.dart';
import 'package:backend/utils/response_helper.dart';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Service for fetching events from Firestore.
///
/// Handles querying the events collection with filtering, search, and
/// cursor-based pagination.
class EventService {
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
      'private_key': envMap['FIREBASE_SERVICE_ACCOUNT_KEY']?.replaceAll(r'\n', '\n'),
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

  /// Fetches events with optional filtering and pagination.
  ///
  /// - Fetches events ordered by event_id (uses single-field index)
  /// - Applies `status == "approved"` and `is_deleted == false` filters client-side
  /// - `tags`: comma-separated, URL-decoded, matched case-sensitively
  /// - `search`: case-insensitive substring match on title
  /// - `cursor`: base64-encoded JSON `{eventId}` for pagination
  /// - `limit`: max number of results after client-side filtering (default 20)
  static Future<List<Event>> fetchEvents({
    String? tags,
    String? search,
    String? cursor,
    int limit = 20,
  }) async {
    if (cursor != null) {
      try {
        final decoded = jsonDecode(utf8.decode(base64.decode(cursor)));
        if (decoded is! Map<String, dynamic> ||
            !decoded.containsKey('eventId')) {
          throw EventException(EventErrorCode.invalidCursor, 'Invalid cursor');
        }
      } catch (e) {
        if (e is EventException) rethrow;
        throw EventException(EventErrorCode.invalidCursor, 'Invalid cursor');
      }
    }

    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();

    // Fetch with pagination limit (may return more before client-side filtering)
    final fetchLimit = limit * 3; // Fetch extra to account for client-side filtering
    final structuredQuery = _buildQuery(
      cursor: cursor,
      limit: fetchLimit,
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
      // ignore: avoid_print
      print('Firestore query failed: ${response.statusCode}');
      // ignore: avoid_print
      print('Query: ${jsonEncode(structuredQuery)}');
      // ignore: avoid_print
      print('Response: ${response.body}');
      throw StateError(
        'Firestore query failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    final events = <Event>[];

    for (final entry in decoded) {
      try {
        final row = entry as Map<String, dynamic>;
        final document = row['document'] as Map<String, dynamic>?;
        if (document == null) {
          continue;
        }

        final fields = document['fields'] as Map<String, dynamic>? ?? {};
        final resourceName = document['name'] as String? ?? '';
        final eventId = resourceName.split('/').last;

        final event = _parseEventFromFields(fields, eventId);
        if (event != null) {
          events.add(event);
        }
      } catch (_) {
        // Skip malformed entries - don't let one bad document crash the whole query
        continue;
      }
    }

    // Apply client-side filters for fields that require composite indexes
    return _applyClientFilters(events, tags: tags, search: search, limit: limit);
  }

  static Map<String, dynamic> _buildQuery({
    String? cursor,
    int limit = 20,
  }) {
    // Use only single-field indexes by:
    // 1. Not filtering by status (filter client-side)
    // 2. Ordering by document ID (__name__) for pagination
    // Firestore orders by __name__ which is the document path
    final query = {
      'from': [
        {'collectionId': 'events'},
      ],
      // No filters - we'll filter client-side
      'orderBy': [
        {
          'field': {'fieldPath': '__name__'},
          'direction': 'ASCENDING',
        },
      ],
      'limit': limit,
    };

    if (cursor != null) {
      // Cursor is now based on eventId (document ID)
      final cursorData = jsonDecode(
        utf8.decode(base64.decode(cursor)),
      ) as Map<String, dynamic>;
      // Use the full document path for startAt
      query['startAt'] = ['projects/${FirebaseConfig.envMap['FIREBASE_PROJECT_ID']}/databases/(default)/documents/events/${cursorData['eventId']}'];
    }

    return query;
  }

  /// Filters events client-side for fields that require composite indexes.
  /// This is necessary because Firestore single-field indexes can only filter
  /// on one field efficiently.
  static List<Event> _applyClientFilters(
    List<Event> events, {
    String? tags,
    String? search,
    int limit = 20,
  }) {
    final filtered = events.where((event) {
      // Filter by status == "approved"
      if (event.status != 'approved') {
        return false;
      }

      // Filter by is_deleted == false
      if (event.isDeleted) {
        return false;
      }

      // Filter by tags (case-sensitive)
      if (tags != null && tags.isNotEmpty) {
        final tagSet = event.tags.toSet();
        final filterTags = tags.split(',').map((t) => t.trim()).toSet();
        // Match if ANY filter tag is in event's tags
        if (!tagSet.any((tag) => filterTags.contains(tag))) {
          return false;
        }
      }

      // Filter by search (case-insensitive on title)
      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        if (!event.title.toLowerCase().contains(searchLower)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Apply limit after filtering
    return filtered.take(limit).toList();
  }

  static Event? _parseEventFromFields(
    Map<String, dynamic> fields,
    String eventId,
  ) {
    String? stringField(String key) =>
        (fields[key] as Map<String, dynamic>?)?['stringValue'] as String?;
    int? intField(String key) {
      final value =
          (fields[key] as Map<String, dynamic>?)?['integerValue'] as String?;
      if (value == null) return null;
      return int.tryParse(value);
    }
    List<String>? arrayField(String key) {
      final arr = fields[key] as Map<String, dynamic>?;
      if (arr == null) {
        return null;
      }
      final values = arr['arrayValue'] as Map<String, dynamic>?;
      if (values == null) {
        return null;
      }
      final fieldValues = values['values'] as List<dynamic>?;
      if (fieldValues == null) {
        return null;
      }
      return fieldValues.whereType<Map<String, dynamic>>().map((map) {
        return (map['stringValue'] as String?) ?? '';
      }).toList();
    }

    final title = stringField('title');
    if (title == null) {
      return null;
    }

    // eventId is derived from document ID (resourceName)
    // This is the unique identifier for the event
    final eventIdFromDoc = eventId;

    // Extract status field
    final status = stringField('status') ?? 'draft';

    // Extract is_deleted field safely
    final isDeleted = () {
      final field = fields['is_deleted'];
      if (field is Map<String, dynamic>) {
        final boolValue = field['booleanValue'];
        if (boolValue is bool) return boolValue;
      }
      return false;
    }();

    return Event(
      eventId: eventIdFromDoc,
      title: title,
      coverImageUrl: stringField('cover_image_url') ?? '',
      date: stringField('date') ?? '',
      startTime: stringField('start_time') ?? '',
      endTime: stringField('end_time') ?? '',
      tags: arrayField('tags') ?? [],
      slotsTotal: intField('slots_total') ?? 0,
      registeredCount: intField('registered_count') ?? 0,
      status: status,
      isDeleted: isDeleted,
    );
  }
}

/// Exception thrown when event operations fail.
class EventException extends AppException {
  EventException(super.code, super.message);
}