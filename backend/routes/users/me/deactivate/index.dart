import 'package:dart_frog/dart_frog.dart';

/// POST /users/me/deactivate
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
