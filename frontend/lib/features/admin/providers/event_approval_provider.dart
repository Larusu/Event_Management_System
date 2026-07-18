import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/event_moderation_repository.dart';
import '../models/pending_event.dart';

enum EventApprovalStatus { idle, loading, loaded, error }

/// Screen-scoped state for the event review queue. Loads pending events and
/// approves/rejects them via `PATCH /events/{eventId}/status`.
class EventApprovalProvider extends ChangeNotifier {
  final EventModerationRepository _repository;

  EventApprovalProvider({EventModerationRepository? repository})
      : _repository = repository ?? createEventModerationRepository();

  EventApprovalStatus _status = EventApprovalStatus.idle;
  List<PendingEvent> _events = [];
  String? _errorMessage;
  String? _nextCursor;
  bool _isLoadingMore = false;
  bool _isDisposed = false;

  EventApprovalStatus get status => _status;
  List<PendingEvent> get events => _events;
  String? get errorMessage => _errorMessage;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _nextCursor != null;

  Future<void> load() async {
    _status = EventApprovalStatus.loading;
    _errorMessage = null;
    _events = [];
    _nextCursor = null;
    _safeNotify();

    try {
      final page = await _repository.getPending();
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
      final page = await _repository.getPending(cursor: _nextCursor);
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

  /// Approves or rejects an event, removing it from the queue on success.
  /// Returns `null` on success, or a user-facing error message on failure.
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
      _events = _events.where((e) => e.eventId != eventId).toList();
      _safeNotify();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
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
