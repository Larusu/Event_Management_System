import 'dart:convert';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/firebase_config.dart';
import 'package:backend/services/event_service.dart';
import 'package:backend/services/firebase_event_service.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Which slice of a caller's registrations to return.
///
/// [upcoming] keeps events dated today or later (soonest first); [past] keeps
/// events dated before today (most recent first) for the registration history
/// view. Defaults to [upcoming] so existing callers are unaffected.
enum RegisteredFilter {
  /// Events dated today or later, sorted soonest first (ascending).
  upcoming,

  /// Events dated before today, sorted most recent first (descending).
  past,
}

/// Read-path for a caller's registered events, upcoming or past (Feature 5,
/// Dev B).
///
/// Uses the locked `registrations` schema (doc 5.4). Write path lives
/// separately so Dev A can own register/cancel without merge conflicts.
class RegistrationListService {
  RegistrationListService._();

  static const _batchSize = 100;
  static const _defaultPageSize = 20;

  /// Collection name locked in Feature 5 §5.4.1.
  static const collectionId = 'registrations';

  /// Returns a page of registered events for [uid].
  ///
  /// [filter] selects upcoming (`date >= today`, soonest first) or past
  /// (`date < today`, most recent first). Filters active registrations
  /// (`is_cancelled == false`), resolves each event, keeps approved /
  /// non-deleted / date-in-range, then paginates with an opaque
  /// `{date, eventId}` cursor (EVT001 if malformed).
  static Future<RegisteredEventPage> fetchRegistered({
    required String uid,
    String? cursor,
    int limit = _defaultPageSize,
    RegisteredFilter filter = RegisteredFilter.upcoming,
  }) async {
    final startAfter = decodeRegisteredCursor(cursor);
    final events = await _loadRegisteredEvents(uid, filter);
    final descending = filter == RegisteredFilter.past;

    final page = <Map<String, dynamic>>[];
    Map<String, String>? lastMatched;

    for (final event in events) {
      if (startAfter != null &&
          !_isBeyondCursor(event, startAfter, descending: descending)) {
        continue;
      }
      page.add(_listCard(event));
      lastMatched = {'date': event.date, 'eventId': event.eventId};
      if (page.length == limit) {
        break;
      }
    }

    final nextCursor = page.length == limit ? lastMatched : null;
    return RegisteredEventPage(events: page, nextCursor: nextCursor);
  }

  /// Returns the soonest upcoming registered event for [uid], or null.
  static Future<Map<String, dynamic>?> fetchNextRegistered({
    required String uid,
  }) async {
    final upcoming =
        await _loadRegisteredEvents(uid, RegisteredFilter.upcoming);
    if (upcoming.isEmpty) {
      return null;
    }
    return _nextCard(upcoming.first);
  }

  /// Decodes the opaque pagination cursor for `/events/registered`.
  ///
  /// Exposed for unit tests.
  static Map<String, String>? decodeRegisteredCursor(String? cursor) {
    if (cursor == null || cursor.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(utf8.decode(base64.decode(cursor)));
      if (decoded is! Map<String, dynamic> ||
          decoded['eventId'] is! String ||
          (decoded['eventId'] as String).isEmpty ||
          decoded['date'] is! String) {
        throw EventException(
          EventErrorCode.invalidQueryParam,
          'Invalid cursor.',
        );
      }
      return {
        'date': decoded['date'] as String,
        'eventId': decoded['eventId'] as String,
      };
    } catch (e) {
      if (e is EventException) rethrow;
      throw EventException(
        EventErrorCode.invalidQueryParam,
        'Invalid cursor.',
      );
    }
  }

  /// Whether a resolved registration should appear in the upcoming list.
  ///
  /// Keeps approved, non-deleted events dated today or later.
  /// Exposed for unit tests.
  static bool passesUpcomingFilters({
    required String status,
    required bool isDeleted,
    required String date,
    required String today,
  }) {
    if (!_passesSharedFilters(
      status: status,
      isDeleted: isDeleted,
      date: date,
    )) {
      return false;
    }
    return date.compareTo(today) >= 0;
  }

  /// Whether a resolved registration should appear in the past (history) list.
  ///
  /// Keeps approved, non-deleted events dated before today.
  /// Exposed for unit tests.
  static bool passesPastFilters({
    required String status,
    required bool isDeleted,
    required String date,
    required String today,
  }) {
    if (!_passesSharedFilters(
      status: status,
      isDeleted: isDeleted,
      date: date,
    )) {
      return false;
    }
    return date.compareTo(today) < 0;
  }

  /// Eligibility shared by both list modes: approved, not deleted, dated.
  static bool _passesSharedFilters({
    required String status,
    required bool isDeleted,
    required String date,
  }) {
    if (status != 'approved') return false;
    if (isDeleted) return false;
    if (date.isEmpty) return false;
    return true;
  }

  static Future<List<_ResolvedRegisteredEvent>> _loadRegisteredEvents(
    String uid,
    RegisteredFilter filter,
  ) async {
    final today = _todayUtcDateString();
    final regs = await _fetchActiveRegistrations(uid);
    final resolved = <_ResolvedRegisteredEvent>[];

    for (final reg in regs) {
      final eventId = reg['event_id'] as String? ?? '';
      if (eventId.isEmpty) continue;

      final doc = await FirebaseEventService.getEventDocument(eventId);
      if (doc == null) continue;

      final event = _ResolvedRegisteredEvent(
        eventId: eventId,
        title: doc['title'] as String? ?? '',
        date: doc['date'] as String? ?? '',
        startTime: doc['start_time'] as String? ?? '',
        endTime: doc['end_time'] as String? ?? '',
        location: doc['location'] as String?,
        status: doc['status'] as String? ?? '',
        isDeleted: doc['is_deleted'] as bool? ?? false,
      );

      final passes = filter == RegisteredFilter.past
          ? passesPastFilters(
              status: event.status,
              isDeleted: event.isDeleted,
              date: event.date,
              today: today,
            )
          : passesUpcomingFilters(
              status: event.status,
              isDeleted: event.isDeleted,
              date: event.date,
              today: today,
            );
      if (!passes) continue;
      resolved.add(event);
    }

    final descending = filter == RegisteredFilter.past;
    resolved.sort((a, b) {
      final byDate =
          descending ? b.date.compareTo(a.date) : a.date.compareTo(b.date);
      if (byDate != 0) return byDate;
      return descending
          ? b.eventId.compareTo(a.eventId)
          : a.eventId.compareTo(b.eventId);
    });

    return resolved;
  }

  static Future<List<Map<String, dynamic>>> _fetchActiveRegistrations(
    String uid,
  ) async {
    final active = <Map<String, dynamic>>[];
    var offset = 0;
    var exhausted = false;

    while (!exhausted) {
      final batch = await _fetchRegistrationsBatch(uid: uid, offset: offset);

      if (batch.docCount < _batchSize) {
        exhausted = true;
      }
      offset += batch.docCount;

      for (final entry in batch.entries) {
        final isCancelled = entry['is_cancelled'] as bool? ?? false;
        if (isCancelled) continue;
        active.add(entry);
      }
    }

    return active;
  }

  /// Query by `user_uid` only (single-field index); `is_cancelled` filtered
  /// client-side per Dev B notes.
  static Future<_RegistrationBatch> _fetchRegistrationsBatch({
    required String uid,
    required int offset,
  }) async {
    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();

    final query = <String, dynamic>{
      'from': [
        {'collectionId': collectionId},
      ],
      'where': {
        'fieldFilter': {
          'field': {'fieldPath': 'user_uid'},
          'op': 'EQUAL',
          'value': {'stringValue': uid},
        },
      },
      'offset': offset,
      'limit': _batchSize,
    };

    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents:runQuery',
    );

    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'structuredQuery': query}),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Firestore registrations query failed: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    final entries = <Map<String, dynamic>>[];
    var docCount = 0;

    for (final row in decoded) {
      final entry = row as Map<String, dynamic>?;
      final document = entry?['document'] as Map<String, dynamic>?;
      if (document == null) continue;

      docCount++;
      final resourceName = document['name'] as String? ?? '';
      final docId = resourceName.split('/').last;
      final fields = document['fields'] as Map<String, dynamic>? ?? {};
      entries.add(_decodeRegistrationFields(fields, docId: docId));
    }

    return _RegistrationBatch(entries: entries, docCount: docCount);
  }

  static Map<String, dynamic> _decodeRegistrationFields(
    Map<String, dynamic> fields, {
    required String docId,
  }) {
    String? stringField(String key) =>
        (fields[key] as Map<String, dynamic>?)?['stringValue'] as String?;

    bool? boolField(String key) =>
        (fields[key] as Map<String, dynamic>?)?['booleanValue'] as bool?;

    return {
      'registration_id': docId,
      'user_uid': stringField('user_uid'),
      'event_id': stringField('event_id'),
      'is_cancelled': boolField('is_cancelled') ?? false,
    };
  }

  /// Whether [event] falls strictly past [cursor] in the active sort order.
  ///
  /// For ascending (upcoming) order this means "after" the cursor; for
  /// descending (past) order it means "before" it. Matches the sort used in
  /// [_loadRegisteredEvents] so pagination stays consistent.
  static bool _isBeyondCursor(
    _ResolvedRegisteredEvent event,
    Map<String, String> cursor, {
    required bool descending,
  }) {
    final dateCmp = event.date.compareTo(cursor['date']!);
    if (dateCmp != 0) {
      return descending ? dateCmp < 0 : dateCmp > 0;
    }
    final idCmp = event.eventId.compareTo(cursor['eventId']!);
    return descending ? idCmp < 0 : idCmp > 0;
  }

  static Map<String, dynamic> _listCard(_ResolvedRegisteredEvent event) => {
        'event_id': event.eventId,
        'title': event.title,
        'date': event.date,
        'start_time': event.startTime,
        'end_time': event.endTime,
      };

  static Map<String, dynamic> _nextCard(_ResolvedRegisteredEvent event) => {
        'event_id': event.eventId,
        'title': event.title,
        'date': event.date,
        'start_time': event.startTime,
        'end_time': event.endTime,
        'location': event.location,
      };

  static String _todayUtcDateString() {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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

/// A page of registered events (upcoming or past, per the requested filter).
class RegisteredEventPage {
  /// Creates a [RegisteredEventPage].
  RegisteredEventPage({required this.events, this.nextCursor});

  /// Card-shaped registered events for this page.
  final List<Map<String, dynamic>> events;

  /// Opaque cursor payload `{date, eventId}`, or null on the last page.
  final Map<String, String>? nextCursor;
}

class _ResolvedRegisteredEvent {
  _ResolvedRegisteredEvent({
    required this.eventId,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.isDeleted,
    this.location,
  });

  final String eventId;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String? location;
  final String status;
  final bool isDeleted;
}

class _RegistrationBatch {
  _RegistrationBatch({
    required this.entries,
    required this.docCount,
  });

  final List<Map<String, dynamic>> entries;
  final int docCount;
}
