/// Base URL of the Dart Frog backend (Cloud Run).
///
/// During local backend development, point this to the backend dev's local
/// Dart Frog server (e.g. `http://<their-local-ip>:8080`) — `localhost` will
/// not work since the team is fully remote.
const String apiBaseUrl = 'http://127.0.0.1:8080';

/// Auth route paths currently implemented by the backend.
class ApiRoutes {
  const ApiRoutes._();

  static const String signIn = '/auth/signin';
  static const String register = '/auth/register';
}
