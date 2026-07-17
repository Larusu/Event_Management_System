import 'dart:convert';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/firebase_config.dart';
import 'package:backend/models/event.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Firestore-backed event operations.
///
/// On failure, every method throws [AuthException] — callers (routes)
/// catch this one type and hand it to [ResponseHelper.error].
class FirebaseEventService {
  /// Returns full detail for a single approved, non-deleted event.
  ///
  /// Throws [AuthException] with EVT002 when the event does not exist,
  /// is soft-deleted, or has `status != approved`. All three cases use
  /// the same error so the API never reveals whether an unapproved event
  /// exists.
  static Future<Event> getEventById(String eventId) async {
    final doc = await _getEventDocument(eventId);

    if (doc == null || !_isPubliclyVisible(doc)) {
      throw AuthException(EventErrorCode.notFound, 'Event not found.');
    }

    return _toEvent(eventId, doc);
  }

  /// Returns the raw Firestore document for [eventId], or null if missing.
  ///
  /// Unlike [getEventById], this does not filter by approval status — used by
  /// moderation and write endpoints.
  static Future<Map<String, dynamic>?> getEventDocument(String eventId) async {
    return _getEventDocument(eventId);
  }

  /// Patches specific fields on `events/{eventId}` via the Firestore REST API.
  static Future<void> patchEvent(
    String eventId,
    Map<String, dynamic> fields,
  ) async {
    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();

    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents/events/$eventId',
    );

    final fieldPaths =
        fields.keys.map((k) => 'updateMask.fieldPaths=$k').join('&');
    final patchUri = Uri.parse('$uri?$fieldPaths');

    final encodedFields = <String, dynamic>{};
    for (final entry in fields.entries) {
      final value = entry.value;
      if (value == null) {
        encodedFields[entry.key] = {'nullValue': null};
      } else if (value is bool) {
        encodedFields[entry.key] = {'booleanValue': value};
      } else if (value is int) {
        encodedFields[entry.key] = {'integerValue': value.toString()};
      } else if (value is String) {
        encodedFields[entry.key] = entry.key.endsWith('_at')
            ? {'timestampValue': value}
            : {'stringValue': value};
      } else {
        throw ArgumentError(
          'Unsupported field type for ${entry.key}: ${value.runtimeType}',
        );
      }
    }

    final response = await client.patch(
      patchUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': encodedFields}),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Firestore patch failed for events/$eventId: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  /// Updates an event with the given fields.
  static Future<void> updateEvent(
    String eventId,
    Map<String, dynamic> updates,
  ) async {
    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();

    final timeNow = DateTime.now().toUtc().toIso8601String();
    final updatesWithTimestamp = {
      ...updates,
      'updated_at': timeNow,
    };

    final baseUri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents/events/$eventId',
    );
    final fieldPaths = updatesWithTimestamp.keys
        .map((k) => 'updateMask.fieldPaths=$k')
        .join('&');
    final patchUri = Uri.parse('$baseUri?$fieldPaths');

    final response = await client.patch(
      patchUri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fields': _encodeFirestoreFields(updatesWithTimestamp),
      }),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Firestore update failed for events/$eventId: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  /// Soft deletes an event by setting is_deleted=true and updated_at.
  static Future<void> softDeleteEvent(String eventId) async {
    final timeNow = DateTime.now().toUtc().toIso8601String();
    await updateEvent(eventId, {'is_deleted': true, 'updated_at': timeNow});
  }

  static Map<String, dynamic> _encodeFirestoreFields(
    Map<String, dynamic> fields,
  ) {
    final result = <String, dynamic>{};

    for (final entry in fields.entries) {
      final key = entry.key;
      final value = entry.value;

      if (value == null) {
        result[key] = {'nullValue': null};
      } else if (value is String) {
        result[key] = {'stringValue': value};
      } else if (value is bool) {
        result[key] = {'booleanValue': value};
      } else if (value is int) {
        result[key] = {'integerValue': value.toString()};
      } else if (value is double) {
        result[key] = {'doubleValue': value};
      } else if (value is List<String>) {
        result[key] = {
          'arrayValue': {
            'values': value.map((v) => {'stringValue': v}).toList(),
          },
        };
      } else {
        result[key] = {'stringValue': value.toString()};
      }
    }

    return result;
  }

  /// Whether an event document should be returned to clients.
  ///
  /// Exposed for unit testing — routes never call this directly.
  static bool isPubliclyVisible(Map<String, dynamic> doc) =>
      _isPubliclyVisible(doc);

  static bool _isPubliclyVisible(Map<String, dynamic> doc) {
    final isDeleted = doc['is_deleted'] as bool? ?? false;
    final status = doc['status'] as String? ?? '';
    return !isDeleted && status == 'approved';
  }

  static Event _toEvent(String eventId, Map<String, dynamic> doc) {
    return Event(
      eventId: eventId,
      title: doc['title'] as String? ?? '',
      description: doc['description'] as String? ?? '',
      coverImageUrl: doc['cover_image_url'] as String? ?? '',
      date: doc['date'] as String? ?? '',
      startTime: doc['start_time'] as String? ?? '',
      endTime: doc['end_time'] as String? ?? '',
      eventMode: doc['event_mode'] as String? ?? '',
      location: doc['location'] as String?,
      streamLink: doc['stream_link'] as String?,
      hostName: doc['host_name'] as String? ?? '',
      guestSpeaker: doc['guest_speaker'] as String?,
      contactEmails: List<String>.from(
        doc['contact_emails'] as List<dynamic>? ?? const [],
      ),
      tags: List<String>.from(doc['tags'] as List<dynamic>? ?? const []),
      isOpenToGuests: doc['is_open_to_guests'] as bool? ?? false,
      slotsTotal: doc['slots_total'] as int? ?? 0,
      registeredCount: doc['registered_count'] as int? ?? 0,
    );
  }

  static Future<Map<String, dynamic>?> _getEventDocument(String eventId) async {
    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();

    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents/events/$eventId',
    );

    final response = await client.get(uri);

    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw StateError(
        'Firestore read failed for events/$eventId: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = decoded['fields'] as Map<String, dynamic>? ?? {};
    return _decodeFirestoreFields(fields);
  }

  static Map<String, dynamic> _decodeFirestoreFields(
    Map<String, dynamic> fields,
  ) {
    String? stringField(String key) =>
        (fields[key] as Map<String, dynamic>?)?['stringValue'] as String?;

    bool? boolField(String key) =>
        (fields[key] as Map<String, dynamic>?)?['booleanValue'] as bool?;

    int? intField(String key) {
      final raw =
          (fields[key] as Map<String, dynamic>?)?['integerValue'] as String?;
      return raw == null ? null : int.tryParse(raw);
    }

    List<String> stringListField(String key) {
      final array = fields[key] as Map<String, dynamic>?;
      final values = array?['arrayValue'] as Map<String, dynamic>?;
      final items = values?['values'] as List<dynamic>? ?? const [];
      return items
          .map(
            (item) =>
                (item as Map<String, dynamic>)['stringValue'] as String? ?? '',
          )
          .where((value) => value.isNotEmpty)
          .toList();
    }

    return {
      'title': stringField('title'),
      'description': stringField('description'),
      'cover_image_url': stringField('cover_image_url'),
      'date': stringField('date'),
      'start_time': stringField('start_time'),
      'end_time': stringField('end_time'),
      'event_mode': stringField('event_mode'),
      'location': stringField('location'),
      'stream_link': stringField('stream_link'),
      'host_name': stringField('host_name'),
      'guest_speaker': stringField('guest_speaker'),
      'contact_emails': stringListField('contact_emails'),
      'tags': stringListField('tags'),
      'is_open_to_guests': boolField('is_open_to_guests'),
      'slots_total': intField('slots_total'),
      'registered_count': intField('registered_count'),
      'status': stringField('status'),
      'organizer_uid': stringField('organizer_uid'),
      'is_deleted': boolField('is_deleted'),
      'created_at': stringField('created_at'),
      'updated_at': stringField('updated_at'),
      'rejection_reason': stringField('rejection_reason'),
      'reviewed_by': stringField('reviewed_by'),
      'reviewed_at': stringField('reviewed_at'),
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
