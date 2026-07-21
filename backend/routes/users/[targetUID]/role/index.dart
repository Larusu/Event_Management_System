import 'package:backend/constants/error_codes.dart';
import 'package:backend/services/firebase_auth_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

/// PATCH /users/{targetUID}/role
Future<Response> onRequest(RequestContext context, String targetUid) async {
  if (context.request.method != HttpMethod.patch) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed.'},
    );
  }

  try {
    final requesterUid = context.read<String>();
    final requesterDoc = context.read<Map<String, dynamic>>();
    final requesterRole = requesterDoc['role'] as String? ?? '';

    final body = await context.request.json() as Map<String, dynamic>;
    final newRole = body['new_role'] as String?;

    if (newRole == null || newRole.isEmpty) {
      throw AuthException(AuthErrorCode.validationFailed, 
        'new_role is required.');
    }

    await FirebaseAuthService.changeUserRole(
      targetUid: targetUid,
      requesterUid: requesterUid,
      requesterRole: requesterRole,
      newRole: newRole,
    );

    return ResponseHelper.success(
      message: 'User role updated to $newRole.',
      data: {
        'target_uid': targetUid,
        'new_role': newRole,
      },
    );
  } on AuthException catch (e) {
    return ResponseHelper.error(e);
  } catch (e) {
    return ResponseHelper.error(
      AuthException(AuthErrorCode.internalError, 'Internal server error'),
    );
  }
}
