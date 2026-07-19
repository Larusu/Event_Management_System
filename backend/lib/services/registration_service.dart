import 'dart:convert';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/constants/event_exception.dart';
import 'package:backend/firebase_config.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Sole writer for the `registrations` collection and `registered_count`
/// on events. All registration and cancellation writes go through this
/// service to guarantee transactional consistency.
class RegistrationService {
  static http.Client? _testHttpClient;

  static set overrideHttpClient(http.Client client) {
    _testHttpClient = client;
  }

  static void clearHttpClientOverride() {
    _testHttpClient = null;
  }

  static Future<http.Client> _firestoreClient() async {
    if (_testHttpClient != null) {
      return _testHttpClient!;
    }
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

  /// Firestore REST base for the `(default)` database of the project.
  static String _documentsBase(String projectId) =>
      'https://firestore.googleapis.com/v1/projects/$projectId'
      '/databases/(default)/documents';

  /// Opens a read-write transaction and returns its opaque token.
  ///
  /// The token must be passed to every read (as the `transaction` query
  /// parameter) and to the final `commit` so Firestore can enforce
  /// optimistic concurrency and abort on conflicting writes.
  static Future<String> _beginTransaction(
    http.Client client,
    String projectId,
  ) async {
    final uri = Uri.parse('${_documentsBase(projectId)}:beginTransaction');
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'options': {'readWrite': <String, dynamic>{}},
      }),
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Firestore beginTransaction failed: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final token = decoded['transaction'] as String?;
    if (token == null || token.isEmpty) {
      throw StateError('Firestore beginTransaction returned no token.');
    }
    return token;
  }

  /// Commits [writes] atomically as part of [transaction].
  ///
  /// Throws `StateError('ABORTED')` when Firestore reports a conflict so the
  /// caller can retry the whole transaction.
  static Future<void> _commit(
    http.Client client,
    String projectId,
    List<Map<String, dynamic>> writes,
    String transaction,
  ) async {
    final uri = Uri.parse('${_documentsBase(projectId)}:commit');
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'writes': writes,
        'transaction': transaction,
      }),
    );

    if (response.statusCode == 409 ||
        (response.statusCode == 400 && response.body.contains('ABORTED'))) {
      throw StateError('ABORTED');
    }

    if (response.statusCode != 200) {
      throw StateError(
        'Firestore transaction commit failed: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  /// Reads the document at [path] inside [transaction]. Returns `null` when
  /// the document does not exist.
  static Future<Map<String, dynamic>?> _readDoc(
    http.Client client,
    String projectId,
    String path,
    String transaction,
  ) async {
    final uri = Uri.parse(
      '${_documentsBase(projectId)}/$path'
      '?transaction=${Uri.encodeQueryComponent(transaction)}',
    );

    final response = await client.get(uri);

    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw StateError(
        'Firestore read failed for $path: '
        '${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = decoded['fields'] as Map<String, dynamic>? ?? {};
    if (path.startsWith('events/')) {
      return _decodeEventFields(fields);
    }
    return _decodeFirestoreFields(fields, docId: path.split('/').last);
  }

  static String _registrationDocId(String uid, String eventId) =>
      '${uid}_$eventId';

  static String registrationDocId(String uid, String eventId) =>
      _registrationDocId(uid, eventId);

  static Map<String, dynamic> encodeFirestoreFields(
    Map<String, dynamic> fields,
  ) =>
      _encodeFirestoreFields(fields);

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
      } else if (value is List) {
        result[key] = {
          'arrayValue': {
            'values': value
                .map((v) => {'stringValue': v.toString()})
                .toList(),
          },
        };
      } else {
        result[key] = {'stringValue': value.toString()};
      }
    }

    return result;
  }

  static Map<String, dynamic> _decodeFirestoreFields(
    Map<String, dynamic> fields, {
    required String docId,
  }) {
    return {
      'registration_id': docId,
      'user_uid': _stringField(fields, 'user_uid'),
      'event_id': _stringField(fields, 'event_id'),
      'is_cancelled': _boolField(fields, 'is_cancelled') ?? false,
      'cancelled_at': _stringField(fields, 'cancelled_at'),
      'created_at': _stringField(fields, 'created_at'),
      'reactivated_at': _stringField(fields, 'reactivated_at'),
    };
  }

  static Map<String, dynamic> _decodeEventFields(
    Map<String, dynamic> fields,
  ) {
    return {
      'status': _stringField(fields, 'status'),
      'is_deleted': _boolField(fields, 'is_deleted') ?? false,
      'date': _stringField(fields, 'date'),
      'is_open_to_guests': _boolField(fields, 'is_open_to_guests') ?? false,
      'slots_total': _intField(fields, 'slots_total') ?? 0,
      'registered_count': _intField(fields, 'registered_count') ?? 0,
    };
  }

  static String? _stringField(Map<String, dynamic> fields, String key) =>
      (fields[key] as Map<String, dynamic>?)?['stringValue'] as String?;

  static bool? _boolField(Map<String, dynamic> fields, String key) =>
      (fields[key] as Map<String, dynamic>?)?['booleanValue'] as bool?;

  static int? _intField(Map<String, dynamic> fields, String key) {
    final raw = (fields[key] as Map<String, dynamic>?)?['integerValue'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// Registers [uid] for [eventId].
  ///
  /// All reads and writes happen inside a single Firestore transaction.
  /// On `ABORTED`, retries once. On second failure, throws
  /// [EventException] with [EventErrorCode.internalError].
  static Future<String> register(String eventId, String uid, String role) async{
    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();
    final now = DateTime.now().toUtc().toIso8601String();

    final eventPath =
        'projects/$projectId/databases/(default)/documents/events/$eventId';
    final regDocId = _registrationDocId(uid, eventId);
    final regPath =
        'projects/$projectId/databases/(default)/documents/registrations/$regDocId';

    Future<Map<String, dynamic>> attempt() async {
      final transaction = await _beginTransaction(client, projectId);
      final eventDoc =
          await _readDoc(client, projectId, 'events/$eventId', transaction);

      if (eventDoc == null) {
        throw EventException(EventErrorCode.notFound, 'Event not found.');
      }

      final isDeleted = eventDoc['is_deleted'] as bool? ?? false;
      if (isDeleted) {
        throw EventException(EventErrorCode.notFound, 'Event not found.');
      }

      final status = eventDoc['status'] as String? ?? '';
      if (status != 'approved') {
        throw EventException(EventErrorCode.notFound, 'Event not found.');
      }

      final eventDate = eventDoc['date'] as String? ?? '';
      final today = _todayUtcDateString();
      if (eventDate.isNotEmpty && eventDate.compareTo(today) < 0) {
        throw EventException(
          EventErrorCode.dateInPast,
          'Event date is in the past.',
        );
      }

      final isOpenToGuests = eventDoc['is_open_to_guests'] as bool? ?? false;
      if (role == 'guest' && !isOpenToGuests) {
        throw EventException(
          EventErrorCode.guestRegistrationLocked,
          'Event is not open to guests.',
        );
      }

      final slotsTotal = eventDoc['slots_total'] as int? ?? 0;
      final registeredCount = eventDoc['registered_count'] as int? ?? 0;
      if (registeredCount >= slotsTotal) {
        throw EventException(
          EventErrorCode.slotsFull,
          'Event is fully booked.',
        );
      }

      final regDoc = await _readDoc(
        client,
        projectId,
        'registrations/$regDocId',
        transaction,
      );

      if (regDoc != null && !(regDoc['is_cancelled'] as bool? ?? false)) {
        throw EventException(
          EventErrorCode.alreadyRegistered,
          'You are already registered for this event.',
        );
      }

      final writes = <Map<String, dynamic>>[];

      if (regDoc != null) {
        writes.add({
          'update': {
            'name': regPath,
            'fields': {
              'is_cancelled': {'booleanValue': false},
              'reactivated_at': {'stringValue': now},
            },
          },
          'updateMask': {
            'fieldPaths': ['is_cancelled', 'reactivated_at'],
          },
        });
      } else {
        writes.add({
          'update': {
            'name': regPath,
            'fields': _encodeFirestoreFields({
              'user_uid': uid,
              'event_id': eventId,
              'is_cancelled': false,
              'created_at': now,
            }),
          },
          'currentDocument': {'exists': false},
        });
      }

      final newCount = registeredCount + 1;
      writes.add({
        'update': {
          'name': eventPath,
          'fields': {
            'registered_count': {'integerValue': newCount.toString()},
          },
        },
        'updateMask': {'fieldPaths': ['registered_count']},
      });

      await _commit(client, projectId, writes, transaction);
      return {'registrationId': regDocId};
    }

    try {
      final result = await attempt();
      return result['registrationId'] as String;
    } on EventException {
      rethrow;
    } catch (e) {
      if (e is StateError && e.message == 'ABORTED') {
        try {
          final result = await attempt();
          return result['registrationId'] as String;
        } on EventException {
          rethrow;
        } catch (e) {
          throw EventException(
            EventErrorCode.internalError,
            'Transaction aborted after retry.',
          );
        }
      }
      throw EventException(
        EventErrorCode.internalError,
        'Registration failed: $e',
      );
    }
  }

  /// Cancels [uid]'s registration for [eventId].
  ///
  /// All reads and writes happen inside a single Firestore transaction.
  /// On `ABORTED`, retries once. On second failure, throws
  /// [EventException] with [EventErrorCode.internalError].
  static Future<void> cancel(String eventId, String uid) async {
    final client = await _firestoreClient();
    final projectId = _firestoreProjectId();
    final now = DateTime.now().toUtc().toIso8601String();

    final eventPath =
        'projects/$projectId/databases/(default)/documents/events/$eventId';
    final regDocId = _registrationDocId(uid, eventId);
    final regPath =
        'projects/$projectId/databases/(default)/documents/registrations/$regDocId';

    Future<void> attempt() async {
      final transaction = await _beginTransaction(client, projectId);
      final regDoc = await _readDoc(
        client,
        projectId,
        'registrations/$regDocId',
        transaction,
      );

      if (regDoc == null) {
        throw EventException(
          EventErrorCode.noActiveRegistration,
          'No active registration found.',
        );
      }

      final isCancelled = regDoc['is_cancelled'] as bool? ?? false;
      if (isCancelled) {
        throw EventException(
          EventErrorCode.noActiveRegistration,
          'No active registration found.',
        );
      }

      final eventDoc =
          await _readDoc(client, projectId, 'events/$eventId', transaction);
      final currentCount =
          eventDoc != null ? (eventDoc['registered_count'] as int? ?? 0) : 0;
      final newCount = currentCount > 0 ? currentCount - 1 : 0;

      final writes = <Map<String, dynamic>>[
        {
          'update': {
            'name': regPath,
            'fields': {
              'is_cancelled': {'booleanValue': true},
              'cancelled_at': {'stringValue': now},
            },
          },
          'updateMask': {
            'fieldPaths': ['is_cancelled', 'cancelled_at'],
          },
        },
        {
          'update': {
            'name': eventPath,
            'fields': {
              'registered_count': {'integerValue': newCount.toString()},
            },
          },
          'updateMask': {'fieldPaths': ['registered_count']},
        },
      ];

      await _commit(client, projectId, writes, transaction);
    }

    try {
      await attempt();
    } catch (e) {
      if (e is EventException) {
        rethrow;
      }
      if (e is StateError && e.message == 'ABORTED') {
        try {
          await attempt();
        } catch (e) {
          if (e is EventException) {
            rethrow;
          }
          throw EventException(
            EventErrorCode.internalError,
            'Transaction aborted after retry.',
          );
        }
        return;
      }
      throw EventException(
        EventErrorCode.internalError,
        'Cancellation failed: $e',
      );
    }
  }

  static String _todayUtcDateString() {
    final now = DateTime.now().toUtc();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
