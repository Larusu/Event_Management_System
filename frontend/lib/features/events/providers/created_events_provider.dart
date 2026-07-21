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
  bool _loadedOnce = false;

  bool isDeleting(String eventId) => _deletingEventIds.contains(eventId);

  /// True when [eventId] belongs to the signed-in user. Powers the "Your own
  /// event" state in the Event Modal (frontend-only ownership check).
  bool isOwnEvent(String eventId) =>
      events.any((event) => event.eventId == eventId);

  /// Loads the owned-events list at most once, so ownership data can be warmed
  /// app-wide for organizers without re-fetching on every screen. Use [load] to
  /// force a refresh.
  Future<void> ensureLoaded() async {
    if (_loadedOnce) return;
    await load();
  }

  Future<void> load() async {
    _loadedOnce = true;
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
