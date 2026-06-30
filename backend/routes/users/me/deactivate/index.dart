import 'package:backend/constants/error_codes.dart';
import 'package:backend/services/firebase_auth_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

/// POST /users/me/deactivate
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed.'},
    );
  }

  try {
    final uid = context.read<String>();

    await FirebaseAuthService.deactivateUser(uid); 

    return ResponseHelper.success( 
      message: 'Your account has been deactivated.',
    );
  } on AuthException catch (e) {
    return ResponseHelper.error(e);
  } catch (e) {
    return ResponseHelper.error(
      AuthException(AuthErrorCode.internalError, 'Internal server error'),
    );
  }
}
