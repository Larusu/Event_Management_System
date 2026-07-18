import 'package:flutter/foundation.dart';

import '../../../core/constants/roles.dart';
import '../../../core/network/api_exception.dart';
import '../data/user_management_repository.dart';
import '../models/managed_user.dart';

enum RolePromotionStatus { idle, loading, loaded, error }

/// Screen-scoped state for the role promotion surface. Loads the promotable
/// user list (filtered by the requester's role) and performs promotions via
/// `PATCH /users/{targetUID}/role`.
class RolePromotionProvider extends ChangeNotifier {
  final UserManagementRepository _repository;

  /// The signed-in user's role. Drives which candidates are shown and which
  /// target roles may be assigned.
  final String requesterRole;

  RolePromotionProvider({
    required this.requesterRole,
    UserManagementRepository? repository,
  }) : _repository = repository ?? createUserManagementRepository();

  RolePromotionStatus _status = RolePromotionStatus.idle;
  List<ManagedUser> _users = [];
  String? _errorMessage;
  bool _isDisposed = false;

  RolePromotionStatus get status => _status;
  List<ManagedUser> get users => _users;
  String? get errorMessage => _errorMessage;

  /// Roles a [requesterRole] can assign to a user currently holding
  /// [targetRole]. Faculty can only create organizers; super_admin can create
  /// organizers or faculty (and can only promote an existing organizer up to
  /// faculty).
  static List<String> assignableRoles({
    required String requesterRole,
    required String targetRole,
  }) {
    if (requesterRole == Roles.faculty) {
      return targetRole == Roles.organizer ? const [] : const [Roles.organizer];
    }
    if (requesterRole == Roles.superAdmin) {
      if (targetRole == Roles.organizer) return const [Roles.faculty];
      return const [Roles.organizer, Roles.faculty];
    }
    return const [];
  }

  bool _isCandidate(String role) {
    if (requesterRole == Roles.faculty) {
      return role == Roles.student;
    }
    if (requesterRole == Roles.superAdmin) {
      return role == Roles.student ||
          role == Roles.guest ||
          role == Roles.organizer;
    }
    return false;
  }

  Future<void> load({String? search}) async {
    _status = RolePromotionStatus.loading;
    _errorMessage = null;
    _safeNotify();

    try {
      final result = await _repository.listUsers(search: search);
      _users = result.where((u) => _isCandidate(u.role)).toList();
      _status = RolePromotionStatus.loaded;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = RolePromotionStatus.error;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _status = RolePromotionStatus.error;
    }
    _safeNotify();
  }

  /// Promotes a user and updates the local list on success. Returns `null` on
  /// success, or a user-facing error message on failure.
  Future<String?> promote({
    required String targetUid,
    required String newRole,
  }) async {
    try {
      await _repository.promoteUser(targetUid: targetUid, newRole: newRole);
      // Reflect the change locally, dropping anyone who is no longer a
      // candidate for this requester (e.g. a student promoted to organizer by
      // a faculty member).
      _users = _users
          .map((u) => u.uid == targetUid ? u.copyWith(role: newRole) : u)
          .where((u) => _isCandidate(u.role))
          .toList();
      _safeNotify();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
