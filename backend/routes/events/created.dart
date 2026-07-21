import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/services/firebase_event_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET /events/created — all non-deleted events owned by the caller.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed.'},
    );
  }

  try {
    final events = await FirebaseEventService.getCreatedEvents(
      context.read<String>(),
    );
    return Response.json(body: {'success': true, 'events': events});
  } catch (error, stack) {
    // ignore: avoid_print
    print('${EventErrorCode.internalError} created events: $error\n$stack');
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
