import 'dart:convert';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/services/event_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  try {
    final query = context.request.url.queryParameters;

    var tagsParam = query['tags'];
    if (tagsParam != null) {
      tagsParam = Uri.decodeComponent(tagsParam);
    }

    final searchParam = query['search'];
    final cursorParam = query['cursor'];
    final limitParam = query['limit'];

    var limit = 20;
    if (limitParam != null) {
      final parsedLimit = int.tryParse(limitParam);
      if (parsedLimit == null || parsedLimit < 1) {
        return Response.json(
          statusCode: 400,
          body: {
            'success': false,
            'code': EventErrorCode.invalidCursor,
            'message': 'Invalid limit parameter',
          },
        );
      }
      limit = parsedLimit;
    }

    final events = await EventService.fetchEvents(
      tags: tagsParam,
      search: searchParam,
      cursor: cursorParam,
      limit: limit,
    );

    String? nextCursor;
    if (events.length == limit && events.isNotEmpty) {
      final lastEvent = events.last;
      final cursorData = {
        'date': lastEvent.date,
        'eventId': lastEvent.eventId,
      };
      nextCursor = base64.encode(
        utf8.encode(jsonEncode(cursorData)),
      );
    }

    final responseEvents = events.map((event) {
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
  } catch (e) {
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