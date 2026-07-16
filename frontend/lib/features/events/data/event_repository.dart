import '../../../core/constants/api_constants.dart';
import '../../../core/constants/error_codes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/event.dart';
import '../models/event_list_response.dart';

/// Data access for the events feature. Screens depend on this interface, not on
/// a concrete implementation, so the mock can be swapped for the real backend
/// via the [useMockEvents] flag without touching the UI.
abstract class EventRepository {
  Future<Event> getEvent(String eventId);
  Future<EventListResponse> getEvents({
    String? query,
    List<String>? tags,
    String? cursor,
    int? limit,
  });
  Future<List<Event>> getFeaturedEvents({int limit = 3});
  Future<List<Event>> getRegisteredEvents();
  Future<Event?> getNextRegisteredEvent();
}

/// Talks to the real Dart Frog backend.
class EventApiRepository implements EventRepository {
  final ApiClient _api;

  EventApiRepository([ApiClient? api]) : _api = api ?? ApiClient();

  @override
  Future<Event> getEvent(String eventId) async {
    final response = await _api.get(ApiRoutes.eventById(eventId));
    final json = response.data['event'] ?? response.data['events'];
    if (json is! Map<String, dynamic>) {
      throw const ApiException('Something went wrong. Please try again.');
    }
    return Event.fromJson(json);
  }

  @override
  Future<EventListResponse> getEvents({
    String? query,
    List<String>? tags,
    String? cursor,
    int? limit,
  }) async {
    final path = ApiEventsListHelper.buildPath(
      query: query,
      tags: tags,
      cursor: cursor,
      limit: limit,
    );
    final response = await _api.get(path);
    final json = response.data['events'];
    if (json is! List) {
      return const EventListResponse(events: []);
    }
    final events =
        json.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
    final nextCursor = response.data['next_cursor'] as String?;
    return EventListResponse(events: events, nextCursor: nextCursor);
  }

  @override
  Future<List<Event>> getFeaturedEvents({int limit = 3}) async {
    final response = await _api.get(ApiRoutes.eventsFeatured(limit: limit));
    final json = response.data['events'];
    if (json is! List) {
      return const [];
    }
    return json.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Event>> getRegisteredEvents() async {
    final response = await _api.get(ApiRoutes.eventsRegistered);
    final json = response.data['events'];
    if (json is! List) {
      return const [];
    }
    return json.map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Event?> getNextRegisteredEvent() async {
    final response = await _api.get(ApiRoutes.eventsNextRegistered);
    final json = response.data['event'];
    if (json == null || json is! Map<String, dynamic>) {
      return null;
    }
    return Event.fromJson(json);
  }
}

/// Helper to build the events list query path.
class ApiEventsListHelper {
  const ApiEventsListHelper._();

  static String buildPath({
    String? query,
    List<String>? tags,
    String? cursor,
    int? limit,
  }) {
    final params = <String, String>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (tags != null) {
      for (final tag in tags) {
        params['tag'] = Uri.encodeComponent(tag);
      }
    }
    if (cursor != null) params['cursor'] = cursor;
    if (limit != null) params['limit'] = limit.toString();
    if (params.isEmpty) return ApiRoutes.events;
    final qs = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '${ApiRoutes.events}?$qs';
  }
}

/// Returns sample data so the modal can be built and demoed before the backend
/// ships. Pass the id `missing` to exercise the EVT002 not-found state.
class MockEventRepository implements EventRepository {
  final _allEvents = [
    Event.fromJson({
      'event_id': '1',
      'title': 'Paws-to-Pause',
      'description':
          'Take a break with adorable therapy dogs! Relax, de-stress, and enjoy quality time with certified therapy animals.',
      'cover_image_url': 'https://picsum.photos/600/400?random=1',
      'date': '2026-07-21',
      'start_time': '16:00',
      'end_time': '18:30',
      'event_mode': 'offline',
      'location': '7th Floor, Gymnasium, Interweave Building',
      'stream_link': null,
      'host_name': 'Sean Audric Salvado',
      'guest_speaker': null,
      'contact_emails': ['sao@ciit.edu.ph'],
      'tags': ['Students Only', 'Wellness'],
      'is_open_to_guests': true,
      'registered_count': 24,
      'slots_remaining': 6,
    }),
    Event.fromJson({
      'event_id': '2',
      'title': 'Tech Talk: AI in 2026',
      'description': 'Explore the latest in AI and machine learning.',
      'cover_image_url': 'https://picsum.photos/600/400?random=2',
      'date': '2026-07-22',
      'start_time': '13:00',
      'end_time': '15:00',
      'event_mode': 'online',
      'location': null,
      'stream_link': 'https://meet.google.com/abc-defg-hij',
      'host_name': 'Jhervis Arevalo',
      'guest_speaker': 'Dr. Maria Santos',
      'contact_emails': ['jeff.marquez@ciit.edu.ph'],
      'tags': ['Technology', 'Open to All'],
      'is_open_to_guests': true,
      'registered_count': 45,
      'slots_remaining': 55,
    }),
    Event.fromJson({
      'event_id': '3',
      'title': 'End of Classes',
      'description': 'Celebrate the end of the semester!',
      'cover_image_url': 'https://picsum.photos/600/400?random=3',
      'date': '2026-07-25',
      'start_time': '18:30',
      'end_time': '21:00',
      'event_mode': 'offline',
      'location': 'Main Hall, Interweave Building',
      'stream_link': null,
      'host_name': 'Student Council',
      'guest_speaker': null,
      'contact_emails': ['council@ciit.edu.ph'],
      'tags': ['Social', 'Students Only'],
      'is_open_to_guests': false,
      'registered_count': 120,
      'slots_remaining': 30,
    }),
    Event.fromJson({
      'event_id': '1',
      'title': 'Paws-to-Pause',
      'description':
          'Take a break with adorable therapy dogs! Relax, de-stress, and enjoy quality time with certified therapy animals.',
      'cover_image_url': 'https://picsum.photos/600/400?random=1',
      'date': '2026-07-21',
      'start_time': '16:00',
      'end_time': '18:30',
      'event_mode': 'offline',
      'location': '7th Floor, Gymnasium, Interweave Building',
      'stream_link': null,
      'host_name': 'Sean Audric Salvado',
      'guest_speaker': null,
      'contact_emails': ['sao@ciit.edu.ph'],
      'tags': ['Students Only', 'Wellness'],
      'is_open_to_guests': true,
      'registered_count': 24,
      'slots_remaining': 6,
    }),
    Event.fromJson({
      'event_id': '2',
      'title': 'Tech Talk: AI in 2026',
      'description': 'Explore the latest in AI and machine learning.',
      'cover_image_url': 'https://picsum.photos/600/400?random=2',
      'date': '2026-07-22',
      'start_time': '13:00',
      'end_time': '15:00',
      'event_mode': 'online',
      'location': null,
      'stream_link': 'https://meet.google.com/abc-defg-hij',
      'host_name': 'Jhervis Arevalo',
      'guest_speaker': 'Dr. Maria Santos',
      'contact_emails': ['jeff.marquez@ciit.edu.ph'],
      'tags': ['Technology', 'Open to All'],
      'is_open_to_guests': true,
      'registered_count': 45,
      'slots_remaining': 55,
    }),
    Event.fromJson({
      'event_id': '3',
      'title': 'End of Classes',
      'description': 'Celebrate the end of the semester!',
      'cover_image_url': 'https://picsum.photos/600/400?random=3',
      'date': '2026-07-25',
      'start_time': '18:30',
      'end_time': '21:00',
      'event_mode': 'offline',
      'location': 'Main Hall, Interweave Building',
      'stream_link': null,
      'host_name': 'Student Council',
      'guest_speaker': null,
      'contact_emails': ['council@ciit.edu.ph'],
      'tags': ['Social', 'Students Only'],
      'is_open_to_guests': false,
      'registered_count': 120,
      'slots_remaining': 30,
    }),
  ];

  @override
  Future<Event> getEvent(String eventId) async {
    if (eventId == 'missing') {
      throw const ApiException(
        'Event not found.',
        code: EventErrorCodes.notFound,
      );
    }
    return _allEvents.firstWhere(
      (e) => e.eventId == eventId,
      orElse: () => _allEvents.first,
    );
  }

  @override
  Future<EventListResponse> getEvents({
    String? query,
    List<String>? tags,
    String? cursor,
    int? limit,
  }) async {
    var results = List<Event>.from(_allEvents);

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q))
          .toList();
    }

    if (tags != null && tags.isNotEmpty) {
      results =
          results.where((e) => e.tags.any((t) => tags.contains(t))).toList();
    }

    final startIndex = cursor != null ? int.tryParse(cursor) ?? 0 : 0;
    final pageSize = limit ?? 10;
    final page = results.skip(startIndex).take(pageSize).toList();
    final nextIndex = startIndex + pageSize;
    final nextCursor = nextIndex < results.length ? '$nextIndex' : null;

    return EventListResponse(events: page, nextCursor: nextCursor);
  }

  @override
  Future<List<Event>> getFeaturedEvents({int limit = 3}) async {
    final now = DateTime.now();
    final featured = _allEvents
        .where((e) {
          try {
            return DateTime.parse(e.date).isAfter(now);
          } catch (_) {
            return false;
          }
        })
        .take(limit.clamp(0, 10))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return featured;
  }

  @override
  Future<List<Event>> getRegisteredEvents() async {
    // Stub: empty until Registration feature exists.
    return const [];
  }

  @override
  Future<Event?> getNextRegisteredEvent() async {
    // Stub: null until Registration feature exists.
    return null;
  }
}

/// Picks the mock or real repository based on the [useMockEvents] flag.
EventRepository createEventRepository() =>
    useMockEvents ? MockEventRepository() : EventApiRepository();
