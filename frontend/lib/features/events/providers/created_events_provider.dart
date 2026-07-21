import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/event_repository.dart';
import '../models/event.dart';

enum CreatedEventsStatus { loading, loaded, error }

class CreatedEventsProvider extends ChangeNotifier {
  CreatedEventsProvider({EventRepository? repository})
      : _repository = repository ?? createEventRepository();

  final EventRepository _repository;
  CreatedEventsStatus status = CreatedEventsStatus.loading;
  List<Event> events = const [];
  String? errorMessage;
  final Set<String> _deletingEventIds = {};

  bool isDeleting(String eventId) => _deletingEventIds.contains(eventId);

  /// True when [eventId] belongs to the signed-in user. Powers the "Your own
  /// event" state in the Event Modal (frontend-only ownership check).
  bool isOwnEvent(String eventId) =>
      events.any((event) => event.eventId == eventId);

  /// Clears cached ownership data so a newly signed-in user cannot inherit the
  /// previous user's owned-events list. This provider is app-level (single
  /// instance for the app's lifetime), so it MUST be reset on every user
  /// change — otherwise `isOwnEvent` reads a stale list and the Event Modal
  /// shows the wrong "Event Owner" / "Register" state until an app restart.
  void reset() {
    events = const [];
    errorMessage = null;
    _deletingEventIds.clear();
    status = CreatedEventsStatus.loading;
    notifyListeners();
  }

  Future<void> load() async {
    status = CreatedEventsStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      events = await _repository.getCreatedEvents();
      status = CreatedEventsStatus.loaded;
    } on ApiException catch (error) {
      errorMessage = error.message;
      status = CreatedEventsStatus.error;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
      status = CreatedEventsStatus.error;
    }
    notifyListeners();
  }

  Future<bool> deleteEvent(String eventId) async {
    if (_deletingEventIds.contains(eventId)) return false;
    _deletingEventIds.add(eventId);
    notifyListeners();
    try {
      await _repository.deleteEvent(eventId);
      events = events.where((event) => event.eventId != eventId).toList();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = 'Could not delete the event. Please try again.';
      return false;
    } finally {
      _deletingEventIds.remove(eventId);
      notifyListeners();
    }
  }
}
