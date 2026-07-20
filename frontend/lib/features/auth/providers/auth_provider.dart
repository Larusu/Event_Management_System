import 'dart:async';

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
  StreamSubscription<dynamic>? _authSubscription;

  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  AuthStatus _status = AuthStatus.unknown;
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _errorCode;

  // True while an interactive sign-in/register is in progress. During that
  // window the auth-state stream must not spawn its own _loadCurrentUser():
  // signInWithCustomToken (and the sign-out inside register) fire the stream,
  // and a stray profile load can resolve after a successful sign-in and sign
  // the user back out. _run/_runRegister own _currentUser/_status themselves.
  bool _isAuthenticating = false;

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    // Drive all auth state off the stream. On cold start it fires once with the
    // restored session (or null); on sign-in/out it fires again. No synchronous
    // hasSession check, so persisted sessions restore reliably on a real device.
    _authSubscription = _repository.firebaseAuthState.listen((_) {
      // Let the interactive sign-in/register flow manage state; ignore the
      // stream events it triggers to avoid a race that can sign the user out.
      if (_isAuthenticating) return;

      // Act on the LIVE session rather than the event payload: Firebase
      // delivers authStateChanges asynchronously, so a delayed/stale event
      // (e.g. an old sign-out) must not override the current session.
      if (!_repository.hasSession) {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
        notifyListeners();
      } else if (_currentUser == null) {
        // Session exists but profile not loaded yet (restored on launch).
        // Fresh sign-in/register already set _currentUser via _run(), so this
        // guard avoids a redundant /users/me call in that path.
        _loadCurrentUser();
      }
    });
  }

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
    return _runRegister(() => _repository.register(
          firstName: firstName,
          lastName: lastName,
          email: email,
          contact: contact,
          password: password,
        ));
  }

  /// Updates the signed-in user's profile via PATCH /users/me.
  ///
  /// Deliberately does NOT go through [_run]: a failed update (e.g. AUTH010
  /// wrong current_password) is an expected form error, not a session failure,
  /// so [_status] must stay [AuthStatus.authenticated] and the current session
  /// must be preserved. On success only name/contact are updated locally —
  /// no forced sign-out after a password change.
  Future<bool> updateProfile({
    required String currentPassword,
    required String name,
    required String contact,
    String? newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      final updated = await _repository.updateProfile(
        currentPassword: currentPassword,
        name: name,
        contact: contact,
        newPassword: newPassword,
      );
      final current = _currentUser;
      _currentUser = current == null
          ? updated
          : current.copyWith(name: updated.name, contact: updated.contact);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _errorCode = e.code;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _errorCode = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.forgotPassword(email);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears any surfaced error (e.g. when the user edits the form again).
  void clearError() {
    if (_errorMessage == null && _errorCode == null) return;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();
  }

  /// Shared runner for sign-in: toggles loading, stores the resulting
  /// user, and maps [ApiException] into [errorMessage]. Returns `true` on
  /// success so screens can react (e.g. navigate).
  Future<bool> _run(Future<User> Function() action) async {
    _isAuthenticating = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await action();
      _status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _errorCode = e.code;
      _status = AuthStatus.unauthenticated;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      _errorCode = null;
      _status = AuthStatus.unauthenticated;
      return false;
    } finally {
      _isLoading = false;
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  /// Runner for registration: registration never establishes a session (see
  /// [AuthRepository.register]), so the user stays signed out and must sign in
  /// manually (status stays [AuthStatus.unauthenticated]).
  Future<bool> _runRegister(Future<User> Function() action) async {
    _isAuthenticating = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Registration returns the created profile but does not sign in.
      await action();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
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
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await _repository.fetchCurrentUser();
      _status = AuthStatus.authenticated;
    } catch (_) {
      // Expired/broken session or network failure: don't leave the user
      // stuck on a spinner — drop to signed-out.
      await _repository.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
