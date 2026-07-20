import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/event_repository.dart';
import '../models/event.dart';

/// Lifecycle of the two-step create flow: upload the cover image, then POST the
/// event. [uploading] and [submitting] map to the two backend calls so the UI
/// can show accurate progress.
enum CreateEventStatus { idle, uploading, submitting, success, error }

/// Drives the New Event modal. Scoped per-modal (not global) so a dismissed
/// form leaves no lingering state.
class CreateEventProvider extends ChangeNotifier {
  final EventRepository _repository;

  CreateEventProvider({EventRepository? repository})
      : _repository = repository ?? createEventRepository();

  CreateEventStatus _status = CreateEventStatus.idle;
  String? _errorMessage;
  Event? _createdEvent;
  bool _isDisposed = false;

  CreateEventStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Event? get createdEvent => _createdEvent;

  /// True while either backend call is in flight (used to gate the submit
  /// button and show a spinner).
  bool get isBusy =>
      _status == CreateEventStatus.uploading ||
      _status == CreateEventStatus.submitting;

  /// Runs the two-step create: uploads [imageBytes] to Cloudinary, then creates
  /// the event with the returned URL. Returns true on success.
  ///
  /// [eventMode] must be `online` or `offline`; the matching [streamLink] /
  /// [location] is attached accordingly. [guestSpeaker] is omitted when empty.
  Future<bool> submit({
    required List<int> imageBytes,
    required String imageFilename,
    required String imageMimeType,
    required String title,
    required String description,
    required String date,
    required String startTime,
    required String endTime,
    required String eventMode,
    String? location,
    String? streamLink,
    required String hostName,
    String? guestSpeaker,
    required List<String> contactEmails,
    required List<String> tags,
    required bool isOpenToGuests,
    required int slotsTotal,
  }) async {
    _errorMessage = null;
    _status = CreateEventStatus.uploading;
    _safeNotify();

    try {
      final coverImageUrl = await _repository.uploadCoverImage(
        bytes: imageBytes,
        filename: imageFilename,
        mimeType: imageMimeType,
      );

      _status = CreateEventStatus.submitting;
      _safeNotify();

      final body = <String, dynamic>{
        'title': title.trim(),
        'description': description.trim(),
        'cover_image_url': coverImageUrl,
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
        'event_mode': eventMode,
        'host_name': hostName.trim(),
        'contact_emails': contactEmails,
        'tags': tags,
        'is_open_to_guests': isOpenToGuests,
        'slots_total': slotsTotal,
      };
      if (eventMode == 'online') {
        body['stream_link'] = streamLink?.trim();
      } else {
        body['location'] = location?.trim();
      }
      if (guestSpeaker != null && guestSpeaker.trim().isNotEmpty) {
        body['guest_speaker'] = guestSpeaker.trim();
      }

      _createdEvent = await _repository.createEvent(body);
      _status = CreateEventStatus.success;
      _safeNotify();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = CreateEventStatus.error;
      _safeNotify();
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _status = CreateEventStatus.error;
      _safeNotify();
      return false;
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
