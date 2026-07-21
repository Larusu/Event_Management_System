import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/event_repository.dart';
import '../models/event.dart';

enum CalendarStatus { loading, loaded, error }

/// The three calendar layouts. [label] matches the strings shown in the
/// Header's view dropdown so the two stay in sync.
enum CalendarViewMode {
  month('Month'),
  day('Day'),
  week('Week');

  const CalendarViewMode(this.label);

  final String label;

  static CalendarViewMode fromLabel(String label) =>
      CalendarViewMode.values.firstWhere(
        (mode) => mode.label == label,
        orElse: () => CalendarViewMode.month,
      );
}

/// Single source of truth for the Calendar screen. Both the Header (which
/// writes: view + date navigation) and the calendar body (which reads: view,
/// focused date, and the events to render) talk to this provider, so they can
/// never drift out of sync.
///
/// Because `GET /events` is an ascending, cursor-paged feed with no date-range
/// filter, [load] pages forward (up to [_maxPages]) collecting only the events
/// that fall inside the currently visible window, and stops as soon as it sees
/// a date past that window. Mirrors the try/catch pattern used by
/// [EventDetailProvider].
class CalendarProvider extends ChangeNotifier {
  final EventRepository _repository;

  CalendarProvider({EventRepository? repository})
      : _repository = repository ?? createEventRepository();

  /// Per-page fetch size (clamped to 100 server-side).
  static const int _pageSize = 100;

  /// Safety cap so a huge backlog of past events can't page forever.
  static const int _maxPages = 20;

  /// How long loaded data is considered fresh; a focus/resume refresh within
  /// this window is skipped. Aligned with the backend's 60s snapshot cache.
  static const Duration _refreshTtl = Duration(seconds: 60);

  DateTime? _lastLoadedAt;

  CalendarViewMode _viewMode = CalendarViewMode.month;
  DateTime _focusedDate = _dateOnly(DateTime.now());
  CalendarStatus _status = CalendarStatus.loading;
  List<Event> _events = const [];
  String? _errorMessage;

  /// Guards against stale responses: rapid prev/next taps fire overlapping
  /// loads, and only the most recent one should apply its result.
  int _loadToken = 0;

  CalendarViewMode get viewMode => _viewMode;
  DateTime get focusedDate => _focusedDate;
  CalendarStatus get status => _status;
  List<Event> get events => List.unmodifiable(_events);
  String? get errorMessage => _errorMessage;

  /// Events on [day] (date-only), sorted by start time. `HH:mm` sorts
  /// correctly as plain strings because it is zero-padded 24-hour.
  List<Event> eventsOn(DateTime day) {
    final target = _dateOnly(day);
    final list = _events.where((event) {
      final date = _parseDate(event.date);
      return date != null && date == target;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  void setView(CalendarViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    load();
  }

  void goToToday() {
    _focusedDate = _dateOnly(DateTime.now());
    load();
  }

  /// Focuses [date] and switches to the Day view — used when a Month cell is
  /// tapped to drill into that day.
  void openDay(DateTime date) {
    _focusedDate = _dateOnly(date);
    _viewMode = CalendarViewMode.day;
    load();
  }

  /// Focuses [date] without changing the current view — used when a header
  /// strip cell is tapped.
  void goToDate(DateTime date) {
    _focusedDate = _dateOnly(date);
    load();
  }

  void nextPeriod() => _shiftPeriod(1);

  void previousPeriod() => _shiftPeriod(-1);

  void _shiftPeriod(int direction) {
    final d = _focusedDate;
    switch (_viewMode) {
      case CalendarViewMode.day:
        _focusedDate = DateTime(d.year, d.month, d.day + direction);
      case CalendarViewMode.week:
        _focusedDate = DateTime(d.year, d.month, d.day + 7 * direction);
      case CalendarViewMode.month:
        // Snap to the first of the target month to avoid day-overflow
        // (e.g. Jan 31 -> Feb would roll into March).
        _focusedDate = DateTime(d.year, d.month + direction, 1);
    }
    load();
  }

  /// Silently re-fetches the current window when the data is stale, keeping the
  /// current events on screen (no loading spinner) while it updates. Called
  /// when the calendar tab regains focus or the app resumes.
  Future<void> refreshIfStale() async {
    final last = _lastLoadedAt;
    if (last != null && DateTime.now().difference(last) < _refreshTtl) return;
    if (_status == CalendarStatus.loading) return;
    await load(silent: true);
  }

  /// Fetches the events for the currently visible window and updates state.
  ///
  /// When [silent] is true the loading state is not shown (the current events
  /// stay on screen) and a failure is swallowed, keeping the existing data.
  Future<void> load({bool silent = false}) async {
    final token = ++_loadToken;
    if (!silent) {
      _status = CalendarStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    final (rangeStart, rangeEnd) = _visibleRange();

    try {
      final collected = <Event>[];
      String? cursor;

      for (var page = 0; page < _maxPages; page++) {
        final result =
            await _repository.getEvents(cursor: cursor, limit: _pageSize);

        var passedWindow = false;
        for (final event in result.events) {
          final date = _parseDate(event.date);
          if (date == null) continue;
          // Feed is ascending: once we pass the window, every later event is
          // out of range too, so stop scanning this page.
          if (date.isAfter(rangeEnd)) {
            passedWindow = true;
            break;
          }
          if (!date.isBefore(rangeStart)) {
            collected.add(event);
          }
        }

        if (passedWindow || result.nextCursor == null) break;
        cursor = result.nextCursor;
      }

      if (token != _loadToken) return; // superseded by a newer load
      _events = collected;
      _status = CalendarStatus.loaded;
      _lastLoadedAt = DateTime.now();
    } on ApiException catch (e) {
      if (token != _loadToken) return;
      // A silent (focus/resume) refresh keeps the existing events on screen
      // instead of blanking them out with an error.
      if (silent) return;
      _errorMessage = e.message;
      _status = CalendarStatus.error;
    } catch (_) {
      if (token != _loadToken) return;
      if (silent) return;
      _errorMessage = 'Something went wrong. Please try again.';
      _status = CalendarStatus.error;
    }
    notifyListeners();
  }

  /// Inclusive [start, end] date-only window for the current view + focused
  /// date. Week starts on Sunday to match the Header's weekday strip.
  (DateTime, DateTime) _visibleRange() {
    final focused = _dateOnly(_focusedDate);
    switch (_viewMode) {
      case CalendarViewMode.day:
        // Load the focused week (not just the day) so the header strip, which
        // spans the whole week in Day view, can show per-day event dots. The
        // Day grid still filters to the focused day via eventsOn().
        final start = focused.subtract(Duration(days: focused.weekday % 7));
        return (start, start.add(const Duration(days: 6)));
      case CalendarViewMode.week:
        final start = focused.subtract(Duration(days: focused.weekday % 7));
        return (start, start.add(const Duration(days: 6)));
      case CalendarViewMode.month:
        final start = DateTime(focused.year, focused.month, 1);
        final end = DateTime(focused.year, focused.month + 1, 0);
        return (start, end);
    }
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime? _parseDate(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }
}
