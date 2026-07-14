/// Error codes for the events endpoint.
class EventErrorCode {
  EventErrorCode._();

  /// Invalid query parameters (cursor, limit, or tags malformed). (400)
  static const String invalidQueryParam = 'EVT001';

  /// An unexpected server-side error occurred. (500)
  static const String internalError = 'EVT002';

  /// The authentication token is missing, expired, or invalid. (401)
  static const String invalidToken = 'AUTH001';

  /// Maps each error code to its HTTP status code.
  static const Map<String, int> statusFor = {
    invalidQueryParam: 400,
    invalidToken: 401,
    internalError: 500,
  };
}
