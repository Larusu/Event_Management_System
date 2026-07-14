import 'package:backend/constants/error_codes.dart';
import 'package:backend/services/firebase_event_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET /events/{eventId}
Future<Response> onRequest(RequestContext context, String eventId) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed.'},
    );
  }

  try {
    final event = await FirebaseEventService.getEventById(eventId);

    return Response.json(
      body: {
        'success': true,
        'events': event.toJson(),
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
