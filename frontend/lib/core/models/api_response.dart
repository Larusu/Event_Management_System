/// Parsed view of the backend's standardized response envelope:
/// `{ success, message, code, ... }`.
///
/// The original decoded JSON is kept in [data] so callers (repositories) can
/// read endpoint-specific fields such as `custom_token` or `user`.
class ApiResponse {
  final bool success;
  final String? message;
  final String? code;
  final Map<String, dynamic> data;

  const ApiResponse({
    required this.success,
    required this.data,
    this.message,
    this.code,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) => ApiResponse(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String?,
        code: json['code'] as String?,
        data: json,
      );
}
