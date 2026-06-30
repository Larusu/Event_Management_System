import 'package:dart_frog/dart_frog.dart';

/// Route handler for /auth endpoint
/// 
/// This catches requests to /auth without a specific sub-route
/// and returns a list of available auth endpoints.
Response onRequest(RequestContext context) {
  return Response(
    body: '/auth/ is healthy.\n\nEndpoints: "/auth/register", "/auth/signin"',
  );
}
