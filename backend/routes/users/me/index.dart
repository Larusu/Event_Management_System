import 'package:dart_frog/dart_frog.dart';

/// GET /users/me
///
/// Placeholder : Session & Role Enforcement
Future<Response> onRequest(RequestContext context) async {
  return Response.json(
    statusCode: 501,
    body: {
      'success': false,
      'message': 'Not implemented yet. See Dev B: Session & Role Enforcement.',
    },
  );
}
