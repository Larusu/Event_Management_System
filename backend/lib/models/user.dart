import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// API-facing user representation.
///
/// This model matches the API response shape exactly - it is
/// NOT a 1:1 mirror of the Firestore document. Firestore additionally
/// tracks is_deleted, last_login_at, and updated_at, none of which are
/// ever returned in an API response, so they don't belong here.
///
/// All JSON keys are snake_case (fieldRename: FieldRename.snake):
///   uid, email, name, contact, role, created_at
///
/// Fields:
/// - `uid`: Firebase UID
/// - `email`: user's email address
/// - `name`: full name, "firstName lastName" combined into one string
/// - `contact`: 11-digit 09-format contact number
/// - `role`: student | guest | organizer | faculty | super_admin
/// - `createdAt`: ISO 8601 string, set once at registration.
///   Null on sign-in responses — only present right after registration.
@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  /// Creates a [User]. [createdAt] is only set on registration responses.
  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.contact,
    required this.role,
    this.createdAt,
  });

  /// Creates a [User] from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Firebase UID.
  final String uid;

  /// User's email address.
  final String email;

  /// Full name, "firstName lastName" combined into one string.
  final String name;

  /// 11-digit, 09-format contact number.
  final String contact;

  /// Role: student | guest | organizer | faculty | super_admin.
  final String role;

  /// ISO 8601 timestamp — only included in registration responses.
  /// Serialized as "created_at" to match the snake_case API contract.
  final String? createdAt;

  /// Converts this [User] to a JSON map with snake_case keys.
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  String toString() =>
      'User(uid: $uid, email: $email, name: $name, role: $role)';
}
