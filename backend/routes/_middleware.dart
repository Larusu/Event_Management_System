import 'dart:async';

import 'package:backend/config/cloudinary_config.dart';
import 'package:backend/firebase_config.dart';
import 'package:backend/services/firebase_id_token_verifier.dart';
import 'package:backend/services/firestore_client.dart';
import 'package:dart_frog/dart_frog.dart';

/// One-time process bootstrap, shared across every request.
///
/// Stored as a FUTURE — not a bool flag flipped *before* its `await` — so the
/// burst of concurrent requests a screen fires on open all await the SAME
/// initialization. The previous flag-before-await let sibling requests race
/// past the gate and hit Google with a cold service-account token, cold JWKS
/// cache, and a brand-new TLS connection. That cold burst intermittently
/// produced spurious edge 400s / connection resets, which surfaced as generic
/// internal errors that then "worked after refresh" (once things were warm).
Future<void>? _bootstrap;

Future<void> _ensureBootstrapped() {
  final existing = _bootstrap;
  if (existing != null) {
    return existing;
  }
  final future = _bootstrapOnce();
  _bootstrap = future;
  // If bootstrap fails, drop the cached future so the next request retries
  // from scratch instead of being stuck with a permanently-failed one.
  unawaited(future.catchError((Object _) => _bootstrap = null));
  return future;
}

Future<void> _bootstrapOnce() async {
  // Firebase Admin init (needed for custom tokens / user creation). Failure is
  // logged but not fatal — read-only endpoints don't need the Admin SDK.
  if (!FirebaseConfig.isInitialized) {
    try {
      await FirebaseConfig.initialize();
    } catch (e) {
      // ignore: avoid_print
      print('⚠ Firebase initialization in middleware failed: $e');
    }
  }

  // Cloudinary config (needed for cover-image uploads).
  if (!CloudinaryConfig.isInitialized) {
    try {
      CloudinaryConfig.initialize(FirebaseConfig.envMap);
    } catch (e) {
      // ignore: avoid_print
      print('⚠ Cloudinary config in middleware failed: $e');
    }
  }

  // Prime the shared Firestore client (mints the service-account OAuth token)
  // and the token verifier's JWKS cache, so the first authenticated request is
  // never cold. Both warmUp()s swallow their own errors.
  await Future.wait([
    FirestoreClient.warmUp(),
    FirebaseIdTokenVerifier.warmUp(),
  ]);
}

// CORS headers so browser-based clients (Flutter web) can call the API.
// Use '*' for local dev only; lock this to the real frontend origin in prod.
const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods':
      'GET, POST, PATCH, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};

/// Middleware to initialize Firebase Admin SDK and Cloudinary (and warm the
/// Firestore/JWKS caches) on first request, then apply CORS headers to every
/// response.
Handler middleware(Handler handler) {
  return (RequestContext context) async {
    // Answer the CORS preflight before any route logic runs.
    if (context.request.method == HttpMethod.options) {
      return Response(statusCode: 204, headers: _corsHeaders);
    }

    // Every request awaits the SAME one-time bootstrap. Concurrent first
    // requests block here together instead of racing past a half-set flag and
    // hitting Google cold.
    await _ensureBootstrapped();

    // Continue to route handler, then attach CORS headers.
    final response = await handler(context);
    return response.copyWith(
      headers: {...response.headers, ..._corsHeaders},
    );
  };
}
