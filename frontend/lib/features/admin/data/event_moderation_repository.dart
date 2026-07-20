import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/pending_event.dart';

/// One page of the pending review queue.
class PendingEventsPage {
  final List<PendingEvent> events;
  final String? nextCursor;

  const PendingEventsPage({required this.events, this.nextCursor});
}

/// Data access for the faculty/super_admin event moderation surface. Screens
/// depend on this interface so it can be backed by a fake in tests.
abstract class EventModerationRepository {
  /// Fetches a page of pending, non-deleted events (oldest first).
  Future<PendingEventsPage> getPending({String? cursor});

  /// Fetches a page of rejected, non-deleted events (oldest first). Rows carry
  /// `rejection_reason` so the reviewer can decide whether to reopen.
  Future<PendingEventsPage> getRejected({String? cursor});

  /// Approves, rejects, or reopens an event. [reason] is only stored on reject.
  Future<void> updateStatus({
    required String eventId,
    required String action,
    String? reason,
  });
}

/// Talks to the real Dart Frog backend.
class EventModerationApiRepository implements EventModerationRepository {
  final ApiClient _api;

  EventModerationApiRepository([ApiClient? api]) : _api = api ?? ApiClient();

  @override
  Future<PendingEventsPage> getPending({String? cursor}) async {
    final response = await _api.get(ApiRoutes.eventsPending(cursor: cursor));
    return _parsePage(response.data);
  }

  @override
  Future<PendingEventsPage> getRejected({String? cursor}) async {
    final response = await _api.get(ApiRoutes.eventsRejected(cursor: cursor));
    return _parsePage(response.data);
  }

  PendingEventsPage _parsePage(Map<String, dynamic> data) {
    final json = data['events'];
    if (json is! List) {
      return const PendingEventsPage(events: []);
    }
    final events = json
        .map((e) => PendingEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    final nextCursor = data['next_cursor'] as String?;
    return PendingEventsPage(events: events, nextCursor: nextCursor);
  }

  @override
  Future<void> updateStatus({
    required String eventId,
    required String action,
    String? reason,
  }) async {
    final body = <String, dynamic>{'action': action};
    if (reason != null && reason.trim().isNotEmpty) {
      body['reason'] = reason.trim();
    }
    await _api.patch(ApiRoutes.eventStatus(eventId), body);
  }
}

/// Moderation data now comes from the live backend.
EventModerationRepository createEventModerationRepository() =>
    EventModerationApiRepository();
