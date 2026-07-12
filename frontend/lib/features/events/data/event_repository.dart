import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_codes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/event.dart';

/// Data access for the events feature. Screens depend on this interface, not on
/// a concrete implementation, so the mock can be swapped for the real backend
/// via the [useMockEvents] flag without touching the UI.
abstract class EventRepository {
  Future<Event> getEvent(String eventId);
}

/// Talks to the real Dart Frog backend (`GET /events/{eventId}`, doc 3.5.2).
class EventApiRepository implements EventRepository {
  final ApiClient _api;

  EventApiRepository([ApiClient? api]) : _api = api ?? ApiClient();

  @override
  Future<Event> getEvent(String eventId) async {
    final response = await _api.get(ApiRoutes.eventById(eventId));
    // The doc uses the key `events` for a single object; accept `event` too.
    // TODO(backend): once live, confirm the real response envelope key against
    // doc 3.5.2, and verify AUTH001 (expired token) and EVT002 (not found /
    // deleted / unapproved) surface correctly through ApiException.
    final json = response.data['event'] ?? response.data['events'];
    if (json is! Map<String, dynamic>) {
      throw const ApiException('Something went wrong. Please try again.');
    }
    return Event.fromJson(json);
  }
}

/// Returns sample data so the modal can be built and demoed before the backend
/// ships. Pass the id `missing` to exercise the EVT002 not-found state.
///
// TODO(backend): once the real endpoint is verified, remove this mock and the
// artificial 600ms delay (or keep it solely for widget tests). The `missing`
// id shortcut is mock-only and has no backend equivalent.
class MockEventRepository implements EventRepository {
  @override
  Future<Event> getEvent(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (eventId == 'missing') {
      throw const ApiException(
        'Event not found.',
        code: EventErrorCodes.notFound,
      );
    }

    return Event.fromJson({
      'event_id': eventId,
      'title': 'Event Details 2',
      'description':
          'Very long description of the event. Thank you. Lorem ipsum. '
              'Dolor sit amet, consectetur adipiscing elit, sed do eiusmod '
              'tempor incididunt ut labore et dolore magna aliqua.',
      'cover_image_url': 'https://picsum.photos/600/400',
      'date': '2026-05-16',
      'start_time': '13:30',
      'end_time': '16:00',
      'event_mode': 'offline',
      'location': '7th Floor, Gymnasium, Interweave Building',
      'stream_link': null,
      'host_name': 'Sean Audric Salvado',
      'guest_speaker': 'Jhervis Arevalo',
      'contact_emails': ['jeff.marquez@ciit.edu.ph', 'lars.timajo@ciit.edu.ph'],
      'tags': ['Students Only', 'Technology'],
      'is_open_to_guests': true,
      'slots_total': 30,
      'registered_count': 14,
      'slots_remaining': 16,
    });
  }
}

/// Picks the mock or real repository based on the [useMockEvents] flag.
EventRepository createEventRepository() =>
    useMockEvents ? MockEventRepository() : EventApiRepository();
