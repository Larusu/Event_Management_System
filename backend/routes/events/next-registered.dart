import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/constants/event_exception.dart';
import 'package:backend/services/event_service.dart';
import 'package:backend/services/registration_list_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET /events/next-registered
///
/// Returns the single soonest upcoming event the authenticated user is
/// registered for, or `event: null` (Feature 5 §5.5.4). Replaces the Feature 3
/// stub; standardized on the singular `event` key.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  try {
    final uid = context.read<String>();
    final event = await RegistrationListService.fetchNextRegistered(uid: uid);

    // Locked Feature 3 / 5.5.4 shape — no extra message field.
    return Response.json(
      body: {
        'success': true,
        'event': event,
      },
    );
  } on EventException catch (e) {
    return ResponseHelper.errorFromException(e);
  } catch (e, stack) {
    // ignore: avoid_print
    print('${EventErrorCode.internalError} next-registered: $e\n$stack');
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
