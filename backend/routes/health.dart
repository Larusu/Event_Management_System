import 'package:dart_frog/dart_frog.dart';

/// GET /health
/// 
/// Health check endpoint for API
/// 
/// Response (200 OK):
/// ```json
/// {
///   "status": "healthy",
///   "timestamp": "2026-06-24T10:30:00Z",
///   "version": "1.0.0",
///   "endpoints": {
///     "auth": [
///       "POST /auth/register",
///       "POST /auth/signin"
///     ]
///   }
/// }
/// ```
Response onRequest(RequestContext context) {
  return Response(
    body: '''
{
  "status": "healthy",
  "timestamp": "${DateTime.now().toUtc().toIso8601String()}",
  "version": "1.0.0",
  "endpoints": {
    "auth": [
      "POST /auth/register - Register new user",
      "POST /auth/signin - Sign in user"
    ]
  }
}''',
  );
}
