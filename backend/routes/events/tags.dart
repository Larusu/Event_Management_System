import 'package:backend/services/event_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET /events/tags
///
/// Returns all unique tags from approved events, sorted alphabetically.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  try {
    final tags = await EventService.fetchTags();

    return ResponseHelper.success(
      message: 'Tags retrieved successfully.',
      data: {'tags': tags},
    );
  } catch (e, stack) {
    // ignore: avoid_print
    print('Internal error fetching tags: $e\n$stack');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'message': 'Internal server error',
      },
    );
  }
}
