import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../constants/api_constants.dart';
import '../models/api_response.dart';
import 'api_exception.dart';

/// Thin wrapper around `http` that talks to the Dart Frog backend.
///
/// Responsibilities:
/// - Prefix requests with [apiBaseUrl] and set the JSON content type.
/// - Optionally attach a fresh Firebase ID token as a Bearer header. The token
///   is fetched per-request (never cached).
/// - Decode the standardized `{ success, message, code }` envelope and throw an
///   [ApiException] on transport errors, non-2xx status, or `success == false`.
class ApiClient {
  final http.Client _client;

  ApiClient([http.Client? client]) : _client = client ?? http.Client();

  Future<ApiResponse> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) {
    return _send(() async => _client.post(
          _uri(path),
          headers: await _headers(auth),
          body: jsonEncode(body),
        ));
  }

  Future<ApiResponse> get(String path, {bool auth = true}) {
    return _send(() async => _client.get(
          _uri(path),
          headers: await _headers(auth),
        ));
  }

  Future<ApiResponse> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) {
    return _send(() async => _client.patch(
          _uri(path),
          headers: await _headers(auth),
          body: jsonEncode(body),
        ));
  }

  /// Uploads a single file as `multipart/form-data` (used for the Cloudinary
  /// cover-image endpoint). The file is sent under [field]; the `Content-Type`
  /// is set per-part from [contentType], never `application/json`.
  Future<ApiResponse> postMultipart(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    required MediaType contentType,
    bool auth = true,
  }) {
    return _send(() async {
      final request = http.MultipartRequest('POST', _uri(path));
      if (auth) {
        final token = await _bearerToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          field,
          bytes,
          filename: filename,
          contentType: contentType,
        ),
      );
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    });
  }

  Uri _uri(String path) {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    return Uri.parse('$base$path');
  }

  Future<Map<String, String>> _headers(bool auth) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _bearerToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Fetches a fresh Firebase ID token for the current user (never cached).
  /// Returns null when there is no signed-in user.
  Future<String?> _bearerToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return user == null ? null : await user.getIdToken();
  }

  Future<ApiResponse> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request();
    } on SocketException {
      throw ApiException.network();
    } on http.ClientException {
      throw ApiException.network();
    }

    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      json = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on FormatException {
      throw ApiException(
        'Unexpected server response (${response.statusCode}).',
      );
    }

    final parsed = ApiResponse.fromJson(json);
    final isOk = response.statusCode >= 200 && response.statusCode < 300;
    if (!isOk || !parsed.success) {
      throw ApiException.fromResponse(json);
    }
    return parsed;
  }
}
