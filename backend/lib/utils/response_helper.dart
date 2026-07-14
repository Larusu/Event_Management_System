import 'package:backend/constants/error_codes.dart';
import 'package:backend/constants/event_error_codes.dart';

import 'package:dart_frog/dart_frog.dart';

/// Base class for exceptions that carry an error [code] and [message] and can
/// be rendered into a standard JSON error response.
abstract class AppException implements Exception {
  /// Creates an [AppException] with the given error [code] and [message].
  AppException(this.code, this.message);

  /// The machine-readable error code (e.g. `EVT001`).
  final String code;

  /// The human-readable error message.
  final String message;

  /// HTTP status looked up from the error code table (500 if unknown).
  int get statusCode {
    final status = AuthErrorCode.statusFor[code] ??
        EventErrorCode.statusFor[code];
    return status ?? 500;
  }

  /// Builds the standard error body for this exception.
  Map<String, dynamic> toResponseMap() => {
        'success': false,
        'code': code,
        'message': message,
      };
}

/// Exception raised by auth routes, optionally tied to a specific [field].
class AuthException implements Exception {
  /// Creates an [AuthException] with the given error [code] and [message].
  AuthException(this.code, this.message, {this.field});

  /// The machine-readable error code (e.g. `AUTH001`).
  final String code;

  /// The human-readable error message.
  final String message;

  /// The specific field that caused the error, if applicable.
  final String? field; // ADDED: field property

  @override
  String toString() =>
      'AuthException(code: $code, message: $message, field: $field)';
}

/// Builds consistent JSON Responses for every auth route.
///
/// Using this instead of hand-built string templates fixes two problems
/// at once:
/// 1. jsonEncode() correctly escapes quotes/newlines in messages, so a
///    Firebase error message containing a stray quote can never produce
///    broken JSON the frontend fails to parse.
/// 2. The HTTP status code is always looked up from the error code table,
///    so no route can accidentally return the wrong status for a given
///    error code.
class ResponseHelper {
  ResponseHelper._();

  /// Build a success response.
  ///
  /// [data] is merged into the top-level JSON body alongside
  /// "success" and "message" - e.g. pass {'user': user.toJson()}.
  static Response success({
    required String message,
    int statusCode = 200,
    Map<String, dynamic>? data,
  }) {
    return Response.json(
      statusCode: statusCode,
      body: {
        'success': true,
        'message': message,
        if (data != null) ...data,
      },
    );
  }

  /// Build an error response from an [AuthException].
  ///
  /// The HTTP status is looked up automatically from the error code -
  /// callers never pass a status code for errors, so it's impossible
  /// for the status and code to disagree.
  static Response error(AuthException exception) {
    final statusCode = AuthErrorCode.statusFor[exception.code] ?? 500;
    return Response.json(
      statusCode: statusCode,
      body: {
        'success': false,
        'code': exception.code,
        'message': exception.message,
        if (exception.field != null)
          'field': exception.field, // ADDED: Output field if present
      },
    );
  }

  /// Build an error response from any [AppException] (status from its code).
  static Response errorFromException(AppException exception) {
    return Response.json(
      statusCode: exception.statusCode,
      body: exception.toResponseMap(),
    );
  }
}
