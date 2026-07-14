/// Error codes for the events endpoints.
class EventErrorCode {
  EventErrorCode._();

  /// Invalid query parameters (cursor, limit, or tags malformed). (400)
  static const String invalidQueryParam = 'EVT001';

  /// The event does not exist, is soft-deleted, or is not approved. (404)
  ///
  /// All three cases return the same code and message so the API never
  /// reveals whether an unapproved event exists.
  static const String notFound = 'EVT002';

  /// An unexpected server-side error occurred. (500)
  static const String internalError = 'EVT008';

  /// The authentication token is missing, expired, or invalid. (401)
  static const String invalidToken = 'AUTH001';

  /// Maps each error code to its HTTP status code.
  static const Map<String, int> statusFor = {
    invalidQueryParam: 400,
    notFound: 404,
    invalidToken: 401,
    internalError: 500,
  };
}
