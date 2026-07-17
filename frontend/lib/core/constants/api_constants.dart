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

  /// All unique tags (Feature 3): `/events/tags`.
  static const String eventsTags = '/events/tags';

  /// Register for an event: `/events/{eventId}/register`.
  static String eventRegister(String eventId) => '/events/$eventId/register';

  /// Events list with optional query/cursor/tags.
  static String eventsList(
      {String? q, List<String>? tags, String? cursor, int? limit}) {
    final params = <String, String>{};
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (tags != null && tags.isNotEmpty) {
      params['tags'] = Uri.encodeComponent(tags.join(','));
    }
    if (cursor != null) params['cursor'] = cursor;
    if (limit != null) params['limit'] = limit.toString();
    if (params.isEmpty) return events;
    final qs = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$events?$qs';
  }
}
