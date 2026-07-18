/// A user row returned by `GET /users` for the faculty/super_admin
/// user-management screen. Mirrors the backend list shape exactly:
/// `{ uid, name, email, contact, role }`.
class ManagedUser {
  final String uid;
  final String name;
  final String email;
  final String contact;
  final String role;

  const ManagedUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.contact,
    required this.role,
  });

  factory ManagedUser.fromJson(Map<String, dynamic> json) => ManagedUser(
        uid: json['uid'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        contact: json['contact'] as String? ?? '',
        role: json['role'] as String? ?? '',
      );

  ManagedUser copyWith({String? role}) => ManagedUser(
        uid: uid,
        name: name,
        email: email,
        contact: contact,
        role: role ?? this.role,
      );
}
