import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/event_repository.dart';
import '../models/event.dart';

enum EventListStatus { idle, loading, loaded, error }

/// Paginated, searchable, filterable event list. Used by the events screen.
class EventListProvider extends ChangeNotifier {
  final EventRepository _repository;

  EventListProvider({EventRepository? repository})
      : _repository = repository ?? createEventRepository();

  EventListStatus _status = EventListStatus.idle;
  List<Event> _events = [];
  String? _errorMessage;
  String? _nextCursor;
  bool _isLoadingMore = false;
  bool _isDisposed = false;
  String? _currentQuery;
  List<String>? _currentTags;
  List<String> _tags = [];

  EventListStatus get status => _status;
  List<Event> get events => _events;
  String? get errorMessage => _errorMessage;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _nextCursor != null;
  List<String> get tags => _tags;

  Future<void> load({
    String? query,
    List<String>? tags,
    bool reset = false,
  }) async {
    if (reset || query != _currentQuery || !_listEquals(tags, _currentTags)) {
      _events = [];
      _nextCursor = null;
    }
    _currentQuery = query;
    _currentTags = tags;
    _status = EventListStatus.loading;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await _repository.getEvents(
        query: query,
        tags: tags,
        limit: 10,
      );
      _events = response.events;
      _nextCursor = response.nextCursor;
      _status = EventListStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = EventListStatus.error;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _status = EventListStatus.error;
    }
    _safeNotify();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _nextCursor == null) return;
    _isLoadingMore = true;
    _safeNotify();

    try {
      final response = await _repository.getEvents(
        query: _currentQuery,
        tags: _currentTags,
        cursor: _nextCursor,
        limit: 10,
      );
      _events = [..._events, ...response.events];
      _nextCursor = response.nextCursor;
    } on ApiException catch (_) {
      // Silently fail on load more — keep existing data.
    } catch (_) {
      // Silently fail on load more.
    }

    _isLoadingMore = false;
    _safeNotify();
  }

  static bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> loadTags() async {
    try {
      _tags = await _repository.getTags();
      _safeNotify();
    } catch (_) {
      // Silently fail — tags stay empty.
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
