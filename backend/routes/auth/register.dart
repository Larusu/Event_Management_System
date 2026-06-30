import 'package:backend/constants/error_codes.dart';
import 'package:backend/models/auth_request.dart';
import 'package:backend/models/user.dart';
import 'package:backend/services/firebase_auth_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:backend/utils/validators.dart';
import 'package:dart_frog/dart_frog.dart';

/// POST /auth/register
///
/// Register a new user account. Role is auto-detected from email domain
/// (@ciit.edu.ph -> student, else -> guest) - never accepted from the
/// client.
///
/// Error Responses (see constants/error_codes.dart):
/// - 400 AUTH005: validation failed
/// - 409 AUTH002: email already exists
/// - 500 AUTH009: internal/Firestore error (Auth user is cleaned up)
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final request = RegisterRequest.fromJson(body);

    _validateRegisterRequest(request);

    final result = await FirebaseAuthService.registerUser(
      firstName: request.firstName,
      lastName: request.lastName,
      email: request.email,
      contactNumber: request.contact,
      password: request.password,
    );

    final user = result['user'] as User;
    final token = result['token'] as String;

    return ResponseHelper.success(
      statusCode: 201,
      message: 'Account created successfully.',
      data: {
        'custom_token': token,
        'user': user.toJson(),
      },
    );
  } on AuthException catch (e) {
    return ResponseHelper.error(e);
  } catch (e) {
    // ignore: avoid_print
    print('AUTH009 catch-all error: $e');
    return ResponseHelper.error(
      AuthException(AuthErrorCode.internalError, 'Internal server error'),
    );
  }
}

/// Runs all field validations for registration. Throws the first
/// AuthException it hits, so the caller never has to branch on multiple
/// return values - one throw, one catch, same as every other failure path.
void _validateRegisterRequest(RegisterRequest request) {
  final emailError = AuthValidationService.validateEmail(request.email);
  if (emailError != null) {
    throw AuthException(AuthErrorCode.validationFailed, emailError);
  }

  final passwordError =
      AuthValidationService.validatePassword(request.password);
  if (passwordError != null) {
    throw AuthException(AuthErrorCode.validationFailed, passwordError);
  }

  final firstNameError =
      AuthValidationService.validateName(request.firstName, 'First name');
  if (firstNameError != null) {
    throw AuthException(AuthErrorCode.validationFailed, firstNameError);
  }

  final lastNameError =
      AuthValidationService.validateName(request.lastName, 'Last name');
  if (lastNameError != null) {
    throw AuthException(AuthErrorCode.validationFailed, lastNameError);
  }

  final contactError =
      AuthValidationService.validateContactNumber(request.contact);
  if (contactError != null) {
    throw AuthException(AuthErrorCode.validationFailed, contactError);
  }
}
