import 'package:backend/constants/error_codes.dart';
import 'package:backend/constants/event_error_codes.dart';

import 'package:dart_frog/dart_frog.dart';

abstract class AppException implements Exception {
  AppException(this.code, this.message);

  final String code;
  final String message;

  int get statusCode {
    final status = AuthErrorCode.statusFor[code] ??
        EventErrorCode.statusFor[code];
    return status ?? 500;
  }

  Map<String, dynamic> toResponseMap() => {
        'success': false,
        'code': code,
        'message': message,
      };
}

class AuthException implements Exception {
  AuthException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AuthException(code: $code, message: $message)';
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
      },
    );
  }

  static Response errorFromException(AppException exception) {
    return Response.json(
      statusCode: exception.statusCode,
      body: exception.toResponseMap(),
    );
  }
}
