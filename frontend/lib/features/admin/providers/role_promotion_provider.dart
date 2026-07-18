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

  /// Locked role transition graph (mirrors the backend). Keyed by the target's
  /// current role -> the assignable new role -> the requester roles allowed to
  /// perform it. Promotion and demotion share this one table.
  ///
  ///   student   -> organizer            (faculty, super_admin)
  ///   organizer -> faculty              (super_admin only)
  ///   organizer -> student  (demote)    (faculty, super_admin)
  ///   guest / faculty / super_admin     -> terminal (no transitions)
  static const Map<String, Map<String, Set<String>>> _transitions = {
    Roles.student: {
      Roles.organizer: {Roles.faculty, Roles.superAdmin},
    },
    Roles.organizer: {
      Roles.faculty: {Roles.superAdmin},
      Roles.student: {Roles.faculty, Roles.superAdmin},
    },
  };

  /// The new roles a [requesterRole] may assign to a user currently holding
  /// [currentRole]. Promotions are listed before demotions.
  static List<String> availableRoleChanges({
    required String requesterRole,
    required String currentRole,
  }) {
    final fromCurrent = _transitions[currentRole];
    if (fromCurrent == null) return const [];
    final result = <String>[];
    fromCurrent.forEach((newRole, actors) {
      if (actors.contains(requesterRole)) result.add(newRole);
    });
    return result;
  }

  bool _isCandidate(String role) => availableRoleChanges(
        requesterRole: requesterRole,
        currentRole: role,
      ).isNotEmpty;

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

  /// Changes a user's role (promote or demote) and updates the local list on
  /// success. Returns `null` on success, or a user-facing error message.
  Future<String?> changeRole({
    required String targetUid,
    required String newRole,
  }) async {
    try {
      await _repository.changeUserRole(targetUid: targetUid, newRole: newRole);
      // Reflect the change locally, dropping anyone who no longer has any
      // available action for this requester (e.g. an organizer promoted to
      // faculty, which is terminal).
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
