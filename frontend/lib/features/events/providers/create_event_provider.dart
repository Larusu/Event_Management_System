import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/event_repository.dart';
import '../models/event.dart';

/// Lifecycle of the two-step create flow: upload the cover image, then POST the
/// event. [uploading] and [submitting] map to the two backend calls so the UI
/// can show accurate progress.
enum CreateEventStatus { idle, uploading, submitting, success, error }

/// Fields whose change forces an approved event owned by an organizer back into
/// the review queue (mirrors the backend's `_approvalResetFields`). Edits by
/// faculty/super_admin never reset status.
const approvalResetFields = <String>{
  'title',
  'date',
  'start_time',
  'end_time',
  'event_mode',
  'location',
  'stream_link',
  'slots_total',
};

/// Builds the subset of PATCH fields that actually differ from [existing].
///
/// The backend keys re-approval off the mere *presence* of an approval-reset
/// field in the PATCH body, so sending a full body would bounce an approved
/// event back to pending on any edit. Returning only changed fields keeps edits
/// minimal and makes the re-approval warning accurate. [imagePicked] marks the
/// cover image as changed since its URL is otherwise untouched.
Map<String, dynamic> changedEventFields({
  required Event existing,
  required String title,
  required String description,
  required String coverImageUrl,
  required bool imagePicked,
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
  required int slotsTotal,
}) {
  final candidate = <String, dynamic>{
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
    'slots_total': slotsTotal,
    'guest_speaker': guestSpeaker?.trim() ?? '',
  };
  if (eventMode == 'online') {
    candidate['stream_link'] = streamLink?.trim() ?? '';
  } else {
    candidate['location'] = location?.trim() ?? '';
  }

  final existingTotal = existing.registeredCount + existing.slotsRemaining;
  final changed = <String, dynamic>{};
  candidate.forEach((key, value) {
    final unchanged = switch (key) {
      'title' => value == existing.title,
      'description' => value == existing.description,
      // The cover URL only changes when the user picks a new image.
      'cover_image_url' => !imagePicked,
      'date' => value == existing.date,
      'start_time' => value == existing.startTime,
      'end_time' => value == existing.endTime,
      'event_mode' => value == existing.eventMode,
      'host_name' => value == existing.hostName,
      'contact_emails' =>
        listEquals(value as List<String>, existing.contactEmails),
      'tags' => listEquals(value as List<String>, existing.tags),
      'slots_total' => value == existingTotal,
      'location' => value == (existing.location ?? ''),
      'stream_link' => value == (existing.streamLink ?? ''),
      'guest_speaker' => value == (existing.guestSpeaker ?? ''),
      _ => false,
    };
    if (!unchanged) changed[key] = value;
  });
  return changed;
}

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
    List<int>? imageBytes,
    String? imageFilename,
    String? imageMimeType,
    Event? existingEvent,
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
      var coverImageUrl = existingEvent?.coverImageUrl ?? '';
      if (imageBytes != null) {
        coverImageUrl = await _repository.uploadCoverImage(
          bytes: imageBytes,
          filename: imageFilename ?? 'cover.jpg',
          mimeType: imageMimeType ?? 'image/jpeg',
        );
      }

      _status = CreateEventStatus.submitting;
      _safeNotify();

      if (existingEvent == null) {
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
          'slots_total': slotsTotal,
          'is_open_to_guests': isOpenToGuests,
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
      } else {
        // Edit: PATCH only the fields that actually changed. is_open_to_guests
        // is locked after creation, so it is never part of the diff.
        final body = changedEventFields(
          existing: existingEvent,
          title: title,
          description: description,
          coverImageUrl: coverImageUrl,
          imagePicked: imageBytes != null,
          date: date,
          startTime: startTime,
          endTime: endTime,
          eventMode: eventMode,
          location: location,
          streamLink: streamLink,
          hostName: hostName,
          guestSpeaker: guestSpeaker,
          contactEmails: contactEmails,
          tags: tags,
          slotsTotal: slotsTotal,
        );
        if (body.isNotEmpty) {
          await _repository.updateEvent(existingEvent.eventId, body);
        }
      }
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
