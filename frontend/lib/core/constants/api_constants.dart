/// Base URL of the Dart Frog backend (Cloud Run).
const String apiBaseUrl = String.fromEnvironment( 
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8080',
);

/// When true, event features use mock repositories instead of hitting the
/// backend. Flip to false once the Feature 3 backend endpoints are deployed.
///
// TODO(backend): set to `false` once Backend Dev B deploys
// GET /events/{eventId}. This single flag switches the whole events feature
// from mock data to the real API — no other UI changes required.
const bool useMockEvents = true;

/// Auth route paths currently implemented by the backend.
class ApiRoutes {
  const ApiRoutes._();

  static const String signIn = '/auth/signin';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String usersMe = '/users/me';

  /// Events feed (Feature 3).
  static const String events = '/events';

  /// Single-event detail (Feature 3): `/events/{eventId}`.
  static String eventById(String eventId) => '/events/$eventId';
}
