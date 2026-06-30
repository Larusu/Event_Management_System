/// Role string constants matching the backend Firestore `role` enum.
///
/// Promotion/permission helpers are intentionally deferred until the role
/// management endpoint is implemented on the backend.
class Roles {
  const Roles._();

  static const String guest = 'guest';
  static const String student = 'student';
  static const String organizer = 'organizer';
  static const String faculty = 'faculty';
  static const String superAdmin = 'super_admin';

  static const List<String> all = [
    guest,
    student,
    organizer,
    faculty,
    superAdmin,
  ];
}
