/// Authenticated user profile as returned by the backend auth endpoints.
///
/// Mirrors the Firestore `users/` document shape (section 1.4). `createdAt` and
/// `lastLoginAt` are only present on some responses (e.g. registration), so
/// they are optional here.
class User {
  final String uid;
  final String email;
  final String name;
  final String contact;
  final String role;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.uid,
    required this.email,
    required this.name,
    required this.contact,
    required this.role,
    this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json['uid'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        contact: json['contact'] as String? ?? '',
        role: json['role'] as String,
        createdAt: _parseDate(json['createdAt']),
        lastLoginAt: _parseDate(json['lastLoginAt']),
      );

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
