import 'package:backend/constants/error_codes.dart';
import 'package:backend/services/firebase_auth_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET /users
/// 
/// List users for the faculty/super_admin user-management screen.
//// Supports optional '?search=' (name/email substring) and '?role=' filters
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json( 
      statusCode:405,
      body: {'success': false, 'message': 'Method not allowed(use get).'},
    );
  }
  
  try {
    // Provided by the shared auth middleware (routes/users/_middleware.dart):
    // the token is already verified, the account isn't deactivated, and the
    // resolved user document is handed to us here. We never re-verify/re-fetch.
    final requesterDoc = context.read<Map<String, dynamic>>();
    final requesterRole = requesterDoc['role'] as String? ?? '';

    // Middleware step 4 (route-specific): only faculty/super_admin may browse
    if (requesterRole != 'faculty' && requesterRole != 'super_admin') {
      throw AuthException( 
        AuthErrorCode.insufficientPermission,
        'You do not have permission to view users.',
      );
    }

    final params = context.request.uri.queryParameters;

    final users = await FirebaseAuthService.listUsers( 
      search: params['search'],
      roleFilter: params['role'],
    );

    return ResponseHelper.success( 
      message: 'Users retrieved successfully.',
      data: {'users': users},
    );
  } on AuthException catch (e) {
    return ResponseHelper.error(e);
  } catch (e) {
    return ResponseHelper.error( 
      AuthException(AuthErrorCode.internalError, 'Internal server error. :(')
    );
  }
}

