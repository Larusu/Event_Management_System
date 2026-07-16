import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/event_repository.dart';
import '../models/event.dart';

enum EventDetailStatus { idle, loading, loaded, error }

/// Loads a single event by ID. Used by the event modal.
///
/// Each modal creates its own scoped instance so concurrent modals
/// do not interfere with each other's state.
class EventDetailProvider extends ChangeNotifier {
  final EventRepository _repository;

  EventDetailProvider({EventRepository? repository})
      : _repository = repository ?? createEventRepository();

  EventDetailStatus _status = EventDetailStatus.idle;
  Event? _event;
  String? _errorMessage;
  bool _isDisposed = false;

  EventDetailStatus get status => _status;
  Event? get event => _event;
  String? get errorMessage => _errorMessage;

  Future<void> load(String eventId) async {
    _status = EventDetailStatus.loading;
    _errorMessage = null;
    _safeNotify();

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
