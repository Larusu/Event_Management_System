import 'package:backend/config/cloudinary_config.dart';
import 'package:backend/firebase_config.dart';
import 'package:backend/services/firebase_id_token_verifier.dart';
import 'package:backend/services/firestore_client.dart';
import 'package:dart_frog/dart_frog.dart';

// Global initialization flags
bool _firebaseInitialized = false;
bool _cloudinaryInitialized = false;
bool _firestoreWarmed = false;

// CORS headers so browser-based clients (Flutter web) can call the API.
// Use '*' for local dev only; lock this to the real frontend origin in prod.
const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods':
      'GET, POST, PATCH, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};

/// Middleware to initialize Firebase Admin SDK and Cloudinary on first
/// request, then apply CORS headers to every response.
Handler middleware(Handler handler) {
  return (RequestContext context) async {
    // Answer the CORS preflight before any route logic runs.
    if (context.request.method == HttpMethod.options) {
      return Response(statusCode: 204, headers: _corsHeaders);
    }

    // Initialize Firebase once on first request
    if (!_firebaseInitialized && !FirebaseConfig.isInitialized) {
      try {
        await FirebaseConfig.initialize();
        _firebaseInitialized = true;
      } catch (e) {
        // ignore: avoid_print
        print('⚠ Firebase initialization in middleware failed: $e');
        // Continue anyway - some endpoints might not need Firebase
      }
    }

    // Initialize Cloudinary once on first request
    if (!_cloudinaryInitialized && !CloudinaryConfig.isInitialized) {
      try {
        CloudinaryConfig.initialize(FirebaseConfig.envMap);
        _cloudinaryInitialized = true;
      } catch (e) {
        // ignore: avoid_print
        print('⚠ Cloudinary config in middleware failed: $e');
      }
    }

    // Warm the shared Firestore client and the token-verification keys once so
    // the first authenticated request doesn't pay the one-time service-account
    // token mint or the initial JWKS fetch. Both warmUp()s swallow their own
    // errors, so a failure here never blocks the request.
    if (!_firestoreWarmed) {
      _firestoreWarmed = true;
      await Future.wait([
        FirestoreClient.warmUp(),
        FirebaseIdTokenVerifier.warmUp(),
      ]);
    }

    // Continue to route handler, then attach CORS headers.
    final response = await handler(context);
    return response.copyWith(
      headers: {...response.headers, ..._corsHeaders},
    );
  };
}
