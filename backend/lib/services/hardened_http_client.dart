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
  _RetryOnConnectionResetClient(this._inner, {this.maxRetries = 1});

  final http.Client _inner;
  final int maxRetries;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Only plain requests can be safely rebuilt and resent. Streamed or
    // multipart bodies (e.g. the Cloudinary upload) get a single attempt.
    final canRetry = request is http.Request;

    var attempt = 0;
    while (true) {
      final toSend = canRetry ? _copy(request as http.Request) : request;
      // Never reuse a keep-alive socket: a stale/desynced shared connection to
      // Google's front end is what produced the spurious edge HTML 400s (and
      // the "unsolicited response"/"connection reset" errors). A fresh
      // connection per request eliminates that class of failure.
      toSend.persistentConnection = false;
      try {
        return await _inner.send(toSend);
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
