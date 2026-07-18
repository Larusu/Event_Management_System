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

  /// is_open_to_guests locked at creation (400).
  /// Also returned when is_open_to_guests is present in PATCH body.
  static const String isOpenToGuestsLocked = 'EVT003';

  /// Forbidden — not the owner, or role below the required minimum. (403)
  static const String permissionDenied = 'EVT004';

  /// Invalid status transition (action not allowed from current status). (409)
  static const String invalidStatusTransition = 'EVT005';

  /// Validation error. (400)
  static const String validationError = 'EVT007';

  /// An unexpected server-side error occurred. (500)
  static const String internalError = 'EVT008';

  /// The authentication token is missing, expired, or invalid. (401)
  static const String invalidToken = 'AUTH001';

  /// Maps each error code to its HTTP status code.
  static const Map<String, int> statusFor = {
    invalidQueryParam: 400,
    notFound: 404,
    isOpenToGuestsLocked: 400,
    permissionDenied: 403,
    invalidStatusTransition: 409,
    validationError: 400,
    invalidToken: 401,
    internalError: 500,
  };
}
