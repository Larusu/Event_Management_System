import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/managed_user.dart';

/// Data access for the faculty/super_admin user-management surface. Screens
/// depend on this interface so it can be backed by a fake in tests.
abstract class UserManagementRepository {
  /// Lists active users, optionally filtered by a name/email [search] and an
  /// exact [role]. Backing endpoint enforces faculty/super_admin access.
  Future<List<ManagedUser>> listUsers({String? search, String? role});

  /// Changes [targetUid]'s role to [newRole] (promotion or demotion; the
  /// backend enforces which transitions are valid).
  Future<void> changeUserRole({
    required String targetUid,
    required String newRole,
  });
}

/// Talks to the real Dart Frog backend.
class UserManagementApiRepository implements UserManagementRepository {
  final ApiClient _api;

  UserManagementApiRepository([ApiClient? api]) : _api = api ?? ApiClient();

  @override
  Future<List<ManagedUser>> listUsers({String? search, String? role}) async {
    final response =
        await _api.get(ApiRoutes.users(search: search, role: role));
    final json = response.data['users'];
    if (json is! List) {
      return const [];
    }
    return json
        .map((e) => ManagedUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> changeUserRole({
    required String targetUid,
    required String newRole,
  }) async {
    await _api.patch(ApiRoutes.userRole(targetUid), {'new_role': newRole});
  }
}

/// User-management data now comes from the live backend.
UserManagementRepository createUserManagementRepository() =>
    UserManagementApiRepository();
