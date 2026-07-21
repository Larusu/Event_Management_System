import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/event_repository.dart';
import '../models/event.dart';
import 'event_detail_provider.dart';
import 'event_list_provider.dart';

/// Featured events, registered events, and next registered event.
/// Used by the dashboard screen.
class EventDashboardProvider extends ChangeNotifier {
  final EventRepository _repository;
  final DateTime Function() _now;

  EventDashboardProvider({
    EventRepository? repository,
    DateTime Function()? now,
  })  : _repository = repository ?? createEventRepository(),
        _now = now ?? DateTime.now;

  /// How long loaded data is considered fresh; a focus/resume refresh within
  /// this window is skipped. Aligned with the backend's 60s snapshot cache.
  static const Duration _refreshTtl = Duration(seconds: 60);

  DateTime? _lastLoadedAt;

  /// Silently re-fetches all sections when the data is stale, keeping the
  /// current content visible (no loading spinner) while it updates. Called when
  /// the dashboard tab regains focus or the app resumes.
  Future<void> refreshIfStale() async {
    final last = _lastLoadedAt;
    if (last != null && _now().difference(last) < _refreshTtl) return;
    if (_featuredStatus == EventListStatus.loading ||
        _registeredStatus == EventListStatus.loading ||
        _nextRegisteredStatus == EventDetailStatus.loading) {
      return;
    }
    await Future.wait([
      loadNextRegistered(silent: true),
      loadFeatured(silent: true),
      loadRegistered(silent: true),
    ]);
  }

  // ── Featured events ──
  EventListStatus _featuredStatus = EventListStatus.idle;
  List<Event> _featuredEvents = [];
  String? _featuredErrorMessage;

  EventListStatus get featuredStatus => _featuredStatus;
  List<Event> get featuredEvents => _featuredEvents;
  String? get featuredErrorMessage => _featuredErrorMessage;

  // ── Registered events ──
  EventListStatus _registeredStatus = EventListStatus.idle;
  List<Event> _registeredEvents = [];
  String? _registeredErrorMessage;

  EventListStatus get registeredStatus => _registeredStatus;
  List<Event> get registeredEvents => _registeredEvents;
  String? get registeredErrorMessage => _registeredErrorMessage;

  // ── Next registered event ──
  EventDetailStatus _nextRegisteredStatus = EventDetailStatus.idle;
  Event? _nextRegisteredEvent;
  String? _nextRegisteredErrorMessage;

  EventDetailStatus get nextRegisteredStatus => _nextRegisteredStatus;
  Event? get nextRegisteredEvent => _nextRegisteredEvent;
  String? get nextRegisteredErrorMessage => _nextRegisteredErrorMessage;

  bool _isDisposed = false;

  // ── Load methods ──

  Future<void> loadFeatured({bool silent = false}) async {
    if (!silent) {
      _featuredStatus = EventListStatus.loading;
      _featuredErrorMessage = null;
      _safeNotify();
    }

    try {
      _featuredEvents = await _repository.getFeaturedEvents();
      _featuredStatus = EventListStatus.loaded;
      _lastLoadedAt = _now();
    } on ApiException catch (e) {
      // A silent (focus/resume) refresh keeps the existing data on screen
      // instead of blanking it out with an error.
      if (silent) return;
      _featuredErrorMessage = e.message;
      _featuredStatus = EventListStatus.error;
    } catch (_) {
      if (silent) return;
      _featuredErrorMessage = 'Something went wrong. Please try again.';
      _featuredStatus = EventListStatus.error;
    }
    _safeNotify();
  }

  Future<void> loadRegistered({bool silent = false}) async {
    if (!silent) {
      _registeredStatus = EventListStatus.loading;
      _registeredErrorMessage = null;
      _safeNotify();
    }

    try {
      final registered = await _repository.getRegisteredEvents();
      // Drop events that have already ended so only genuinely upcoming
      // registrations are shown; the backend `registered` feed still includes
      // same-day events whose end time has passed.
      _registeredEvents = registered.where(_isUpcoming).toList()
        ..sort(_bySoonestFirst);
      _registeredStatus = EventListStatus.loaded;
      _lastLoadedAt = _now();
    } on ApiException catch (e) {
      if (silent) return;
      _registeredErrorMessage = e.message;
      _registeredStatus = EventListStatus.error;
    } catch (_) {
      if (silent) return;
      _registeredErrorMessage = 'Something went wrong. Please try again.';
      _registeredStatus = EventListStatus.error;
    }
    _safeNotify();
  }

  Future<void> loadNextRegistered({bool silent = false}) async {
    if (!silent) {
      _nextRegisteredStatus = EventDetailStatus.loading;
      _nextRegisteredErrorMessage = null;
      _safeNotify();
    }

    try {
      final next = await _repository.getNextRegisteredEvent();
      // Guard against the endpoint surfacing an event that has already ended.
      _nextRegisteredEvent = (next != null && _isUpcoming(next)) ? next : null;
      _nextRegisteredStatus = EventDetailStatus.loaded;
      _lastLoadedAt = _now();
    } on ApiException catch (e) {
      if (silent) return;
      _nextRegisteredErrorMessage = e.message;
      _nextRegisteredStatus = EventDetailStatus.error;
    } catch (_) {
      if (silent) return;
      _nextRegisteredErrorMessage = 'Something went wrong. Please try again.';
      _nextRegisteredStatus = EventDetailStatus.error;
    }
    _safeNotify();
  }

  /// True when [event] has not yet ended (its date + end time is in the
  /// future relative to [_now]).
  bool _isUpcoming(Event event) {
    final end = _eventEnd(event);
    return end == null || end.isAfter(_now());
  }

  int _bySoonestFirst(Event a, Event b) {
    final aEnd = _eventEnd(a);
    final bEnd = _eventEnd(b);
    if (aEnd == null && bEnd == null) return 0;
    if (aEnd == null) return 1;
    if (bEnd == null) return -1;
    return aEnd.compareTo(bEnd);
  }

  DateTime? _eventEnd(Event event) {
    final date = DateTime.tryParse(event.date);
    final parts = event.endTime.split(':');
    if (date == null || parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, hour, minute);
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
