import 'dart:convert';

import 'package:backend/constants/error_codes.dart';
import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/services/event_moderation_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET /events/rejected
///
/// Faculty review queue (reopen surface): rejected, non-deleted events,
/// oldest first. Mirrors GET /events/pending but with status == rejected and
/// the rejection metadata (rejection_reason, reviewed_at) exposed.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed.'},
    );
  }

  try {
    final userDoc = context.read<Map<String, dynamic>>();
    final role = userDoc['role'] as String?;
    EventModerationService.requireModeratorRole(role);

    final cursor = context.request.url.queryParameters['cursor'];
    final page = await EventModerationService.fetchRejected(cursor: cursor);

    String? nextCursor;
    if (page.nextCursor != null) {
      nextCursor = base64.encode(
        utf8.encode(jsonEncode(page.nextCursor)),
      );
    }

    return ResponseHelper.success(
      message: 'Rejected events retrieved successfully.',
      data: {
        'events': page.events,
        'next_cursor': nextCursor,
      },
    );
  } on AuthException catch (e) {
    return ResponseHelper.error(e);
  } catch (e, stack) {
    // ignore: avoid_print
    print('${EventErrorCode.internalError} rejected: $e\n$stack');
    return ResponseHelper.error(
      AuthException(AuthErrorCode.internalError, 'Internal server error'),
    );
  }
}
