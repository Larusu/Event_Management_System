import 'dart:convert';

import 'package:backend/constants/error_codes.dart';
import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/services/event_service.dart';
import 'package:backend/services/firebase_event_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:backend/utils/validators.dart';
import 'package:dart_frog/dart_frog.dart';

final _approvalResetFields = {'title', 'date', 'start_time', 'end_time', 'event_mode', 'location', 'stream_link', 'slots_total'};

Future<Response> onRequest(RequestContext context, String eventId) async {
  if (context.request.method == HttpMethod.get) {
    return _handleGet(context, eventId);
  }

  if (context.request.method == HttpMethod.patch) {
    return _handlePatch(context, eventId);
  }

  if (context.request.method == HttpMethod.delete) {
    return _handleDelete(context, eventId);
  }

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed.'},
  );
}

Future<Response> _handleGet(RequestContext context, String eventId) async {
  try {
    final uid = context.read<String>();

    // These two reads are independent, so run them concurrently instead of
    // back-to-back. isRegisteredForEvent never throws (returns false on any
    // error), so awaiting the event read first still surfaces EVT002 cleanly.
    final eventFuture = FirebaseEventService.getEventById(eventId);
    final registeredFuture =
        FirebaseEventService.isRegisteredForEvent(uid, eventId);
    final event = await eventFuture;
    final isRegistered = await registeredFuture;

    return Response.json(
      body: {
        'success': true,
        'events': {
          ...event.toJson(),
          'is_registered': isRegistered,
        },
      },
    );
  } on AuthException catch (e) {
    return ResponseHelper.error(e);
  } catch (e) {
    return ResponseHelper.error(
      AuthException(AuthErrorCode.internalError, 'Internal server error'),
    );
  }
}

Future<Response> _handlePatch(RequestContext context, String eventId) async {
  final uid = context.read<String>();

  try {
    final bodyString = await context.request.body();
    final body = jsonDecode(bodyString) as Map<String, dynamic>;

    final rawEvent = await FirebaseEventService.getEventDocument(eventId);

    if (rawEvent == null) {
      return ResponseHelper.error(
        AuthException(EventErrorCode.notFound, 'Event not found.'),
      );
    }

    final isDeleted = rawEvent['is_deleted'] as bool? ?? false;
    if (isDeleted) {
      return ResponseHelper.error(
        AuthException(EventErrorCode.notFound, 'Event not found.'),
      );
    }

    final organizerUid = rawEvent['organizer_uid'] as String?;
    final userDoc = context.read<Map<String, dynamic>>();
    final role = userDoc['role'] as String?;

    final isOrganizer = role == 'organizer' && organizerUid == uid;
    final isPrivileged = role == 'faculty' || role == 'super_admin';

    if (!isOrganizer && !isPrivileged) {
      return ResponseHelper.error(
        AuthException(EventErrorCode.permissionDenied, 'Permission denied.'),
      );
    }

    if (body.containsKey('is_open_to_guests')) {
      return ResponseHelper.error(
        AuthException(
          EventErrorCode.isOpenToGuestsLocked,
          'is_open_to_guests cannot be modified.',
        ),
      );
    }

    final validationError = EventValidationService.validateEventPatch(body, rawEvent);
    if (validationError != null) {
      return ResponseHelper.error(
        AuthException(EventErrorCode.validationError, validationError),
      );
    }

    final existingStatus = rawEvent['status'] as String? ?? 'draft';
    final hasApprovalResetFields = body.keys.any((key) => _approvalResetFields.contains(key));

    final updates = Map<String, dynamic>.from(body);

    if (existingStatus == 'approved' && hasApprovalResetFields) {
      updates['status'] = 'pending';
    }

    await FirebaseEventService.updateEvent(eventId, updates);

    // Edits can change title/tags/visibility — refresh the cached snapshot.
    EventService.invalidateCaches();

    return ResponseHelper.success(
      message: 'Event updated successfully.',
    );
  } on AuthException catch (e) {
    return ResponseHelper.error(e);
  } catch (e) {
    return ResponseHelper.error(
      AuthException(AuthErrorCode.internalError, 'Internal server error'),
    );
  }
}

Future<Response> _handleDelete(RequestContext context, String eventId) async {
  final uid = context.read<String>();

  try {
    final rawEvent = await FirebaseEventService.getEventDocument(eventId);

    if (rawEvent == null) {
      return ResponseHelper.error(
        AuthException(EventErrorCode.notFound, 'Event not found.'),
      );
    }

    final isDeleted = rawEvent['is_deleted'] as bool? ?? false;
    if (isDeleted) {
      return ResponseHelper.error(
        AuthException(EventErrorCode.notFound, 'Event not found.'),
      );
    }

    final organizerUid = rawEvent['organizer_uid'] as String?;
    final userDoc = context.read<Map<String, dynamic>>();
    final role = userDoc['role'] as String?;

    final isOrganizer = role == 'organizer' && organizerUid == uid;
    final isPrivileged = role == 'faculty' || role == 'super_admin';

    if (!isOrganizer && !isPrivileged) {
      return ResponseHelper.error(
        AuthException(EventErrorCode.permissionDenied, 'Permission denied.'),
      );
    }

    await FirebaseEventService.softDeleteEvent(eventId);

    // A deleted event must drop out of the feed / tag list right away.
    EventService.invalidateCaches();

    return Response.json(
      statusCode: 200,
      body: {'success': true, 'message': 'Event deleted successfully.'},
    );
  } on AuthException catch (e) {
    return ResponseHelper.error(e);
  } catch (e) {
    return ResponseHelper.error(
      AuthException(AuthErrorCode.internalError, 'Internal server error'),
    );
  }
}