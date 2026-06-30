/// Defines all authentication error codes returned by the backend.
class AuthErrorCode {
  AuthErrorCode._(); // prevent instantiation - this is a constants holder

  /// The Firebase ID token is missing, expired, or invalid. (401)
  static const String invalidToken = 'AUTH001';

  /// Registration failed because the email is already registered. (409)
  static const String emailAlreadyExists = 'AUTH002';

  /// The requester's role does not have permission for this action. (403)
  static const String insufficientPermission = 'AUTH003';

  /// No Firestore document exists for the uid. (404)
  static const String userNotFound = 'AUTH004';

  /// One or more request fields are missing or invalid. (400)
  static const String validationFailed = 'AUTH005';

  /// The account's `is_deleted` flag is true; access is blocked. (403)
  static const String accountDeactivated = 'AUTH006';

  /// The `role` value in the request body is not a valid role. (400)
  static const String invalidRole = 'AUTH007';

  /// Email/password credentials did not match any Firebase Auth account. (401)
  static const String invalidCredentials = 'AUTH008';

  /// An unexpected server-side error occurred. (500)
  static const String internalError = 'AUTH009';

  /// The provided `current_password` does not match the account's
  /// password. (401)
  static const String currentPasswordIncorrect = 'AUTH010';

  /// `new_password` is identical to `current_password`; no change was
  /// made. (400)
  static const String passwordSameAsCurrent = 'AUTH011';

  /// Maps each error code to its HTTP status code.
  ///
  /// Used by `ResponseHelper` so individual route handlers never have to
  /// manually pick a status code — just pass the error code and let this
  /// map resolve it.
  static const Map<String, int> statusFor = {
    invalidToken: 401,
    emailAlreadyExists: 409,
    insufficientPermission: 403,
    userNotFound: 404,
    validationFailed: 400,
    accountDeactivated: 403,
    invalidRole: 400,
    invalidCredentials: 401,
    internalError: 500,
    currentPasswordIncorrect: 401,
    passwordSameAsCurrent: 400,
  };
}
