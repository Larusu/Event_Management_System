import 'package:json_annotation/json_annotation.dart';

part 'auth_request.g.dart';

/// Request model for user registration
///
/// Represents the data sent by client during signup
///
/// Fields (all snake_case in JSON):
/// - `email`: User's email address
/// - `password`: User's chosen password
/// - `firstName`: User's first name (JSON key: "first_name")
/// - `lastName`: User's last name (JSON key: "last_name")
/// - `contact`: User's contact phone number (JSON key: "contact")
///
/// Example:
/// ```dart
/// final request = RegisterRequest(
///   email: 'john@example.com',
///   password: 'SecurePass123',
///   firstName: 'John',
///   lastName: 'Doe',
///   contact: '09123456789',
/// );
/// ```
@JsonSerializable(fieldRename: FieldRename.snake)
class RegisterRequest {
  /// Creates a [RegisterRequest] with the given signup fields.
  RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.contact,
  });

  /// Creates a [RegisterRequest] from a JSON map.
  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  /// User's email address
  final String email;

  /// User's password (will be hashed by Firebase Auth)
  final String password;

  /// User's first name — JSON key: "first_name"
  final String firstName;

  /// User's last name — JSON key: "last_name"
  final String lastName;

  /// User's contact phone number — JSON key: "contact"
  final String contact;

  /// Converts this request to a JSON map with snake_case keys.
  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);

  @override
  String toString() =>
    'RegisterRequest(email: $email, firstName: $firstName,  '
    'lastName: $lastName, contact: $contact)';
}

/// Request model for user sign-in/login
///
/// Represents the credentials sent by client during login
///
/// Fields (all snake_case in JSON):
/// - `email`: User's email address
/// - `password`: User's password
///
/// Example:
/// ```dart
/// final request = SignInRequest(
///   email: 'john@example.com',
///   password: 'SecurePass123',
/// );
/// ```
@JsonSerializable(fieldRename: FieldRename.snake)
class SignInRequest {
  /// Creates a [SignInRequest] with login credentials.
  SignInRequest({
    required this.email,
    required this.password,
  });

  /// Creates a [SignInRequest] from a JSON map.
  factory SignInRequest.fromJson(Map<String, dynamic> json) =>
      _$SignInRequestFromJson(json);

  /// User's email address
  final String email;

  /// User's password
  final String password;

  /// Converts this request to a JSON map with snake_case keys.
  Map<String, dynamic> toJson() => _$SignInRequestToJson(this);

  @override
  String toString() => 'SignInRequest(email: $email)';
}

/// Request model for token refresh
///
/// Sent when client needs to refresh an expired token
///
/// Fields (all snake_case in JSON):
/// - `token`: Current/expired ID token or refresh token
///
/// Example:
/// ```dart
/// final request = RefreshTokenRequest(token: 'eyJhbGciOiJIUzI1NiIs...');
/// ```
@JsonSerializable(fieldRename: FieldRename.snake)
class RefreshTokenRequest {
  /// Creates a [RefreshTokenRequest] with the token to refresh.
  RefreshTokenRequest({
    required this.token,
  });

  /// Creates a [RefreshTokenRequest] from a JSON map.
  factory RefreshTokenRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestFromJson(json);

  /// Current or expired token to refresh
  final String token;

  /// Converts this request to a JSON map with snake_case keys.
  Map<String, dynamic> toJson() => _$RefreshTokenRequestToJson(this);

  @override
  String toString() => 'RefreshTokenRequest(hasToken: ${token.isNotEmpty})';
}

/// Request model for the forgot-password flow
///
/// Sent when an unauthenticated user requests a password reset email.
///
/// Fields (all snake_case in JSON):
/// - `email`: Email address of the account to reset
///
/// Example:
/// ```dart
/// final request = ForgotPasswordRequest(email: 'john@example.com');
/// ```
@JsonSerializable(fieldRename: FieldRename.snake)
class ForgotPasswordRequest {
  /// Creates a [ForgotPasswordRequest] with the account email.
  ForgotPasswordRequest({
    required this.email,  
  });

  /// Creates a [ForgotPasswordRequest] from a JSON map.
  factory ForgotPasswordRequest.fromJson(Map<String, dynamic> json) =>
    _$ForgotPasswordRequestFromJson(json);

    /// Email address of the account requesting a password reset
    final String email;

  /// Converts this request to a JSON map with snake_case keys.
    Map<String, dynamic> toJson() => _$ForgotPasswordRequestToJson(this); 

    @override 
    String toString() => 'ForgotPasswordRequest(email: $email)';
}

/// Request model for updating user profile
///
/// Sent when an authenticated user updates their name, contact, or password.
///
/// Fields (all snake_case in JSON):
/// - `current_password`: Required to authorize any changes.
/// - `name`: Optional new name.
/// - `contact`: Optional new contact number.
/// - `new_password`: Optional new password.
@JsonSerializable(fieldRename: FieldRename.snake)
class UpdateProfileRequest {
  /// Creates an [UpdateProfileRequest].
  UpdateProfileRequest({
    required this.currentPassword,
    this.name,
    this.contact,
    this.newPassword,
  });

  /// Creates an [UpdateProfileRequest] from a JSON map.
  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileRequestFromJson(json);

  /// Current password to authorize the change
  final String currentPassword;

  /// Optional updated name
  final String? name;

  /// Optional updated contact
  final String? contact;

  /// Optional new password
  final String? newPassword;

  /// Converts this request to a JSON map with snake_case keys.
  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);

  @override
  String toString() => 'UpdateProfileRequest(hasName: ${name != null}, hasContact: ${contact != null}, hasNewPassword: ${newPassword != null})';
}
