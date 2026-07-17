import 'dart:convert';

import 'package:backend/constants/error_codes.dart';
import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/services/event_moderation_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

/// PATCH /events/{eventId}/status
///
/// Approve, reject, or reopen an event (faculty / super_admin only).
Future<Response> onRequest(RequestContext context, String eventId) async {
  if (context.request.method != HttpMethod.patch) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed.'},
    );
  }

  try {
    final uid = context.read<String>();
    final userDoc = context.read<Map<String, dynamic>>();
    final role = userDoc['role'] as String?;
    EventModerationService.requireModeratorRole(role);

    final bodyString = await context.request.body();
    final body = jsonDecode(bodyString) as Map<String, dynamic>;

    final action = body['action'] as String?;
    if (action == null || action.trim().isEmpty) {
      return ResponseHelper.error(
        AuthException(
          EventErrorCode.invalidQueryParam,
          'action is required.',
        ),
      );
    }

    final reason = body['reason'] as String?;

    final event = await EventModerationService.changeStatus(
      eventId: eventId,
      reviewerUid: uid,
      action: action.trim(),
      reason: reason,
    );

    return ResponseHelper.success(
      message: 'Event status updated.',
      data: {'event': event},
    );
  } on AuthException catch (e) {
    return ResponseHelper.error(e);
  } on FormatException {
    return ResponseHelper.error(
      AuthException(
        EventErrorCode.invalidQueryParam,
        'Invalid JSON body.',
      ),
    );
  } catch (e, stack) {
    // ignore: avoid_print
    print('${EventErrorCode.internalError} status: $e\n$stack');
    return ResponseHelper.error(
      AuthException(AuthErrorCode.internalError, 'Internal server error'),
    );
  }
}
