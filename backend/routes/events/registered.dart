import 'package:dart_frog/dart_frog.dart';

/// GET /events/registered
///
/// Stub until the registrations relationship exists (Registration feature).
/// Locks the response shape so the Dashboard can build against it now.
///
/// Real implementation later: return events the authenticated user has
/// registered for with date today or later, paginated via `cursor`.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  // Honest empty result — frontend shows empty/encouraging UI.
  // Auth (AUTH001 / AUTH006) is enforced by routes/events/_middleware.dart.
  return Response.json(
    body: {
      'success': true,
      'events': <dynamic>[],
      'next_cursor': null,
    },
  );
}
