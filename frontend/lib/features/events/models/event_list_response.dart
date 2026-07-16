import 'event.dart';

/// Wraps a paginated event list response from the backend.
///
/// Contains the events and an optional [nextCursor] for infinite scroll.
/// When [nextCursor] is null, there are no more pages to load.
class EventListResponse {
  final List<Event> events;
  final String? nextCursor;

  const EventListResponse({required this.events, this.nextCursor});
}
