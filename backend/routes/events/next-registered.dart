import 'package:dart_frog/dart_frog.dart';

/// GET /events/next-registered
///
/// Stub until the registrations relationship exists (Registration feature).
/// Locks the response shape so the Dashboard "Next Registered Event" card
/// can build against it now.
///
/// Real implementation later: return the single soonest upcoming registered
/// event with full detail, or `event: null` when none.
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
      'event': null,
    },
  );
}
