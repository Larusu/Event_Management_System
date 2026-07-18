/// Standardized backend auth error codes relevant to sign in and registration.
///
/// The full set (AUTH001, AUTH003, AUTH004, AUTH007, AUTH010, AUTH011) will be
/// added once the protected/profile endpoints are implemented on the backend.
class AuthErrorCodes {
  const AuthErrorCodes._();

  /// Invalid or expired token (HTTP 401).
  static const String invalidToken = 'AUTH001';

  /// Email already exists (HTTP 409).
  static const String emailExists = 'AUTH002';

  /// Insufficient permission for the requested action (HTTP 403).
  static const String insufficientPermission = 'AUTH003';

  /// Target user not found (HTTP 404).
  static const String userNotFound = 'AUTH004';

  /// Validation failed — missing/invalid fields (HTTP 400).
  static const String validationFailed = 'AUTH005';

  /// Invalid/unassignable role specified (HTTP 400).
  static const String invalidRole = 'AUTH007';

  /// Account is deactivated (HTTP 403).
  static const String accountDeactivated = 'AUTH006';

  /// Invalid email or password (HTTP 401).
  static const String invalidCredentials = 'AUTH008';

  /// Internal server error (HTTP 500).
  static const String internalError = 'AUTH009';

  /// The provided current_password does not match the account's password. (401)
  static const String currentPasswordIncorrect = 'AUTH010';

  /// new_password is identical to current_password; no change was made. (400)
  static const String passwordSameAsCurrent = 'AUTH011';

  /// Default user-facing messages keyed by code, used as a fallback when the
  /// backend response does not carry a `message`.
  static const Map<String, String> defaultMessages = {
    invalidToken: 'Your session has expired. Please sign in again.',
    emailExists: 'An account with this email already exists.',
    insufficientPermission:
        'You do not have permission to perform this action.',
    userNotFound: 'That user could not be found.',
    validationFailed: 'Invalid input. Please check your details.',
    invalidRole: 'That role cannot be assigned.',
    accountDeactivated: 'This account has been deactivated.',
    invalidCredentials: 'Invalid email or password.',
    internalError: 'Something went wrong. Please try again.',
    currentPasswordIncorrect: 'Current password is incorrect.',
    passwordSameAsCurrent:
        'New password must be different from current password.',
  };
}

/// Standardized backend error codes for the events feature (Feature 3).
class EventErrorCodes {
  const EventErrorCodes._();

  /// Invalid query parameters — cursor, limit, or tags malformed (HTTP 400).
  static const String invalidQuery = 'EVT001';

  /// Event not found, deleted, or not approved (HTTP 404).
  static const String notFound = 'EVT002';

  /// Default user-facing messages keyed by code, used as a fallback when the
  /// backend response does not carry a `message`.
  static const Map<String, String> defaultMessages = {
    invalidQuery: 'Invalid request. Please try again.',
    notFound: 'Event not found.',
  };
}
