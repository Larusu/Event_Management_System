/// Standardized backend auth error codes relevant to sign in and registration.
///
/// The full set (AUTH001, AUTH003, AUTH004, AUTH007, AUTH010, AUTH011) will be
/// added once the protected/profile endpoints are implemented on the backend.
class AuthErrorCodes {
  const AuthErrorCodes._();

  /// Email already exists (HTTP 409).
  static const String emailExists = 'AUTH002';

  /// Validation failed — missing/invalid fields (HTTP 400).
  static const String validationFailed = 'AUTH005';

  /// Account is deactivated (HTTP 403).
  static const String accountDeactivated = 'AUTH006';

  /// Invalid email or password (HTTP 401).
  static const String invalidCredentials = 'AUTH008';

  /// Internal server error (HTTP 500).
  static const String internalError = 'AUTH009';

  /// Default user-facing messages keyed by code, used as a fallback when the
  /// backend response does not carry a `message`.
  static const Map<String, String> defaultMessages = {
    emailExists: 'An account with this email already exists.',
    validationFailed: 'Invalid input. Please check your details.',
    accountDeactivated: 'This account has been deactivated.',
    invalidCredentials: 'Invalid email or password.',
    internalError: 'Something went wrong. Please try again.',
  };
}
