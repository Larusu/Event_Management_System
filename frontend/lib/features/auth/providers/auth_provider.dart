import 'package:flutter/foundation.dart';

import '../../../core/models/user.dart';
import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// App-wide authentication state. UI reads [status]/[currentUser] and calls
/// [signIn]/[register]/[signOut]; all backend work is delegated to
/// [AuthRepository].
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  AuthStatus _status = AuthStatus.unknown;
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> signIn({
    required String email,
    required String password,
  }) {
    return _run(() => _repository.signIn(email: email, password: password));
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String contact,
    required String password,
  }) {
    return _run(() => _repository.register(
          firstName: firstName,
          lastName: lastName,
          email: email,
          contact: contact,
          password: password,
        ));
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clears any surfaced error (e.g. when the user edits the form again).
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Shared runner for sign-in/register: toggles loading, stores the resulting
  /// user, and maps [ApiException] into [errorMessage]. Returns `true` on
  /// success so screens can react (e.g. navigate).
  Future<bool> _run(Future<User> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await action();
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _status = AuthStatus.unauthenticated;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
