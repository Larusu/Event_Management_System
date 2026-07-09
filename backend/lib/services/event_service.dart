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
  /// - Unconditionally filters `status == "approved"` AND `is_deleted == false`
  /// - `tags`: comma-separated, URL-decoded, matched via array-contains-any
  /// - `search`: case-insensitive substring match against title_search field
  /// - `cursor`: base64-encoded JSON `{date, eventId}` for pagination
  /// - `limit`: max number of results (default 20)
  /// - Results sorted by `date` ascending, then `event_id` ascending
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
            !decoded.containsKey('date') ||
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

    final structuredQuery = _buildQuery(
      tags: tags,
      search: search,
      cursor: cursor,
      limit: limit,
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
        'Firestore query failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    final events = <Event>[];

    for (final entry in decoded) {
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
    }

    return events;
  }

  static Map<String, dynamic> _buildQuery({
    String? tags,
    String? search,
    String? cursor,
    int limit = 20,
  }) {
    final filters = [
      {
        'fieldFilter': {
          'field': {'fieldPath': 'status'},
          'op': 'EQUAL',
          'value': {'stringValue': 'approved'},
        },
      },
      {
        'fieldFilter': {
          'field': {'fieldPath': 'is_deleted'},
          'op': 'EQUAL',
          'value': {'booleanValue': false},
        },
      },
    ];

    if (tags != null && tags.isNotEmpty) {
      final tagList = tags
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (tagList.isNotEmpty) {
        filters.add({
          'arrayContainsAny': {
            'field': {'fieldPath': 'tags'},
            'values': tagList.map((t) => {'stringValue': t}).toList(),
          },
        });
      }
    }

    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      filters.add({
        'fieldFilter': {
          'field': {'fieldPath': 'title_search'},
          'op': 'EQUAL',
          'value': {'stringValue': searchLower},
        },
      });
    }

    final query = {
      'from': [
        {'collectionId': 'events'},
      ],
      'where': {'compositeFilter': {'op': 'AND', 'filters': filters}},
      'orderBy': [
        {
          'field': {'fieldPath': 'date'},
          'direction': 'ASCENDING',
        },
        {
          'field': {'fieldPath': 'event_id'},
          'direction': 'ASCENDING',
        },
      ],
      'limit': limit,
    };

    if (cursor != null) {
      final cursorData = jsonDecode(
        utf8.decode(base64.decode(cursor)),
      ) as Map<String, dynamic>;
      query['startAt'] = [
        cursorData['date'],
        cursorData['eventId'],
      ];
    }

    return query;
  }

  static Event? _parseEventFromFields(
    Map<String, dynamic> fields,
    String eventId,
  ) {
    String? stringField(String key) =>
        (fields[key] as Map<String, dynamic>?)?['stringValue'] as String?;
    int? intField(String key) =>
        (fields[key] as Map<String, dynamic>?)?['integerValue'] as int?;
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
      return fieldValues.map((v) {
        final map = v as Map<String, dynamic>;
        return (map['stringValue'] as String?) ?? '';
      }).toList();
    }

    final title = stringField('title');
    if (title == null) {
      return null;
    }

    return Event(
      eventId: eventId,
      title: title,
      coverImageUrl: stringField('cover_image_url') ?? '',
      date: stringField('date') ?? '',
      startTime: stringField('start_time') ?? '',
      endTime: stringField('end_time') ?? '',
      tags: arrayField('tags') ?? [],
      slotsTotal: intField('slots_total') ?? 0,
      registeredCount: intField('registered_count') ?? 0,
    );
  }
}

/// Exception thrown when event operations fail.
class EventException extends AppException {
  EventException(super.code, super.message);
}