import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../../core/constants/api_constants.dart';
import '../../../core/models/api_response.dart';
import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'firebase_auth_service.dart';

/// The single point that talks to the backend auth endpoints, per the
/// architecture convention (API calls only live in `data/`).
///
/// Currently implements Sign In (1.5.1) and Registration (1.5.2). After a
/// successful response it exchanges the returned `custom_token` for a real
/// Firebase session so the user is immediately authenticated.
class AuthRepository {
  final ApiClient _api;
  final FirebaseAuthService _firebase;

  AuthRepository({
    ApiClient? api,
    FirebaseAuthService? firebase,
  })  : _api = api ?? ApiClient(),
        _firebase = firebase ?? FirebaseAuthService();

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(ApiRoutes.signIn, {
      'email': email,
      'password': password,
    });
    return _establishSession(response);
  }

  Future<User> register({
    required String firstName,
    required String lastName,
    required String email,
    required String contact,
    required String password,
  }) async {
    final response = await _api.post(ApiRoutes.register, {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'contact': contact,
      'password': password,
    });
    return _establishSession(response);
  }

  bool get hasSession => _firebase.currentUser != null;

  Stream<fb.User?> get firebaseAuthState => _firebase.authStateChanges();

  Future<void> signOut() => _firebase.signOut();

  /// Exchanges the `custom_token` for a Firebase session and parses the user.
  Future<User> _establishSession(ApiResponse response) async {
    final customToken = response.data['custom_token'] as String?;
    if (customToken == null) {
      throw const ApiException(
        'Something went wrong. Please try again.',
      );
    }
    await _firebase.signInWithCustomToken(customToken);

    final userJson = response.data['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const ApiException(
        'Something went wrong. Please try again.',
      );
    }
    return User.fromJson(userJson);
  }
}
