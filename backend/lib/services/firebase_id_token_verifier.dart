import 'dart:convert';

import 'package:backend/services/hardened_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';

/// Verifies Firebase ID tokens locally, using Google's public signing keys
/// cached in-process.
///
/// Previously verification went through `firebase_admin` -> `openid_client`,
/// which does network work (issuer discovery + JWKS lookup + validation) on
/// every call, over its own HTTP connection. That ran on EVERY protected
/// request and, under the burst of concurrent calls a screen makes on open,
/// dominated latency (hundreds of ms to many seconds).
///
/// Firebase ID tokens are RS256 JWTs signed by Google. We fetch the public
/// key set ONCE, cache it for as long as Google's `Cache-Control: max-age`
/// says (a few hours), and then verify each token with pure in-memory crypto:
/// signature (RS256 only), issuer, audience, expiry, and a non-empty subject.
/// The uid is the `sub` claim.
class FirebaseIdTokenVerifier {
  FirebaseIdTokenVerifier._();

  /// Google's public keys for Firebase Auth tokens, in JWK Set format.
  static const _jwkUrl =
      'https://www.googleapis.com/service_accounts/v1/jwk/'
      'securetoken@system.gserviceaccount.com';

  static final http.Client _client = createHardenedClient();
  static JsonWebKeyStore? _keyStore;
  static DateTime _keysExpireAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Allow a little clock skew between this server and Google.
  static const _clockSkew = Duration(seconds: 30);

  /// Verifies [idToken] for [projectId] and returns the uid (`sub` claim).
  /// Throws [InvalidIdTokenException] on any failure (malformed token, bad
  /// signature, wrong issuer/audience, or expiry).
  static Future<String> verify(
    String idToken, {
    required String projectId,
  }) async {
    final JsonWebToken jwt;
    try {
      jwt = JsonWebToken.unverified(idToken);
    } catch (_) {
      throw const InvalidIdTokenException();
    }

    // Verify the signature. If it fails, the signing keys may have rotated,
    // so force a single refresh and try once more before giving up.
    var store = await _keyStoreForNow();
    var signatureOk = await jwt.verify(store, allowedArguments: const ['RS256']);
    if (!signatureOk) {
      store = await _refreshKeyStore(force: true);
      signatureOk = await jwt.verify(store, allowedArguments: const ['RS256']);
    }
    if (!signatureOk) {
      throw const InvalidIdTokenException();
    }

    final claims = jwt.claims;
    // validate() dereferences exp and aud with `!`, so guard first.
    if (claims.expiry == null || claims.audience == null) {
      throw const InvalidIdTokenException();
    }

    final errors = claims.validate(
      issuer: Uri.parse('https://securetoken.google.com/$projectId'),
      clientId: projectId,
      expiryTolerance: _clockSkew,
    );
    if (errors.isNotEmpty) {
      throw const InvalidIdTokenException();
    }

    final sub = claims.subject;
    if (sub == null || sub.isEmpty) {
      throw const InvalidIdTokenException();
    }
    return sub;
  }

  static Future<JsonWebKeyStore> _keyStoreForNow() async {
    final store = _keyStore;
    if (store != null && DateTime.now().isBefore(_keysExpireAt)) {
      return store;
    }
    return _refreshKeyStore();
  }

  static Future<JsonWebKeyStore> _refreshKeyStore({bool force = false}) async {
    // Avoid hammering Google: if we refreshed very recently (or aren't forcing
    // and the cache is still valid), reuse what we have.
    if (!force && _keyStore != null && DateTime.now().isBefore(_keysExpireAt)) {
      return _keyStore!;
    }

    final http.Response res;
    try {
      res = await _client.get(Uri.parse(_jwkUrl));
    } catch (_) {
      final existing = _keyStore;
      if (existing != null) return existing;
      throw const InvalidIdTokenException();
    }

    if (res.statusCode != 200) {
      final existing = _keyStore;
      if (existing != null) return existing;
      throw const InvalidIdTokenException();
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final store = JsonWebKeyStore()..addKeySet(JsonWebKeySet.fromJson(json));
    _keyStore = store;
    _keysExpireAt = DateTime.now().add(_maxAge(res.headers['cache-control']));
    return store;
  }

  /// Eagerly fetch the keys so the first real request doesn't pay for it.
  static Future<void> warmUp() async {
    try {
      await _refreshKeyStore(force: true);
    } catch (_) {
      // Best-effort; a real request will retry.
    }
  }

  static Duration _maxAge(String? cacheControl) {
    if (cacheControl != null) {
      final match = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
      final seconds = match == null ? null : int.tryParse(match.group(1)!);
      if (seconds != null && seconds > 0) {
        return Duration(seconds: seconds);
      }
    }
    return const Duration(hours: 1);
  }
}

/// Thrown when a Firebase ID token cannot be verified for any reason.
class InvalidIdTokenException implements Exception {
  const InvalidIdTokenException();
}
