import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Builds an [http.Client] tuned for a long-lived server talking to Google.
///
/// Every request disables HTTP keep-alive (`persistentConnection = false`) so
/// each Google REST call uses a fresh connection and is never sent on a reused
/// socket. Reusing a long-lived keep-alive connection to Google's front end
/// intermittently desyncs: the next request on that socket comes back as a
/// generic GFE HTML "Error 400 (Bad Request)" (rejected at the edge, ~0ms), or
/// surfaces as "unsolicited response without request" / "Connection reset by
/// peer". Those spurious 400s were turned into AUTH009/EVT008 internal errors.
/// The expensive part that the shared client caches — the service-account
/// OAuth token — is unaffected by this; only the (problematic) socket reuse is
/// dropped. [_RetryOnConnectionResetClient] still retries ONCE on a genuine
/// transient connection exception as a safety net.
http.Client createHardenedClient() {
  final ioClient = HttpClient()
    ..idleTimeout = const Duration(seconds: 5)
    ..connectionTimeout = const Duration(seconds: 15);
  return _RetryOnConnectionResetClient(IOClient(ioClient));
}

class _RetryOnConnectionResetClient extends http.BaseClient {
  _RetryOnConnectionResetClient(this._inner);

  final http.Client _inner;
  static const int maxRetries = 1;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Only plain requests can be safely rebuilt and resent. Streamed or
    // multipart bodies (e.g. the Cloudinary upload) get a single attempt.
    final canRetry = request is http.Request;

    var attempt = 0;
    while (true) {
      final toSend = request is http.Request ? _copy(request) : request;
      // Never reuse a keep-alive socket: a stale/desynced shared connection to
      // Google's front end is what produced the spurious edge HTML 400s (and
      // the "unsolicited response"/"connection reset" errors). A fresh
      // connection per request eliminates that class of failure.
      toSend.persistentConnection = false;
      try {
        final response = await _inner.send(toSend);
        // A cold or desynced connection to Google's front end can also come
        // back as a *successful* HTTP response with a transient status — a
        // spurious edge 400, or a brief 429/5xx during a cold burst. These
        // throw no exception, so without this they'd be turned straight into
        // an internal error by the caller. Retry once here instead. This is
        // safe for our writes: creates use an explicit documentId (a duplicate
        // returns 409, not a second document), so a resend never double-writes.
        if (canRetry &&
            attempt < maxRetries &&
            _isTransientStatus(response.statusCode)) {
          // Drain the body so the underlying socket is released before retry.
          await response.stream.drain<void>();
          attempt++;
          await Future<void>.delayed(_backoff(attempt));
          continue;
        }
        return response;
      } on http.ClientException catch (e) {
        if (!canRetry || attempt >= maxRetries || !_isTransient(e.message)) {
          rethrow;
        }
      } on HttpException catch (e) {
        if (!canRetry || attempt >= maxRetries || !_isTransient(e.message)) {
          rethrow;
        }
      } on SocketException {
        if (!canRetry || attempt >= maxRetries) rethrow;
      }
      attempt++;
      await Future<void>.delayed(_backoff(attempt));
    }
  }

  static bool _isTransient(String message) {
    final m = message.toLowerCase();
    return m.contains('connection reset') ||
        m.contains('connection closed') ||
        m.contains('unsolicited response') ||
        m.contains('broken pipe') ||
        m.contains('connection attempt');
  }

  /// Status codes worth one retry: the spurious GFE edge 400 seen on a cold or
  /// desynced connection, plus the standard transient server/throttle codes.
  static bool _isTransientStatus(int statusCode) {
    return statusCode == 400 ||
        statusCode == 408 ||
        statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;
  }

  /// Small linear backoff between retries (150ms, 300ms, ...).
  static Duration _backoff(int attempt) =>
      Duration(milliseconds: 150 * attempt);

  http.Request _copy(http.Request r) => http.Request(r.method, r.url)
    ..headers.addAll(r.headers)
    ..bodyBytes = r.bodyBytes
    ..followRedirects = r.followRedirects
    ..maxRedirects = r.maxRedirects
    ..persistentConnection = r.persistentConnection
    ..encoding = r.encoding;

  @override
  void close() => _inner.close();
}
