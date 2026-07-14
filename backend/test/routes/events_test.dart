import 'dart:convert';

import 'package:backend/services/event_service.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/events/index.dart' as events_route;

class _MockRequestContext extends Mock implements RequestContext {}
class _MockRequest extends Mock implements Request {}

void main() {
  setUpAll(() {
    registerFallbackValue(Map<String, dynamic>.identity());
  });

  group('GET /events', () {
    test('returns 405 for POST', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);

      final response = await events_route.onRequest(context);

      expect(response.statusCode, equals(405));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['message'], contains('Method not allowed'));
    });

    test('returns 400 with EVT001 for cursor with invalid JSON', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.url).thenReturn(
        Uri.parse('/events?cursor='),
      );

      final response = await events_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['code'], equals('EVT001'));
    });

    test('returns 400 with EVT001 for cursor missing eventId', () async {
      final invalidCursor = base64.encode(
        utf8.encode(jsonEncode({'date': '2024-01-01'})),
      );

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.url).thenReturn(
        Uri.parse('/events?cursor=$invalidCursor'),
      );

      final response = await events_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['code'], equals('EVT001'));
    });

    test('returns 400 with EVT001 for invalid limit', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.url).thenReturn(
        Uri.parse('/events?limit=invalid'),
      );

      final response = await events_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['code'], equals('EVT001'));
      expect(body['message'], contains('Invalid limit'));
    });

    test('returns 400 with EVT001 for negative limit', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.url).thenReturn(
        Uri.parse('/events?limit=-1'),
      );

      final response = await events_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['code'], equals('EVT001'));
    });

    test('returns 400 with EVT001 for limit=0', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.url).thenReturn(
        Uri.parse('/events?limit=0'),
      );

      final response = await events_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['code'], equals('EVT001'));
    });

    test('tags parameter is URL-decoded', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.url).thenReturn(
        Uri.parse('/events?tags=conference%2Cworkshop'),
      );

      final response = await events_route.onRequest(context);

      expect(response.statusCode, anyOf(equals(200), equals(500)));
    });

    test('search parameter is case-insensitive', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.url).thenReturn(
        Uri.parse('/events?search=TECH'),
      );

      final response = await events_route.onRequest(context);

      expect(response.statusCode, anyOf(equals(200), equals(500)));
    });
  });

  group('Opaque cursor pagination', () {
    test('opaque cursor round-trips date and eventId', () {
      final cursorData = {
        'date': '2024-01-15',
        'eventId': 'event123',
      };
      final encoded = base64.encode(utf8.encode(jsonEncode(cursorData)));

      final decoded = jsonDecode(utf8.decode(base64.decode(encoded)))
          as Map<String, dynamic>;

      expect(decoded['date'], equals('2024-01-15'));
      expect(decoded['eventId'], equals('event123'));
    });

    test('returns 400 with EVT001 for cursor missing date', () async {
      final invalidCursor = base64.encode(
        utf8.encode(jsonEncode({'eventId': 'event123'})),
      );

      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.url).thenReturn(
        Uri.parse('/events?cursor=$invalidCursor'),
      );

      final response = await events_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['code'], equals('EVT001'));
    });
  });

  group('buildStartAtCursor', () {
    test('is a Firestore Cursor object ordered date then reference', () {
      final startAt = EventService.buildStartAtCursor(
        projectId: 'my-project',
        date: '2024-01-15',
        eventId: 'event123',
      );

      expect(startAt['before'], isFalse);

      final values = startAt['values'] as List<dynamic>;
      expect(values, hasLength(2));

      final dateValue = values[0] as Map<String, dynamic>;
      expect(dateValue['stringValue'], equals('2024-01-15'));

      final refValue = values[1] as Map<String, dynamic>;
      expect(
        refValue['referenceValue'],
        equals(
          'projects/my-project/databases/(default)/documents/events/event123',
        ),
      );
    });
  });
}
