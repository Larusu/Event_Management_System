import 'package:flutter/foundation.dart';

import '../../../core/constants/error_codes.dart';
import '../../../core/network/api_exception.dart';
import '../data/event_moderation_repository.dart';
import '../models/pending_event.dart';

enum EventApprovalStatus { idle, loading, loaded, error }

/// Which review queue is being viewed: events awaiting approval, or already
/// rejected events (the reopen surface).
enum ReviewFilter { pending, rejected }

/// Screen-scoped state for the event review queue. Loads pending or rejected
/// events (per [filter]) and moderates them via `PATCH /events/{eventId}/status`.
class EventApprovalProvider extends ChangeNotifier {
  final EventModerationRepository _repository;

  EventApprovalProvider({EventModerationRepository? repository})
      : _repository = repository ?? createEventModerationRepository();

  EventApprovalStatus _status = EventApprovalStatus.idle;
  ReviewFilter _filter = ReviewFilter.pending;
  List<PendingEvent> _events = [];
  String? _errorMessage;
  String? _nextCursor;
  bool _isLoadingMore = false;
  bool _isDisposed = false;

  EventApprovalStatus get status => _status;
  ReviewFilter get filter => _filter;
  List<PendingEvent> get events => _events;
  String? get errorMessage => _errorMessage;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _nextCursor != null;

  /// Switches between the pending and rejected queues, reloading from scratch.
  /// No-op if the filter is unchanged.
  Future<void> setFilter(ReviewFilter filter) async {
    if (_filter == filter) return;
    _filter = filter;
    await load();
  }

  Future<PendingEventsPage> _fetch({String? cursor}) {
    switch (_filter) {
      case ReviewFilter.pending:
        return _repository.getPending(cursor: cursor);
      case ReviewFilter.rejected:
        return _repository.getRejected(cursor: cursor);
    }
  }

  Future<void> load() async {
    _status = EventApprovalStatus.loading;
    _errorMessage = null;
    _events = [];
    _nextCursor = null;
    _safeNotify();

    try {
      final page = await _fetch();
      _events = page.events;
      _nextCursor = page.nextCursor;
      _status = EventApprovalStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = EventApprovalStatus.error;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _status = EventApprovalStatus.error;
    }
    _safeNotify();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _nextCursor == null) return;
    _isLoadingMore = true;
    _safeNotify();

    try {
      final page = await _fetch(cursor: _nextCursor);
      _events = [..._events, ...page.events];
      _nextCursor = page.nextCursor;
    } on ApiException catch (_) {
      // Keep existing data on a load-more failure.
    } catch (_) {
      // Keep existing data.
    }

    _isLoadingMore = false;
    _safeNotify();
  }

  /// Approves, rejects, or reopens an event, removing it from the current queue
  /// on success. Returns `null` on success, or a user-facing error message on
  /// failure. When the failure indicates the event is stale (another reviewer
  /// already acted: EVT005 invalid transition, or EVT002 not found), the row is
  /// also dropped from the list so the queue stays accurate.
  Future<String?> moderate({
    required String eventId,
    required String action,
    String? reason,
  }) async {
    try {
      await _repository.updateStatus(
        eventId: eventId,
        action: action,
        reason: reason,
      );
      _removeEvent(eventId);
      return null;
    } on ApiException catch (e) {
      if (e.code == EventErrorCodes.invalidStatusTransition ||
          e.code == EventErrorCodes.notFound) {
        _removeEvent(eventId);
      }
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  void _removeEvent(String eventId) {
    _events = _events.where((e) => e.eventId != eventId).toList();
    _safeNotify();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
