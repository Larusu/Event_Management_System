// auth_middleware.dart
import 'package:backend/constants/error_codes.dart';
import 'package:backend/services/firebase_auth_service.dart';
import 'package:backend/services/firestore_client.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

/// Runs the universal checks before any route handler: verifies the Firebase
/// ID token (AUTH001), resolves the `users/{uid}` document (AUTH004), and
/// rejects deactivated accounts (AUTH006). On success it provides the verified
/// `uid` and resolved user document to downstream handlers so they never
/// re-verify or re-fetch.
Handler authMiddleware(Handler handler) {
  return (RequestContext context) async {
    try {
      // Step 1: Extract & verify token
      final authHeader = context.request.headers['authorization'];

      // → AUTH001 if invalid/missing
      if(authHeader == null || !authHeader.startsWith('Bearer ')) {
        throw AuthException(AuthErrorCode.invalidToken, 
          'Invalid or expired token.');
      }

      // Parse "Bearer <token>", verify via _firebaseAuth.verifyIdToken(token)
      final token = authHeader.substring(7);
      final debug = FirestoreClient.debugTiming;
      final sw = debug ? (Stopwatch()..start()) : null;

      final uid = await FirebaseAuthService.verifyIdToken(token);
      final verifyMs = sw?.elapsedMilliseconds;

      // Step 2: Get user doc
      final userDoc = await FirebaseAuthService.getUserByUid(uid);
      if (sw != null) {
        // ignore: avoid_print
        print(
          '[authMiddleware] verifyIdToken=${verifyMs}ms '
          'userDoc=${sw.elapsedMilliseconds - verifyMs!}ms',
        );
      }
      
      // Step 3: Check is_deleted
      final isDeleted = userDoc['is_deleted'] as bool? ?? false;

      if (isDeleted) {
        throw AuthException(AuthErrorCode.accountDeactivated,
          'This account has been deactivated.');
      }

      // Step 4: Provide to downstream handlers 
      return handler(
        context.provide<String>(() => uid)
               .provide<Map<String, dynamic>>(() => userDoc),
      );

    } on AuthException catch (e) {
      return ResponseHelper.error(e);
    } catch (e) {
      return ResponseHelper.error(
        AuthException(AuthErrorCode.internalError, 'Internal Server Error'),
      );
    }
  };
}
