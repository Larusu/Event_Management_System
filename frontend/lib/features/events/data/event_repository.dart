import 'package:http_parser/http_parser.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/event.dart';
import '../models/event_list_response.dart';

/// Data access for the events feature. Screens depend on this interface, not on
/// a concrete implementation, so it can be backed by a fake in tests without
/// touching the UI.
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
  Future<List<String>> getTags();
  Future<Map<String, dynamic>> registerForEvent(String eventId);

  /// Uploads a cover image to `POST /events/cover-image` and
  /// returns the hosted Cloudinary URL to attach to a create/edit call.
  Future<String> uploadCoverImage({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  });

  /// Creates an event via `POST /events`. [body] must already
  /// contain a `cover_image_url` from [uploadCoverImage].
  Future<Event> createEvent(Map<String, dynamic> body);
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

  @override
  Future<List<String>> getTags() async {
    final response = await _api.get(ApiRoutes.eventsTags);
    final json = response.data['tags'];
    if (json is! List) return const [];
    return json.map((e) => e.toString()).toList();
  }

  @override
  Future<Map<String, dynamic>> registerForEvent(String eventId) async {
    final response = await _api.post(
      ApiRoutes.eventRegister(eventId),
      {},
    );
    return response.data;
  }

  @override
  Future<String> uploadCoverImage({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    final response = await _api.postMultipart(
      ApiRoutes.eventsCoverImage,
      field: 'image',
      bytes: bytes,
      filename: filename,
      contentType: MediaType.parse(mimeType),
    );
    final url = response.data['cover_image_url'] as String?;
    if (url == null || url.isEmpty) {
      throw const ApiException('Image upload failed. Please try again.');
    }
    return url;
  }

  @override
  Future<Event> createEvent(Map<String, dynamic> body) async {
    final response = await _api.post(ApiRoutes.events, body, auth: true);
    final json = response.data['event'];
    if (json is! Map<String, dynamic>) {
      throw const ApiException('Something went wrong. Please try again.');
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
    if (query != null && query.isNotEmpty) params['search'] = query;
    if (tags != null && tags.isNotEmpty) {
      params['tags'] = Uri.encodeComponent(tags.join(','));
    }
    if (cursor != null) params['cursor'] = cursor;
    if (limit != null) params['limit'] = limit.toString();
    if (params.isEmpty) return ApiRoutes.events;
    final qs = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '${ApiRoutes.events}?$qs';
  }
}

/// All event data now comes from the live backend.
EventRepository createEventRepository() => EventApiRepository();
