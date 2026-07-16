import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_codes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/event.dart';

/// One page of the events feed: the [events] on this page plus an opaque
/// [nextCursor] to pass back in as `cursor` for the following page. A null
/// [nextCursor] means the feed has been exhausted.
class EventsPage {
  const EventsPage({required this.events, this.nextCursor});

  final List<Event> events;
  final String? nextCursor;
}

/// Data access for the events feature. Screens depend on this interface, not on
/// a concrete implementation, so the mock can be swapped for the real backend
/// via the [useMockEvents] flag without touching the UI.
abstract class EventRepository {
  Future<Event> getEvent(String eventId);

  /// Fetches one page of the events feed (`GET /events`, Feature 3).
  ///
  /// The feed is ordered by `date` ascending. Pass the previous page's
  /// [EventsPage.nextCursor] as [cursor] to page forward; [limit] is clamped
  /// server-side to 100. [tags] / [search] are optional server-side filters.
  Future<EventsPage> getEvents({
    String? cursor,
    int? limit,
    String? tags,
    String? search,
  });
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

  @override
  Future<EventsPage> getEvents({
    String? cursor,
    int? limit,
    String? tags,
    String? search,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = '$limit';
    if (cursor != null) params['cursor'] = cursor;
    if (tags != null) params['tags'] = tags;
    if (search != null) params['search'] = search;

    final query =
        params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    final response = await _api.get('${ApiRoutes.events}$query');

    // The feed merges `events` and `next_cursor` into the top-level envelope
    // (see backend ResponseHelper.success). Feed items are a slim shape
    // (title/date/start_time/end_time/tags/slots); Event.fromJson defaults the
    // detail-only fields, which the calendar cells don't need.
    final rawEvents = response.data['events'];
    final events = rawEvents is List
        ? rawEvents
            .whereType<Map<String, dynamic>>()
            .map(Event.fromJson)
            .toList()
        : <Event>[];

    return EventsPage(
      events: events,
      nextCursor: response.data['next_cursor'] as String?,
    );
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

  @override
  Future<EventsPage> getEvents({
    String? cursor,
    int? limit,
    String? tags,
    String? search,
  }) async {
    // A small fixed set spanning a few days so Day/Week/Month views all render
    // something while building the UI. Returned as a single page
    // (nextCursor == null) — pagination is exercised against the real backend.
    final events = <Event>[
      Event.fromJson({
        'event_id': 'mock-1',
        'title': 'Orientation',
        'date': '2026-05-14',
        'start_time': '09:00',
        'end_time': '11:00',
        'tags': <String>['Education'],
      }),
      Event.fromJson({
        'event_id': 'mock-2',
        'title': 'Coding Workshop',
        'date': '2026-05-16',
        'start_time': '10:00',
        'end_time': '12:00',
        'tags': <String>['Technology'],
      }),
      Event.fromJson({
        'event_id': 'mock-3',
        'title': 'Basketball Finals',
        'date': '2026-05-16',
        'start_time': '13:30',
        'end_time': '16:00',
        'tags': <String>['Sports'],
      }),
    ];
    return EventsPage(events: events, nextCursor: null);
  }
}

/// Picks the mock or real repository based on the [useMockEvents] flag.
EventRepository createEventRepository() =>
    useMockEvents ? MockEventRepository() : EventApiRepository();
