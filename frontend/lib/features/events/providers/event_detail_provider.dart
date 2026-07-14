import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/event_repository.dart';
import '../models/event.dart';

enum EventDetailStatus { loading, loaded, error }

/// Loads a single event's detail for the Event Modal. UI reads [status] /
/// [event] / [errorMessage]; all backend work is delegated to
/// [EventRepository]. Mirrors the try/catch pattern used by AuthProvider.
class EventDetailProvider extends ChangeNotifier {
  final EventRepository _repository;

  EventDetailProvider({EventRepository? repository})
      : _repository = repository ?? createEventRepository();

  EventDetailStatus _status = EventDetailStatus.loading;
  Event? _event;
  String? _errorMessage;

  EventDetailStatus get status => _status;
  Event? get event => _event;
  String? get errorMessage => _errorMessage;

  Future<void> load(String eventId) async {
    _status = EventDetailStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _event = await _repository.getEvent(eventId);
      _status = EventDetailStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = EventDetailStatus.error;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _status = EventDetailStatus.error;
    }
    notifyListeners();
  }
}
