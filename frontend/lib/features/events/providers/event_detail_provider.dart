import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/event_repository.dart';
import '../models/event.dart';

enum EventDetailStatus { idle, loading, loaded, error }

enum RegistrationStatus { idle, loading, success, error }

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
  RegistrationStatus _registrationStatus = RegistrationStatus.idle;
  String? _registrationError;

  EventDetailStatus get status => _status;
  Event? get event => _event;
  String? get errorMessage => _errorMessage;
  RegistrationStatus get registrationStatus => _registrationStatus;
  String? get registrationError => _registrationError;

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

  Future<bool> register(String eventId) async {
    _registrationStatus = RegistrationStatus.loading;
    _registrationError = null;
    _safeNotify();

    try {
      final data = await _repository.registerForEvent(eventId);
      final eventJson = data['event'] as Map<String, dynamic>?;
      if (eventJson != null && _event != null) {
        _event = Event(
          eventId: _event!.eventId,
          title: _event!.title,
          description: _event!.description,
          coverImageUrl: _event!.coverImageUrl,
          date: _event!.date,
          startTime: _event!.startTime,
          endTime: _event!.endTime,
          eventMode: _event!.eventMode,
          location: _event!.location,
          streamLink: _event!.streamLink,
          hostName: _event!.hostName,
          guestSpeaker: _event!.guestSpeaker,
          contactEmails: _event!.contactEmails,
          tags: _event!.tags,
          isOpenToGuests: _event!.isOpenToGuests,
          registeredCount: (eventJson['registered_count'] as num?)?.toInt() ??
              _event!.registeredCount,
          slotsRemaining: (eventJson['slots_remaining'] as num?)?.toInt() ??
              _event!.slotsRemaining,
          isRegistered: eventJson['is_registered'] as bool? ?? true,
        );
      }
      _registrationStatus = RegistrationStatus.success;
      _safeNotify();
      return true;
    } on ApiException catch (e) {
      _registrationError = e.message;
      _registrationStatus = RegistrationStatus.error;
      _safeNotify();
      return false;
    } catch (_) {
      _registrationError = 'Something went wrong. Please try again.';
      _registrationStatus = RegistrationStatus.error;
      _safeNotify();
      return false;
    }
  }

  void resetRegistrationStatus() {
    _registrationStatus = RegistrationStatus.idle;
    _registrationError = null;
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
