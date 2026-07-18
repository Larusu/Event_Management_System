/// Base URL of the Dart Frog backend (Cloud Run).
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

/// Auth route paths currently implemented by the backend.
class ApiRoutes {
  const ApiRoutes._();

  static const String signIn = '/auth/signin';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String usersMe = '/users/me';

  /// User management (faculty/super_admin): list users with optional
  /// `?search=` (name/email substring) and `?role=` (exact role) filters.
  static String users({String? search, String? role}) {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) {
      params['search'] = Uri.encodeComponent(search);
    }
    if (role != null && role.isNotEmpty) {
      params['role'] = Uri.encodeComponent(role);
    }
    if (params.isEmpty) return '/users';
    final qs = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '/users?$qs';
  }

  /// Role promotion (faculty/super_admin): `PATCH /users/{targetUID}/role`.
  static String userRole(String targetUid) => '/users/$targetUid/role';

  /// Events feed (Feature 3).
  static const String events = '/events';

  /// Single-event detail (Feature 3): `/events/{eventId}`.
  static String eventById(String eventId) => '/events/$eventId';

  /// Featured events (Feature 3): `/events/featured?limit=N`.
  static String eventsFeatured({int limit = 3}) =>
      '/events/featured?limit=$limit';

  /// Registered events (Feature 3): `/events/registered`.
  static const String eventsRegistered = '/events/registered';

  /// Next registered event (Feature 3): `/events/next-registered`.
  static const String eventsNextRegistered = '/events/next-registered';

  /// Events list with optional query/cursor/tags.
  static String eventsList(
      {String? q, List<String>? tags, String? cursor, int? limit}) {
    final params = <String, String>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (tags != null) {
      for (final tag in tags) {
        params['tag'] = Uri.encodeComponent(tag);
      }
    }
    if (cursor != null) params['cursor'] = cursor;
    if (limit != null) params['limit'] = limit.toString();
    if (params.isEmpty) return events;
    final qs = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$events?$qs';
  }
}
