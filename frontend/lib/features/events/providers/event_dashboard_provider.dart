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

  EventDashboardProvider({EventRepository? repository})
      : _repository = repository ?? createEventRepository();

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

  Future<void> loadFeatured() async {
    _featuredStatus = EventListStatus.loading;
    _featuredErrorMessage = null;
    _safeNotify();

    try {
      _featuredEvents = await _repository.getFeaturedEvents();
      _featuredStatus = EventListStatus.loaded;
    } on ApiException catch (e) {
      _featuredErrorMessage = e.message;
      _featuredStatus = EventListStatus.error;
    } catch (_) {
      _featuredErrorMessage = 'Something went wrong. Please try again.';
      _featuredStatus = EventListStatus.error;
    }
    _safeNotify();
  }

  Future<void> loadRegistered() async {
    _registeredStatus = EventListStatus.loading;
    _registeredErrorMessage = null;
    _safeNotify();

    try {
      _registeredEvents = await _repository.getRegisteredEvents();
      _registeredStatus = EventListStatus.loaded;
    } on ApiException catch (e) {
      _registeredErrorMessage = e.message;
      _registeredStatus = EventListStatus.error;
    } catch (_) {
      _registeredErrorMessage = 'Something went wrong. Please try again.';
      _registeredStatus = EventListStatus.error;
    }
    _safeNotify();
  }

  Future<void> loadNextRegistered() async {
    _nextRegisteredStatus = EventDetailStatus.loading;
    _nextRegisteredErrorMessage = null;
    _safeNotify();

    try {
      _nextRegisteredEvent = await _repository.getNextRegisteredEvent();
      _nextRegisteredStatus = EventDetailStatus.loaded;
    } on ApiException catch (e) {
      _nextRegisteredErrorMessage = e.message;
      _nextRegisteredStatus = EventDetailStatus.error;
    } catch (_) {
      _nextRegisteredErrorMessage = 'Something went wrong. Please try again.';
      _nextRegisteredStatus = EventDetailStatus.error;
    }
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
