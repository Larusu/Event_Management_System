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

  /// Validation failed — invalid input, missing required fields, wrong
  /// types, or business-rule violations (e.g. bad cover-image type/size).
  /// (400)
  static const String validationFailed = 'EVT003';

  /// is_open_to_guests locked at creation. Also returned when
  /// is_open_to_guests is present in a PATCH body. Shares EVT003 with
  /// [validationFailed] since both are validation failures. (400)
  static const String isOpenToGuestsLocked = 'EVT003';

  /// Forbidden — not the owner, or role below the required minimum. (403)
  static const String permissionDenied = 'EVT004';

  /// Invalid status transition (action not allowed from current status). (409)
  static const String invalidStatusTransition = 'EVT005';

  /// Cloudinary upload rejected the image or returned an error. (500)
  static const String cloudinaryError = 'EVT006';

  /// Event date must be today or in the future. (400)
  static const String dateInPast = 'EVT007';

  /// General validation error used by edit/moderation routes. Shares EVT007
  /// with [dateInPast]. (400)
  static const String validationError = 'EVT007';

  /// An unexpected server-side error occurred. (500)
  static const String internalError = 'EVT008';

  /// The authentication token is missing, expired, or invalid. (401)
  static const String invalidToken = 'AUTH001';

  /// Maps each error code to its HTTP status code.
  ///
  /// Keyed by the string code value, so aliases that share a code
  /// (e.g. [validationFailed]/[isOpenToGuestsLocked] on EVT003, and
  /// [dateInPast]/[validationError] on EVT007) resolve to the same status.
  static const Map<String, int> statusFor = {
    invalidQueryParam: 400,
    notFound: 404,
    validationFailed: 400,
    permissionDenied: 403,
    invalidStatusTransition: 409,
    cloudinaryError: 500,
    dateInPast: 400,
    invalidToken: 401,
    internalError: 500,
  };
}
