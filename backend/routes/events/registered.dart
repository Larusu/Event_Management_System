import 'dart:convert';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/services/event_service.dart';
import 'package:backend/services/registration_list_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET /events/registered
///
/// Returns the authenticated user's active registrations for events dated
/// today or later, soonest first (Feature 5 §5.5.3). Replaces the Feature 3
/// stub; response shape unchanged.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  try {
    final uid = context.read<String>();
    final cursor = context.request.url.queryParameters['cursor'];

    final page = await RegistrationListService.fetchRegistered(
      uid: uid,
      cursor: cursor,
    );

    String? nextCursor;
    if (page.nextCursor != null) {
      nextCursor = base64.encode(utf8.encode(jsonEncode(page.nextCursor)));
    }

    // Locked Feature 3 / 5.5.3 shape — no extra message field.
    return Response.json(
      body: {
        'success': true,
        'events': page.events,
        'next_cursor': nextCursor,
      },
    );
  } on EventException catch (e) {
    return ResponseHelper.errorFromException(e);
  } catch (e, stack) {
    // ignore: avoid_print
    print('${EventErrorCode.internalError} registered: $e\n$stack');
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
