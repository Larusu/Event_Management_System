import '../constants/error_codes.dart';

/// Thrown when the backend returns an error envelope (`success: false`) or a
/// non-2xx status, or when the request itself fails (e.g. no network).
///
/// Carries the backend [code] (e.g. `AUTH008`) and a user-facing [message]
/// suitable for surfacing through shared error widgets.
class ApiException implements Exception {
  final String message;
  final String? code;

  const ApiException(this.message, {this.code});

  /// Builds an exception from a decoded error envelope, falling back to a known
  /// default message for the code when the backend omits `message`.
  factory ApiException.fromResponse(Map<String, dynamic> json) {
    final code = json['code'] as String?;
    final message = json['message'] as String? ??
        (code != null ? AuthErrorCodes.defaultMessages[code] : null) ??
        'Something went wrong. Please try again.';
    return ApiException(message, code: code);
  }

  /// Network/transport failure (no connection, timeout, etc.).
  factory ApiException.network() => const ApiException(
        'Unable to reach the server. Check your connection and try again.',
      );

  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}
