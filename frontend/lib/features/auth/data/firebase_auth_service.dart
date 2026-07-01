import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../core/network/api_exception.dart';

/// Wraps the Firebase Client SDK calls needed to turn the backend-issued custom
/// token into a real session.
///
/// Flow (sections 1.5.1 / 1.5.2): the backend returns a `custom_token`, the app
/// exchanges it via [signInWithCustomToken], and subsequent authenticated
/// requests read a fresh ID token via [currentIdToken].
class FirebaseAuthService {
  final fb.FirebaseAuth _auth;

  FirebaseAuthService([fb.FirebaseAuth? auth])
      : _auth = auth ?? fb.FirebaseAuth.instance;

  /// Establishes a Firebase session from the backend's custom token.
  Future<void> signInWithCustomToken(String customToken) async {
    try {
      await _auth.signInWithCustomToken(customToken);
    } on fb.FirebaseAuthException catch (e) {
      throw ApiException(
        e.message ?? 'Could not establish a session. Please try again.',
        code: e.code,
      );
    }
  }

  /// Returns a fresh ID token for the current session, or `null` if signed out.
  Future<String?> currentIdToken() async => _auth.currentUser?.getIdToken();

  fb.User? get currentUser => _auth.currentUser;

  Stream<fb.User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();
}
