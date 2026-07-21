/// Base URL of the Dart Frog backend (Cloud Run).
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

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

  /// Events feed. Also used for `POST /events` create
  static const String events = '/events';

  /// Cover-image upload: `POST /events/cover-image`
  /// (multipart/form-data, single file field `image`).
  static const String eventsCoverImage = '/events/cover-image';

  /// Pending events review queue:
  /// `GET /events/pending?cursor=`.
  static String eventsPending({String? cursor}) {
    if (cursor == null || cursor.isEmpty) return '/events/pending';
    return '/events/pending?cursor=${Uri.encodeComponent(cursor)}';
  }

  /// Rejected events / reopen queue (faculty/super_admin):
  /// `GET /events/rejected?cursor=`.
  static String eventsRejected({String? cursor}) {
    if (cursor == null || cursor.isEmpty) return '/events/rejected';
    return '/events/rejected?cursor=${Uri.encodeComponent(cursor)}';
  }

  /// Event moderation: `PATCH /events/{eventId}/status`.
  static String eventStatus(String eventId) => '/events/$eventId/status';

  /// Single-event detail: `/events/{eventId}`.
  static String eventById(String eventId) => '/events/$eventId';

  /// Featured events: `/events/featured?limit=N`.
  static String eventsFeatured({int limit = 3}) =>
      '/events/featured?limit=$limit';

  /// Registered events: `/events/registered`.
  static const String eventsRegistered = '/events/registered';

  /// Events created by the signed-in user, including pending/rejected events.
  static const String eventsCreated = '/events/created';

  /// Next registered event: `/events/next-registered`.
  static const String eventsNextRegistered = '/events/next-registered';

  /// All unique tags: `/events/tags`.
  static const String eventsTags = '/events/tags';

  /// Register for an event: `/events/{eventId}/register`.
  static String eventRegister(String eventId) => '/events/$eventId/register';

  /// Events list with optional query/cursor/tags.
  static String eventsList(
      {String? q, List<String>? tags, String? cursor, int? limit}) {
    final params = <String, String>{};
    if (q != null && q.isNotEmpty) params['search'] = q;
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
