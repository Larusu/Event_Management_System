import 'dart:async';
import 'dart:convert';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/constants/event_exception.dart';
import 'package:backend/services/registration_service.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/events/[eventId]/register/index.dart'
    as register_route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({
    http.Response? eventResponse,
    http.Response? regResponse,
    http.Response? postResponse,
  })  : _eventResponse = eventResponse ?? http.Response('{}', 404),
        _regResponse = regResponse ?? http.Response('{}', 404),
        _postResponse = postResponse ?? http.Response('{}', 200);

  final http.Response _eventResponse;
  final http.Response _regResponse;
  final http.Response _postResponse;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uri = request.url;
    if (request.method == 'GET') {
      final response = _getResponse(uri);
      final bytes = utf8.encode(response.body);
      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        headers: response.headers,
        reasonPhrase: response.reasonPhrase,
      );
    }
    if (request.method == 'POST') {
      if (uri.path.endsWith(':beginTransaction')) {
        return _transactionResponse();
      }
      final bytes = utf8.encode(_postResponse.body);
      return http.StreamedResponse(
        Stream.value(bytes),
        _postResponse.statusCode,
        headers: _postResponse.headers,
        reasonPhrase: _postResponse.reasonPhrase,
      );
    }
    throw StateError('${request.method} not supported in tests');
  }

  http.Response _getResponse(Uri uri) {
    if (uri.path.contains('registrations/')) {
      return _regResponse;
    }
    return _eventResponse;
  }
}

class _AbortThenOkFakeClient extends http.BaseClient {
  _AbortThenOkFakeClient();

  int _postCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uri = request.url;
    if (request.method == 'GET') {
      final isRegPath = uri.path.contains('registrations/');
      final bytes = utf8.encode(
        isRegPath ? '{}' : _eventFieldsJson(),
      );
      return http.StreamedResponse(
        Stream.value(bytes),
        isRegPath ? 404 : 200,
      );
    }
    if (request.method == 'POST') {
      if (uri.path.endsWith(':beginTransaction')) {
        return _transactionResponse();
      }
      _postCount++;
      if (_postCount == 1) {
        final body = jsonEncode({'error': {'message': 'ABORTED'}});
        final bytes = utf8.encode(body);
        return http.StreamedResponse(
          Stream.value(bytes),
          400,
        );
      }
      final bytes = utf8.encode('{}');
      return http.StreamedResponse(
        Stream.value(bytes),
        200,
      );
    }
    throw StateError('${request.method} not supported in tests');
  }
}

/// Firestore's `:beginTransaction` returns an opaque transaction token that
/// the service passes to every read and to the final `:commit`.
http.StreamedResponse _transactionResponse() {
  final bytes = utf8.encode(jsonEncode({'transaction': 'dHhuLXRva2Vu'}));
  return http.StreamedResponse(Stream.value(bytes), 200);
}

const _eventId = 'evt_test123';
const _uid = 'user_abc';

Map<String, dynamic> _eventFields({
  String status = 'approved',
  bool isDeleted = false,
  String date = '2099-12-31',
  bool isOpenToGuests = true,
  int slotsTotal = 10,
  int registeredCount = 0,
}) {
  return {
    'status': {'stringValue': status},
    'is_deleted': {'booleanValue': isDeleted},
    'date': {'stringValue': date},
    'is_open_to_guests': {'booleanValue': isOpenToGuests},
    'slots_total': {'integerValue': slotsTotal.toString()},
    'registered_count': {'integerValue': registeredCount.toString()},
  };
}

String _eventFieldsJson({
  String status = 'approved',
  bool isDeleted = false,
  String date = '2099-12-31',
  bool isOpenToGuests = true,
  int slotsTotal = 10,
  int registeredCount = 0,
}) {
  return jsonEncode({'fields': _eventFields(
    status: status,
    isDeleted: isDeleted,
    date: date,
    isOpenToGuests: isOpenToGuests,
    slotsTotal: slotsTotal,
    registeredCount: registeredCount,
  )});
}

String _regFieldsJson({
  bool isCancelled = false,
  String? cancelledAt,
  String createdAt = '2099-01-01T00:00:00Z',
  String? reactivatedAt,
}) {
  final fields = <String, dynamic>{
    'user_uid': {'stringValue': _uid},
    'event_id': {'stringValue': _eventId},
    'is_cancelled': {'booleanValue': isCancelled},
    'created_at': {'stringValue': createdAt},
  };
  if (cancelledAt != null) {
    fields['cancelled_at'] = {'stringValue': cancelledAt};
  }
  if (reactivatedAt != null) {
    fields['reactivated_at'] = {'stringValue': reactivatedAt};
  }
  return jsonEncode({'fields': fields});
}

void main() {
  setUpAll(() {
    registerFallbackValue(Map<String, dynamic>.identity());
  });

  tearDown(() {
    RegistrationService.clearHttpClientOverride();
  });

  group('RegistrationService.registrationDocId', () {
    test('builds deterministic doc ID', () {
      expect(
        RegistrationService.registrationDocId('uid_1', 'evt_abc'),
        equals('uid_1_evt_abc'),
      );
    });
  });

  group('RegistrationService.encodeFirestoreFields', () {
    test('encodes string fields', () {
      final encoded = RegistrationService.encodeFirestoreFields({
        'name': 'hello',
      });
      expect(encoded['name'], equals({'stringValue': 'hello'}));
    });

    test('encodes bool fields', () {
      final encoded = RegistrationService.encodeFirestoreFields({
        'active': true,
      });
      expect(encoded['active'], equals({'booleanValue': true}));
    });

    test('encodes int fields', () {
      final encoded = RegistrationService.encodeFirestoreFields({
        'count': 42,
      });
      expect(encoded['count'], equals({'integerValue': '42'}));
    });

    test('encodes null as nullValue', () {
      final encoded = RegistrationService.encodeFirestoreFields({
        'field': null,
      });
      expect(encoded['field'], equals({'nullValue': null}));
    });
  });

  group('POST /events/{eventId}/register', () {
    test('returns 405 for GET', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(405));
    });

    test('returns 405 for PUT', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.put);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(405));
    });

    test('returns 400 for non-empty body', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => context.read<Map<String, dynamic>>())
          .thenReturn(<String, dynamic>{'role': 'student'});
      when(() => request.body())
          .thenAnswer((_) async => jsonEncode({'foo': 'bar'}));

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals(EventErrorCode.validationError));
    });

    test('returns EVT002 for missing event', () async {
      final client = _FakeHttpClient(
        eventResponse: http.Response('{}', 404),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => context.read<Map<String, dynamic>>())
          .thenReturn(<String, dynamic>{'role': 'student'});
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(404));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals(EventErrorCode.notFound));
    });

    test('returns EVT002 for deleted event', () async {
      final client = _FakeHttpClient(
        eventResponse: http.Response(
          _eventFieldsJson(isDeleted: true),
          200,
        ),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => context.read<Map<String, dynamic>>())
          .thenReturn(<String, dynamic>{'role': 'student'});
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(404));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals(EventErrorCode.notFound));
    });

    test('returns EVT002 for not-approved event', () async {
      final client = _FakeHttpClient(
        eventResponse: http.Response(
          _eventFieldsJson(status: 'pending'),
          200,
        ),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => context.read<Map<String, dynamic>>())
          .thenReturn(<String, dynamic>{'role': 'student'});
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(404));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals(EventErrorCode.notFound));
    });

    test('returns EVT007 for past event date', () async {
      final client = _FakeHttpClient(
        eventResponse: http.Response(
          _eventFieldsJson(date: '2020-01-01'),
          200,
        ),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => context.read<Map<String, dynamic>>())
          .thenReturn(<String, dynamic>{'role': 'student'});
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals(EventErrorCode.dateInPast));
    });

    test('returns EVT011 when event is not open to guests', () async {
      final client = _FakeHttpClient(
        eventResponse: http.Response(
          _eventFieldsJson(isOpenToGuests: false),
          200,
        ),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => context.read<Map<String, dynamic>>())
          .thenReturn(<String, dynamic>{'role': 'guest'});
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(403));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals(EventErrorCode.guestRegistrationLocked));
    });

    test('allows a student to register when not open to guests', () async {
      final client = _FakeHttpClient(
        eventResponse: http.Response(
          _eventFieldsJson(isOpenToGuests: false),
          200,
        ),
        regResponse: http.Response('{}', 404),
        postResponse: http.Response('{}', 200),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => context.read<Map<String, dynamic>>())
          .thenReturn(<String, dynamic>{'role': 'student'});
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(201));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isTrue);
    });

    test('returns EVT010 when event is full', () async {
      final client = _FakeHttpClient(
        eventResponse: http.Response(
          _eventFieldsJson(slotsTotal: 1, registeredCount: 1),
          200,
        ),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => context.read<Map<String, dynamic>>())
          .thenReturn(<String, dynamic>{'role': 'student'});
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(409));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals(EventErrorCode.slotsFull));
    });

    test('returns EVT009 when already actively registered', () async {
      final client = _FakeHttpClient(
        eventResponse: http.Response(_eventFieldsJson(), 200),
        regResponse: http.Response(
          _regFieldsJson(isCancelled: false),
          200,
        ),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => context.read<Map<String, dynamic>>())
          .thenReturn(<String, dynamic>{'role': 'student'});
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(409));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals(EventErrorCode.alreadyRegistered));
    });

    test('returns 201 and creates new registration', () async {
      final client = _FakeHttpClient(
        eventResponse: http.Response(_eventFieldsJson(registeredCount: 0), 200),
        regResponse: http.Response('{}', 404),
        postResponse: http.Response('{}', 200),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => context.read<Map<String, dynamic>>())
          .thenReturn(<String, dynamic>{'role': 'student'});
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(201));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['message'], equals('Registered successfully.'));
    });

    test('returns 201 and reactivates cancelled registration', () async {
      final client = _FakeHttpClient(
        eventResponse: http.Response(_eventFieldsJson(registeredCount: 5), 200),
        regResponse: http.Response(_regFieldsJson(isCancelled: true), 200),
        postResponse: http.Response('{}', 200),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => context.read<Map<String, dynamic>>())
          .thenReturn(<String, dynamic>{'role': 'student'});
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(201));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isTrue);
    });
  });

  group('DELETE /events/{eventId}/register', () {
    test('returns 405 for GET', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(405));
    });

    test('returns 405 for PUT', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.put);
      when(() => context.read<String>()).thenReturn(_uid);
      when(() => request.body()).thenAnswer((_) async => '');

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(405));
    });

    test('returns EVT012 when no registration doc', () async {
      final client = _FakeHttpClient(
        regResponse: http.Response('{}', 404),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.delete);
      when(() => context.read<String>()).thenReturn(_uid);

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(404));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals(EventErrorCode.noActiveRegistration));
    });

    test('returns EVT012 when registration is already cancelled', () async {
      final client = _FakeHttpClient(
        regResponse: http.Response(_regFieldsJson(isCancelled: true), 200),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.delete);
      when(() => context.read<String>()).thenReturn(_uid);

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(404));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals(EventErrorCode.noActiveRegistration));
    });

    test('returns 200 and cancels active registration', () async {
      final client = _FakeHttpClient(
        regResponse: http.Response(_regFieldsJson(isCancelled: false), 200),
        eventResponse: http.Response(_eventFieldsJson(registeredCount: 5), 200),
        postResponse: http.Response('{}', 200),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.delete);
      when(() => context.read<String>()).thenReturn(_uid);

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['message'], equals('Registration cancelled.'));
    });

    test('clamps registered_count at 0 when already 0', () async {
      final client = _FakeHttpClient(
        regResponse: http.Response(_regFieldsJson(isCancelled: false), 200),
        eventResponse: http.Response(_eventFieldsJson(registeredCount: 0), 200),
        postResponse: http.Response('{}', 200),
      );

      RegistrationService.overrideHttpClient = client;

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.delete);
      when(() => context.read<String>()).thenReturn(_uid);

      final response = await register_route.onRequest(context, _eventId);

      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isTrue);
    });
  });

  group('RegistrationService transaction retry', () {
    test('succeeds after one ABORTED retry', () async {
      final client = _AbortThenOkFakeClient();
      RegistrationService.overrideHttpClient = client;

      final result =
          await RegistrationService.register(_eventId, _uid, 'student');

      expect(result, equals('${_uid}_$_eventId'));
    });

    test('throws EVT008 after two ABORTED retries', () async {
      final client = _FakeHttpClient(
        eventResponse: http.Response(_eventFieldsJson(registeredCount: 0), 200),
        regResponse: http.Response('{}', 404),
        postResponse: http.Response(
          jsonEncode({'error': {'message': 'ABORTED'}}),
          400,
        ),
      );

      RegistrationService.overrideHttpClient = client;

      expect(
        () => RegistrationService.register(_eventId, _uid, 'student'),
        throwsA(
          isA<EventException>().having(
            (e) => e.code,
            'code',
            EventErrorCode.internalError,
          ),
        ),
      );
    });
  });
}
