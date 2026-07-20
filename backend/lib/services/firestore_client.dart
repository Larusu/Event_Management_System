import 'package:backend/firebase_config.dart';
import 'package:backend/services/hardened_http_client.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Process-wide, token-caching HTTP client for Firestore REST calls.
///
/// Previously every service built its own client per Firestore operation:
/// each call minted a fresh service-account OAuth token (a network round-trip
/// to Google) and opened brand-new, never-closed [http.Client]s (no TLS
/// keep-alive). A single request stacked several of these sequentially, which
/// dominated latency (seconds per request).
///
/// This holds ONE [AutoRefreshingAuthClient] for the whole process. The
/// underlying access token (valid ~1h) is minted once and refreshed
/// automatically in the background, and the single client reuses its
/// connection across requests. All services delegate here.
class FirestoreClient {
  FirestoreClient._();

  /// OAuth scopes required for Firestore REST access.
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/datastore',
    'https://www.googleapis.com/auth/cloud-platform',
  ];

  static AutoRefreshingAuthClient? _cached;

  /// Test seam: when set, [instance] returns this instead of a real client.
  /// Lets tests inject a fake [http.Client] without hitting Google.
  static http.Client? _override;

  /// When `FIRESTORE_DEBUG_TIMING=true`, every Firestore round-trip (and token
  /// verification in the auth middleware) logs its elapsed time. Off by
  /// default; use it to measure before/after, then unset it.
  static bool get debugTiming =>
      (FirebaseConfig.envMap['FIRESTORE_DEBUG_TIMING'] ?? '')
          .toLowerCase() ==
      'true';

  /// Returns the shared authenticated client, creating (and caching) it on
  /// first use. Subsequent calls reuse the same client and its cached token.
  static Future<http.Client> instance() async {
    if (_override != null) {
      return _override!;
    }
    final client = _cached ??= await clientViaServiceAccount(
      _credentials(),
      _scopes,
      // A hardened base client (short idle timeout + retry-once) prevents the
      // stale keep-alive reuse that caused "unsolicited response"/"connection
      // reset" stalls on the long-lived shared connection.
      baseClient: createHardenedClient(),
    );
    return debugTiming ? _TimingClient(client) : client;
  }

  /// The Firebase project id, read from the environment/.env overlay.
  static String projectId() {
    final projectId = FirebaseConfig.envMap['FIREBASE_PROJECT_ID'];
    if (projectId == null || projectId.isEmpty) {
      throw StateError('FIREBASE_PROJECT_ID missing from .env');
    }
    return projectId;
  }

  /// Eagerly mints the token/client so the first real request doesn't pay the
  /// one-time cost. Safe to call more than once. Swallows errors so a warmup
  /// failure never blocks startup (the first request will surface it instead).
  static Future<void> warmUp() async {
    if (_override != null || _cached != null) {
      return;
    }
    try {
      await instance();
    } catch (_) {
      // Best-effort: leave _cached null so instance() retries on demand.
    }
  }

  /// Test seam: force [instance] to return [client].
  static set overrideClient(http.Client client) => _override = client;

  /// Test seam: clear any override and drop the cached client.
  static void clearOverride() {
    _override = null;
    _cached = null;
  }

  static ServiceAccountCredentials _credentials() {
    final envMap = FirebaseConfig.envMap;
    final projectId = envMap['FIREBASE_PROJECT_ID'];
    if (projectId == null || projectId.isEmpty) {
      throw StateError('FIREBASE_PROJECT_ID missing from .env');
    }

    return ServiceAccountCredentials.fromJson({
      'type': 'service_account',
      'project_id': projectId,
      'private_key_id': envMap['FIREBASE_PRIVATE_KEY_ID'],
      'private_key':
          envMap['FIREBASE_SERVICE_ACCOUNT_KEY']?.replaceAll(r'\n', '\n'),
      'client_email': envMap['FIREBASE_CLIENT_EMAIL'],
      'client_id': envMap['FIREBASE_CLIENT_ID'],
    });
  }
}

/// Wraps a client to log the elapsed time of each Firestore round-trip.
/// Only used when [FirestoreClient.debugTiming] is on; `close()` is a no-op
/// so it never tears down the long-lived shared client.
class _TimingClient extends http.BaseClient {
  _TimingClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final sw = Stopwatch()..start();
    try {
      return await _inner.send(request);
    } finally {
      sw.stop();
      // ignore: avoid_print
      print(
        '[firestore] ${request.method} ${request.url.path} '
        '${sw.elapsedMilliseconds}ms',
      );
    }
  }

  @override
  void close() {
    // Intentionally does not close the shared inner client.
  }
}
