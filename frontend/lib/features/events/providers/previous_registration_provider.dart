import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/event_repository.dart';
import '../models/event.dart';

enum PreviousRegisteredEventsStatus { idle, loading, loaded, error }

/// Loads the signed-in user's past event registrations, newest first.
class PreviousRegisteredEventsProvider extends ChangeNotifier {
  PreviousRegisteredEventsProvider({
    PreviousRegisteredEventsRepository? repository,
    DateTime Function()? now,
  })  : _repository = repository ?? createPreviousRegisteredEventsRepository(),
        _now = now ?? DateTime.now;

  final PreviousRegisteredEventsRepository _repository;
  final DateTime Function() _now;

  PreviousRegisteredEventsStatus _status =
      PreviousRegisteredEventsStatus.idle;
  final List<Event> _events = [];
  String? _nextCursor;
  String? _errorMessage;
  bool _isLoadingMore = false;
  bool _isDisposed = false;

  PreviousRegisteredEventsStatus get status => _status;
  List<Event> get events => List.unmodifiable(_events);
  String? get errorMessage => _errorMessage;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _nextCursor != null;

  Future<void> load() async {
    _status = PreviousRegisteredEventsStatus.loading;
    _errorMessage = null;
    _safeNotify();

    try {
      final page = await _repository.getPreviousRegisteredEvents();
      final completedToday = await _loadCompletedToday();
      _events
        ..clear()
        ..addAll(_completedEvents([...page.events, ...completedToday]));
      _nextCursor = page.nextCursor;
      _status = PreviousRegisteredEventsStatus.loaded;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _status = PreviousRegisteredEventsStatus.error;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _status = PreviousRegisteredEventsStatus.error;
    }
    _safeNotify();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _nextCursor == null) return;

    _isLoadingMore = true;
    _safeNotify();
    try {
      final page = await _repository.getPreviousRegisteredEvents(
        cursor: _nextCursor,
      );
      final knownIds = _events.map((event) => event.eventId).toSet();
      _events.addAll(
        _completedEvents(page.events)
            .where((event) => knownIds.add(event.eventId)),
      );
      _sortNewestFirst(_events);
      _nextCursor = page.nextCursor;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Could not load more registrations.';
    } finally {
      _isLoadingMore = false;
      _safeNotify();
    }
  }

  /// The backend's `past` filter is date-only. Events from today remain in
  /// `upcoming`, so read today's pages and classify them using their end time.
  Future<List<Event>> _loadCompletedToday() async {
    final completed = <Event>[];
    String? cursor;
    final today = _dateOnly(_now());

    do {
      final page = await _repository.getUpcomingRegisteredEvents(
        cursor: cursor,
      );
      completed.addAll(page.events.where(_hasEnded));
      cursor = page.nextCursor;

      final hasFutureEvent = page.events.any((event) {
        final eventDate = _parseDate(event.date);
        return eventDate != null && eventDate.isAfter(today);
      });
      if (hasFutureEvent) break;
    } while (cursor != null);

    return completed;
  }

  List<Event> _completedEvents(Iterable<Event> candidates) {
    final unique = <String, Event>{};
    for (final event in candidates) {
      if (_hasEnded(event)) unique[event.eventId] = event;
    }
    final completed = unique.values.toList();
    _sortNewestFirst(completed);
    return completed;
  }

  bool _hasEnded(Event event) {
    final end = _eventEnd(event);
    return end != null && !end.isAfter(_now());
  }

  DateTime? _eventEnd(Event event) {
    final date = _parseDate(event.date);
    final timeParts = event.endTime.split(':');
    if (date == null || timeParts.length < 2) return null;

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    final second = timeParts.length > 2 ? int.tryParse(timeParts[2]) : 0;
    if (hour == null ||
        minute == null ||
        second == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59 ||
        second < 0 ||
        second > 59) {
      return null;
    }
    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
      second,
    );
  }

  DateTime? _parseDate(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null ? null : _dateOnly(parsed);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  void _sortNewestFirst(List<Event> events) {
    events.sort((a, b) {
      final aEnd = _eventEnd(a);
      final bEnd = _eventEnd(b);
      if (aEnd == null && bEnd == null) return 0;
      if (aEnd == null) return 1;
      if (bEnd == null) return -1;
      return bEnd.compareTo(aEnd);
    });
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
