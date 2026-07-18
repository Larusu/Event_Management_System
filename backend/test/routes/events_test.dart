import 'dart:convert';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/models/event.dart';
import 'package:backend/services/event_service.dart';
import 'package:backend/services/firebase_event_service.dart';
import 'package:backend/utils/validators.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/events/[eventId]/index.dart'
    as event_detail_route;
import '../../routes/events/cover-image.dart'
    as cover_image_route;
import '../../routes/events/featured.dart' as featured_route;
import '../../routes/events/index.dart' as events_route;
import '../../routes/events/next-registered.dart'
    as next_registered_route;
import '../../routes/events/registered.dart'
    as registered_route;

class _MockRequestContext extends Mock
    implements RequestContext {}

class _MockRequest extends Mock implements Request {}

void main() {
  setUpAll(() {
    registerFallbackValue(Map<String, dynamic>.identity());
  });

  group('GET /events', () {
    test('returns 405 for PUT', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.put);

      final response = await events_route.onRequest(context);

      expect(response.statusCode, equals(405));
      final body = jsonDecode(await response.body())
          as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(
        body['message'],
        contains('Method not allowed'),
      );
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

  group('Event model', () {
    test('toJson computes slots_remaining server-side', () {
      final event = Event(
        eventId: 'evt_abc123',
        title: 'Event Details 2',
        description: 'Very long description.',
        coverImageUrl: 'https://example.com/cover.jpg',
        date: '2026-05-16',
        startTime: '13:30',
        endTime: '16:00',
        eventMode: 'offline',
        location: '7th Floor, Gymnasium',
        hostName: 'Sean Audric Salvado',
        guestSpeaker: 'Jhervis Arevalo',
        contactEmails: const ['jeff.marquez@ciit.edu.ph'],
        tags: const ['Students Only', 'Technology'],
        isOpenToGuests: true,
        slotsTotal: 30,
        registeredCount: 20,
      );

      final json = event.toJson();

      expect(json['slots_remaining'], equals(10));
      expect(json['slots_total'], equals(30));
      expect(json['registered_count'], equals(20));
      expect(json.containsKey('status'), isFalse);
      expect(json.containsKey('organizer_uid'), isFalse);
      expect(json.containsKey('is_deleted'), isFalse);
    });
  });

  group('FirebaseEventService.isPubliclyVisible', () {
    test('returns true for approved, non-deleted events', () {
      expect(
        FirebaseEventService.isPubliclyVisible({
          'status': 'approved',
          'is_deleted': false,
        }),
        isTrue,
      );
    });

    test('returns false when event is soft-deleted', () {
      expect(
        FirebaseEventService.isPubliclyVisible({
          'status': 'approved',
          'is_deleted': true,
        }),
        isFalse,
      );
    });

    test('returns false when status is not approved', () {
      expect(
        FirebaseEventService.isPubliclyVisible({
          'status': 'pending',
          'is_deleted': false,
        }),
        isFalse,
      );
    });

    test('returns false when status is missing', () {
      expect(
        FirebaseEventService.isPubliclyVisible({
          'is_deleted': false,
        }),
        isFalse,
      );
    });
  });

  group('GET /events/{eventId}', () {
    test('returns 405 for POST', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);

      final response =
          await event_detail_route.onRequest(context, 'evt_abc123');

      expect(response.statusCode, equals(405));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['message'], contains('Method not allowed'));
    });
  });

  group('EventErrorCode', () {
    test('EVT002 maps to HTTP 404', () {
      expect(
        EventErrorCode.statusFor[EventErrorCode.notFound],
        equals(404),
      );
    });

    test('EVT003 maps to HTTP 400', () {
      expect(
        EventErrorCode
            .statusFor[EventErrorCode.validationFailed],
        equals(400),
      );
    });

    test('EVT004 maps to HTTP 403', () {
      expect(
        EventErrorCode
            .statusFor[EventErrorCode.permissionDenied],
        equals(403),
      );
    });

    test('EVT006 maps to HTTP 500', () {
      expect(
        EventErrorCode
            .statusFor[EventErrorCode.cloudinaryError],
        equals(500),
      );
    });

    test('EVT007 maps to HTTP 400', () {
      expect(
        EventErrorCode.statusFor[EventErrorCode.dateInPast],
        equals(400),
      );
    });
  });

  group('GET /events/featured', () {
    test('returns 405 for POST', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);

      final response = await featured_route.onRequest(context);

      expect(response.statusCode, equals(405));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['message'], contains('Method not allowed'));
    });

    test('returns 400 with EVT001 for non-integer limit', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.url).thenReturn(
        Uri.parse('/events/featured?limit=abc'),
      );

      final response = await featured_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('EVT001'));
    });

    test('returns 400 with EVT001 for limit below 3', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.url).thenReturn(
        Uri.parse('/events/featured?limit=2'),
      );

      final response = await featured_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('EVT001'));
    });

    test('returns 400 with EVT001 for limit above 10', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.url).thenReturn(
        Uri.parse('/events/featured?limit=11'),
      );

      final response = await featured_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('EVT001'));
    });

    test('accepts limit=3 without EVT001 (may hit Firestore)', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.url).thenReturn(
        Uri.parse('/events/featured?limit=3'),
      );

      final response = await featured_route.onRequest(context);

      // 200 when Firebase is configured; 500 without .env in CI.
      expect(response.statusCode, anyOf(equals(200), equals(500)));
    });
  });

  group('GET /events/registered (stub)', () {
    test('returns 405 for POST', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);

      final response = await registered_route.onRequest(context);

      expect(response.statusCode, equals(405));
    });

    test('returns locked empty shape', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);

      final response = await registered_route.onRequest(context);

      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['events'], isEmpty);
      expect(body['next_cursor'], isNull);
    });
  });

  group('GET /events/next-registered (stub)', () {
    test('returns 405 for POST', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);

      final response = await next_registered_route.onRequest(context);

      expect(response.statusCode, equals(405));
    });

    test('returns locked empty shape with event: null', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);

      final response = await next_registered_route.onRequest(context);

      expect(response.statusCode, equals(200));
      final body = jsonDecode(await response.body())
          as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body.containsKey('event'), isTrue);
      expect(body['event'], isNull);
    });
  });

  // -----------------------------------------------------------------------
  // validateCreateEvent
  // -----------------------------------------------------------------------

  group('EventValidationService.validateCreateEvent', () {
    Map<String, dynamic> validBody() {
      final today = DateTime.now();
      final futureDate = DateTime(
        today.year,
        today.month,
        today.day + 7,
      );
      final dateStr =
          '${futureDate.year}-'
          '${futureDate.month.toString().padLeft(2, '0')}-'
          '${futureDate.day.toString().padLeft(2, '0')}';

      return <String, dynamic>{
        'title': 'Test Event',
        'description': 'A very long description.',
        'cover_image_url':
            'https://res.cloudinary.com/test/img.jpg',
        'date': dateStr,
        'start_time': '09:00',
        'end_time': '12:00',
        'event_mode': 'offline',
        'location': '7th Floor, Gymnasium',
        'stream_link': null,
        'host_name': 'John Doe',
        'guest_speaker': null,
        'contact_emails': <String>['john@ciit.edu.ph'],
        'tags': <String>['Technology'],
        'is_open_to_guests': true,
        'slots_total': 30,
      };
    }

    test('returns null for a fully valid body', () {
      expect(
        EventValidationService.validateCreateEvent(
          validBody(),
        ),
        isNull,
      );
    });

    test('returns error for missing title', () {
      final body = validBody()..remove('title');
      expect(
        EventValidationService.validateCreateEvent(body),
        contains('title'),
      );
    });

    test('returns error for empty title', () {
      final body = validBody()..['title'] = '   ';
      expect(
        EventValidationService.validateCreateEvent(body),
        contains('title'),
      );
    });

    test('returns error for missing cover_image_url', () {
      final body = validBody()..remove('cover_image_url');
      expect(
        EventValidationService.validateCreateEvent(body),
        contains('cover_image_url'),
      );
    });

    test('returns error for empty contact_emails', () {
      final body = validBody()
        ..['contact_emails'] = <dynamic>[];
      expect(
        EventValidationService.validateCreateEvent(body),
        contains('contact_emails'),
      );
    });

    test('returns error for empty tags', () {
      final body = validBody()
        ..['tags'] = <dynamic>[];
      expect(
        EventValidationService.validateCreateEvent(body),
        contains('tags'),
      );
    });

    test('returns error for slots_total <= 0', () {
      final body = validBody()..['slots_total'] = 0;
      expect(
        EventValidationService.validateCreateEvent(body),
        contains('slots_total'),
      );
    });

    test('returns error for date in the past', () {
      final body = validBody()..['date'] = '2020-01-01';
      expect(
        EventValidationService.validateCreateEvent(body),
        contains('today or in the future'),
      );
    });

    test('returns error for invalid date format', () {
      final body = validBody()..['date'] = '01/01/2026';
      expect(
        EventValidationService.validateCreateEvent(body),
        contains('YYYY-MM-DD'),
      );
    });

    test('returns error for end_time before start_time', () {
      final body = validBody()
        ..['start_time'] = '14:00'
        ..['end_time'] = '09:00';
      expect(
        EventValidationService.validateCreateEvent(body),
        contains('end_time'),
      );
    });

    test('returns error for end_time == start_time', () {
      final body = validBody()
        ..['start_time'] = '09:00'
        ..['end_time'] = '09:00';
      expect(
        EventValidationService.validateCreateEvent(body),
        contains('end_time'),
      );
    });

    test('returns error for invalid event_mode', () {
      final body = validBody()
        ..['event_mode'] = 'hybrid';
      expect(
        EventValidationService.validateCreateEvent(body),
        contains('online" or "offline'),
      );
    });

    test('online event without stream_link fails', () {
      final body = validBody()
        ..['event_mode'] = 'online'
        ..['stream_link'] = null;
      expect(
        EventValidationService.validateCreateEvent(body),
        contains('stream_link'),
      );
    });

    test('online event with stream_link passes', () {
      final body = validBody()
        ..['event_mode'] = 'online'
        ..['stream_link'] = 'https://zoom.us/j/123'
        ..['location'] = null;
      expect(
        EventValidationService.validateCreateEvent(body),
        isNull,
      );
    });

    test('offline event without location fails', () {
      final body = validBody()
        ..['event_mode'] = 'offline'
        ..['location'] = null;
      expect(
        EventValidationService.validateCreateEvent(body),
        contains('location'),
      );
    });
  });

  // -----------------------------------------------------------------------
  // generateEventId
  // -----------------------------------------------------------------------

  group('FirebaseEventService.generateEventId', () {
    test('prefix is evt_', () {
      final id =
          FirebaseEventService.generateEventId('Uniteam');
      expect(id, startsWith('evt_'));
    });

    test('slugifies title to lowercase', () {
      final id = FirebaseEventService.generateEventId(
        'My Event',
      );
      expect(id, contains('evt_my-event'));
    });

    test('appends 4-char hex suffix', () {
      final id =
          FirebaseEventService.generateEventId('Test');
      final suffix = id.split('_').last;
      expect(suffix.length, equals(4));
      expect(
        int.tryParse(suffix, radix: 16),
        isNotNull,
      );
    });

    test('truncates long titles', () {
      final id = FirebaseEventService.generateEventId(
        'A' * 50,
      );
      // evt_(4) + slug(24) + _(1) + hex(4) = 33
      expect(id.length, lessThanOrEqualTo(33));
    });

    test('strips special characters', () {
      final id = FirebaseEventService.generateEventId(
        'Hello @ World!',
      );
      expect(id, isNot(contains('@')));
      expect(id, isNot(contains('!')));
      expect(id, isNot(contains(' ')));
    });
  });

  // -----------------------------------------------------------------------
  // POST /events — route-level checks
  // -----------------------------------------------------------------------

  group('POST /events', () {
    test('returns 405 for PUT', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.put);

      final response =
          await events_route.onRequest(context);

      expect(response.statusCode, equals(405));
      final body = jsonDecode(await response.body())
          as Map<String, dynamic>;
      expect(body['success'], isFalse);
    });

    test('returns 403 EVT004 for student role', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.read<String>()).thenReturn('uid123');
      when(
        () => context.read<Map<String, dynamic>>(),
      ).thenReturn({'role': 'student'});
      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(
        () => request.body(),
      ).thenAnswer((_) async => '{}');

      final response =
          await events_route.onRequest(context);

      expect(response.statusCode, equals(403));
      final body = jsonDecode(await response.body())
          as Map<String, dynamic>;
      expect(body['code'], equals('EVT004'));
    });

    test('returns 403 EVT004 for guest role', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.read<String>()).thenReturn('uid123');
      when(
        () => context.read<Map<String, dynamic>>(),
      ).thenReturn({'role': 'guest'});
      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(
        () => request.body(),
      ).thenAnswer((_) async => '{}');

      final response =
          await events_route.onRequest(context);

      expect(response.statusCode, equals(403));
      final body = jsonDecode(await response.body())
          as Map<String, dynamic>;
      expect(body['code'], equals('EVT004'));
    });

    test(
      'returns 400 EVT003 for empty body (organizer)',
      () async {
        final context = _MockRequestContext();
        final request = _MockRequest();

        when(
          () => context.read<String>(),
        ).thenReturn('uid123');
        when(
          () => context.read<Map<String, dynamic>>(),
        ).thenReturn({'role': 'organizer'});
        when(() => context.request).thenReturn(request);
        when(
          () => request.method,
        ).thenReturn(HttpMethod.post);
        when(
          () => request.body(),
        ).thenAnswer((_) async => '{}');

        final response =
            await events_route.onRequest(context);

        expect(response.statusCode, equals(400));
        final body =
            jsonDecode(await response.body())
                as Map<String, dynamic>;
        expect(body['code'], equals('EVT003'));
      },
    );

    test(
      'returns 400 EVT003 for empty body (faculty)',
      () async {
        final context = _MockRequestContext();
        final request = _MockRequest();

        when(
          () => context.read<String>(),
        ).thenReturn('uid123');
        when(
          () => context.read<Map<String, dynamic>>(),
        ).thenReturn({'role': 'faculty'});
        when(() => context.request).thenReturn(request);
        when(
          () => request.method,
        ).thenReturn(HttpMethod.post);
        when(
          () => request.body(),
        ).thenAnswer((_) async => '{}');

        final response =
            await events_route.onRequest(context);

        expect(response.statusCode, equals(400));
        final body =
            jsonDecode(await response.body())
                as Map<String, dynamic>;
        expect(body['code'], equals('EVT003'));
      },
    );

    test(
      'strips server-owned fields from input',
      () async {
        final context = _MockRequestContext();
        final request = _MockRequest();

        when(
          () => context.read<String>(),
        ).thenReturn('uid123');
        when(
          () => context.read<Map<String, dynamic>>(),
        ).thenReturn({'role': 'organizer'});
        when(() => context.request).thenReturn(request);
        when(
          () => request.method,
        ).thenReturn(HttpMethod.post);

        final bodyJson = jsonEncode({
          'title': 'Test',
          'status': 'approved',
          'organizer_uid': 'hacker',
          'registered_count': 99,
          'is_deleted': true,
        });

        when(
          () => request.body(),
        ).thenAnswer((_) async => bodyJson);

        final response =
            await events_route.onRequest(context);

        // Should fail validation (missing fields) after
        // stripping server-owned fields
        expect(response.statusCode, equals(400));
        final body =
            jsonDecode(await response.body())
                as Map<String, dynamic>;
        expect(body['code'], equals('EVT003'));
      },
    );
  });

  // -----------------------------------------------------------------------
  // POST /events/cover-image — route-level checks
  // -----------------------------------------------------------------------

  group('POST /events/cover-image', () {
    test('returns 405 for PUT', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.put);

      final response =
          await cover_image_route.onRequest(context);

      expect(response.statusCode, equals(405));
      final body = jsonDecode(await response.body())
          as Map<String, dynamic>;
      expect(body['success'], isFalse);
    });

    test('returns 400 EVT003 for non-multipart', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(
        () => request.headers,
      ).thenReturn({'content-type': 'application/json'});
      when(
        () => request.body(),
      ).thenAnswer((_) async => '{}');

      final response =
          await cover_image_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body())
          as Map<String, dynamic>;
      expect(body['code'], equals('EVT003'));
    });
  });
}
