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
  /// types, or business-rule violations (e.g. is_open_to_guests locked,
  /// bad cover-image type/size). (400)
  static const String validationFailed = 'EVT003';

  /// Permission denied for resource. (403)
  static const String permissionDenied = 'EVT004';

  /// Cloudinary upload rejected the image or returned an error. (500)
  static const String cloudinaryError = 'EVT006';

  /// Event date must be today or in the future. (400)
  static const String dateInPast = 'EVT007';

  /// An unexpected server-side error occurred. (500)
  static const String internalError = 'EVT008';

  /// The authentication token is missing, expired, or invalid. (401)
  static const String invalidToken = 'AUTH001';

  /// Maps each error code to its HTTP status code.
  static const Map<String, int> statusFor = {
    invalidQueryParam: 400,
    notFound: 404,
    validationFailed: 400,
    permissionDenied: 403,
    cloudinaryError: 500,
    dateInPast: 400,
    invalidToken: 401,
    internalError: 500,
  };
}
