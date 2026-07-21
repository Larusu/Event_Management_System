import 'package:backend/constants/error_codes.dart';
import 'package:backend/models/auth_request.dart';
import 'package:backend/models/user.dart';
import 'package:backend/services/firebase_auth_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:backend/utils/validators.dart';
import 'package:dart_frog/dart_frog.dart';

/// POST /auth/signin
///
/// Sign in with email and password. Password is verified server-side via
/// the Identity Toolkit REST API; role/name/contact are read fresh from
/// Firestore (never from a token or claim) on every sign-in.
///
/// Error Responses (see constants/error_codes.dart):
/// - 401 AUTH008: invalid email or password
/// - 403 AUTH006: account deactivated
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final request = SignInRequest.fromJson(body);

    final emailError = AuthValidationService.validateEmail(request.email);
    if (emailError != null) {
      throw AuthException(AuthErrorCode.validationFailed, emailError);
    }
    if (request.password.isEmpty) {
      throw AuthException(
        AuthErrorCode.validationFailed,
        'Password is required',
      );
    }

    final result = await FirebaseAuthService.signInUser(
      email: request.email,
      password: request.password,
    );

    final user = result['user'] as User;
    final token = result['token'] as String;

    return ResponseHelper.success(
      message: 'Sign in successful.',
      data: {
        'custom_token': token,
        'user': {
          'uid': user.uid,
          'email': user.email,
          'name': user.name,
          'contact': user.contact,
          'role': user.role,
        },
      },
    );
  } on AuthException catch (e) {
    return ResponseHelper.error(e);
  } catch (e) {
    // ignore: avoid_print
    print('AUTH009 catch-all error (signin): $e');
    return ResponseHelper.error(
      AuthException(AuthErrorCode.internalError, 'Internal server error'),
    );
  }
}
