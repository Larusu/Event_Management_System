import 'dart:convert';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/constants/event_exception.dart';
import 'package:backend/services/event_service.dart';
import 'package:backend/services/firebase_event_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:backend/utils/validators.dart';
import 'package:dart_frog/dart_frog.dart';

/// Default page size when no `limit` query parameter is supplied.
const _defaultLimit = 20;

/// Upper bound on `limit` to protect Firestore from runaway reads.
const _maxLimit = 100;

/// Server-owned fields that must never be accepted from the client.
const _serverOwnedFields = {
  'status',
  'organizer_uid',
  'registered_count',
  'is_deleted',
  'created_at',
  'updated_at',
};

/// Roles allowed to create events.
const _privilegedRoles = {'organizer', 'faculty', 'super_admin'};

/// Status assigned at creation for every role allowed to create an event.
String initialEventStatus(String role) => 'pending';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.get) {
    return _handleGet(context);
  }

  if (context.request.method == HttpMethod.post) {
    return _handlePost(context);
  }

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed.'},
  );
}

// ---------------------------------------------------------------------------
// GET /events
// ---------------------------------------------------------------------------

Future<Response> _handleGet(RequestContext context) async {
  try {
    final query = context.request.url.queryParameters;

    var tagsParam = query['tags'];
    if (tagsParam != null) {
      tagsParam = Uri.decodeComponent(tagsParam);
    }

    final searchParam = query['search'];
    final cursorParam = query['cursor'];
    final limitParam = query['limit'];

    var limit = _defaultLimit;
    if (limitParam != null) {
      final parsedLimit = int.tryParse(limitParam);
      if (parsedLimit == null || parsedLimit < 1) {
        return Response.json(
          statusCode: 400,
          body: {
            'success': false,
            'code': EventErrorCode.invalidQueryParam,
            'message': 'Invalid limit parameter',
          },
        );
      }
      limit =
          parsedLimit > _maxLimit ? _maxLimit : parsedLimit;
    }

    final page = await EventService.fetchEvents(
      tags: tagsParam,
      search: searchParam,
      cursor: cursorParam,
      limit: limit,
    );

    String? nextCursor;
    if (page.nextCursor != null) {
      nextCursor = base64.encode(
        utf8.encode(jsonEncode(page.nextCursor)),
      );
    }

    final responseEvents = page.events.map((event) {
      return {
        'event_id': event.eventId,
        'title': event.title,
        'cover_image_url': event.coverImageUrl,
        'date': event.date,
        'start_time': event.startTime,
        'end_time': event.endTime,
        'tags': event.tags,
        'slots_total': event.slotsTotal,
        'registered_count': event.registeredCount,
        'slots_remaining': event.slotsRemaining,
      };
    }).toList();

    return ResponseHelper.success(
      message: 'Events retrieved successfully.',
      data: {
        'events': responseEvents,
        'next_cursor': nextCursor,
      },
    );
  } on EventException catch (e) {
    return ResponseHelper.errorFromException(e);
  } catch (e, stack) {
    // ignore: avoid_print
    print(
      '${EventErrorCode.internalError} '
      'Internal error: $e\n$stack',
    );
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'code': EventErrorCode.internalError,
        'message': 'Internal server error',
      },
    );
  }
}

// ---------------------------------------------------------------------------
// POST /events — create event
// ---------------------------------------------------------------------------

Future<Response> _handlePost(RequestContext context) async {
  final uid = context.read<String>();

  try {
    final userDoc = context.read<Map<String, dynamic>>();
    final role = userDoc['role'] as String? ?? '';

    // --- Role gate (EVT004) ---
    if (!_privilegedRoles.contains(role)) {
      return ResponseHelper.error(
        AuthException(
          EventErrorCode.permissionDenied,
          'You do not have permission to perform this action.',
        ),
      );
    }

    // --- Parse body ---
    final bodyString = await context.request.body();
    final body =
        jsonDecode(bodyString) as Map<String, dynamic>;

    // --- Strip server-owned fields silently ---
    for (final field in _serverOwnedFields) {
      body.remove(field);
    }

    // --- Validate ---
    final validationError =
        EventValidationService.validateCreateEvent(body);
    if (validationError != null) {
      return ResponseHelper.error(
        AuthException(
          EventErrorCode.validationFailed,
          validationError,
        ),
      );
    }

    // Every newly created event must be reviewed, regardless of creator role.
    final status = initialEventStatus(role);

    // --- Generate event ID ---
    final title = body['title'] as String;
    final eventId =
        FirebaseEventService.generateEventId(title);

    // --- Build Firestore fields ---
    final now = DateTime.now().toUtc().toIso8601String();
    final fields = <String, dynamic>{
      ...body,
      'status': status,
      'organizer_uid': uid,
      'registered_count': 0,
      'is_deleted': false,
      'created_at': now,
      'updated_at': now,
    };

    // --- Persist ---
    await FirebaseEventService.createEvent(
      fields: fields,
      eventId: eventId,
    );

    // A new event can add tags / change the feed — drop the cached snapshot so
    // it (and any new tags) surface immediately on this instance.
    EventService.invalidateCaches();

    // --- Build response ---
    final eventResponse = <String, dynamic>{
      'event_id': eventId,
      ...body,
      'status': status,
      'organizer_uid': uid,
      'registered_count': 0,
      'is_deleted': false,
      'created_at': now,
      'updated_at': now,
    };

    return ResponseHelper.success(
      message: 'Event submitted for approval.',
      data: {'event': eventResponse},
    );
  } on AuthException catch (e) {
    return ResponseHelper.error(e);
  } catch (e, stack) {
    // ignore: avoid_print
    print(
      '${EventErrorCode.internalError} '
      'Internal error: $e\n$stack',
    );
    return ResponseHelper.error(
      AuthException(
        EventErrorCode.internalError,
        'Internal server error',
      ),
    );
  }
}
