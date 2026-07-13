import 'dart:convert';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/models/event.dart';
import 'package:backend/services/firebase_event_service.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/events/[eventId]/index.dart' as event_detail_route;

class _MockRequestContext extends Mock implements RequestContext {}
class _MockRequest extends Mock implements Request {}

void main() {
  group('Event model', () {
    test('toJson computes slots_remaining server-side', () {
      final event = Event(
        eventId: 'evt_abc123',
        title: 'Event Details 2',
        description: 'Very long description.',
        cover_image_url: 'https://example.com/cover.jpg',
        date: '2026-05-16',
        start_time: '13:30',
        end_time: '16:00',
        event_mode: 'offline',
        location: '7th Floor, Gymnasium',
        stream_link: null,
        host_name: 'Sean Audric Salvado',
        guest_speaker: 'Jhervis Arevalo',
        contactEmails: const ['jeff.marquez@ciit.edu.ph'],
        tags: const ['Students Only', 'Technology'],
        is_open_to_guests: true,
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
      expect(EventErrorCode.statusFor[EventErrorCode.notFound], equals(404));
    });
  });
}
