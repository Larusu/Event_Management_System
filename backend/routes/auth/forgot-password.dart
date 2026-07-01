import 'package:backend/constants/error_codes.dart';
import 'package:backend/models/auth_request.dart';
import 'package:backend/services/firebase_auth_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:backend/utils/validators.dart';
import 'package:dart_frog/dart_frog.dart';

/// POST /auth/forgot-password 
///
/// Public, unauthenticated endpoint that initiates the password reset flow.
/// Looks up the account by email in Firestore, then asks Firebase to send
/// the PASSWORD_RESET email. Firebase both sends the email and hosts the
/// reset page - there is no in-app reset screen.
///
/// This endpoint intentionally reveals whether an email exists 
/// (AUTH004 vs. success) .
///
/// Error Responses (see constants/error_codes.dart):
/// - 400 AUTH005: email missing or malformed
/// - 404 AUTH004: no account matches the email
/// - 403 AUTH006: account is deactivated (no email sent)
Future<Response> onRequest(RequestContext context) async{
  if (context.request.method != HttpMethod.post) {
    return Response.json( 
      statusCode: 405, 
      body: {'success': false, 'message': 'Method not allowed'},
    );
  }

  try {
    final body = await context.request.json() as Map<String, dynamic>;
    final request = ForgotPasswordRequest.fromJson(body);

    final emailError = AuthValidationService.validateEmail(request.email);
    if(emailError != null) {
      throw AuthException(AuthErrorCode.validationFailed, emailError);
    }

    await FirebaseAuthService.forgotPassword(email: request.email);

    return ResponseHelper.success( 
      message: 'Password reset link sent to your email.',
    );
  } on AuthException catch (e) {
    return ResponseHelper.error(e);
  } catch (e) {
    // ignore: avoid_print 
    print('AUTH009 catch-all error (forgot-password): $e');
    return ResponseHelper.error( 
      AuthException(AuthErrorCode.internalError, 'Internal server error'),
    );
  }
}
