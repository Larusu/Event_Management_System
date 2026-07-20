import 'dart:convert';

import 'package:backend/config/cloudinary_config.dart';
import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Server-side image upload to Cloudinary via its REST API.
class CloudinaryService {
  CloudinaryService._();

  /// Uploads [imageBytes] to Cloudinary and returns the secure URL.
  ///
  /// Throws [AuthException] with code [EventErrorCode.cloudinaryError] if
  /// Cloudinary rejects the upload.
  static Future<String> uploadImage({
    required List<int> imageBytes,
    required String contentType,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Cloudinary signed upload:
    //   signature = SHA1("timestamp={ts}{api_secret}")
    final signatureString =
        'timestamp=$timestamp${CloudinaryConfig.apiSecret}';
    final signature =
        sha1.convert(utf8.encode(signatureString)).toString();

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/'
      '${CloudinaryConfig.cloudName}/image/upload',
    );

    // Cloudinary treats the `file` field as a file upload ONLY when the
    // multipart part carries a filename; without one it parses the bytes as a
    // string and fails with "Invalid URL for upload". The extension is
    // cosmetic (Cloudinary sniffs the real format).
    final extension = contentType == 'image/png' ? 'png' : 'jpg';

    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = CloudinaryConfig.apiKey
      ..fields['timestamp'] = timestamp.toString()
      ..fields['signature'] = signature
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'cover.$extension',
          contentType: MediaType.parse(contentType),
        ),
      );

    final streamedResponse = await request.send();
    final response =
        await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      // Surface Cloudinary's real reason (e.g. "Invalid Signature",
      // "Invalid api_key", "Stale request") in the server logs so upload
      // failures can be diagnosed instead of being an opaque EVT006.
      // ignore: avoid_print
      print(
        '${EventErrorCode.cloudinaryError} Cloudinary upload rejected '
        '(HTTP ${response.statusCode}) for cloud '
        '"${CloudinaryConfig.cloudName}": ${response.body}',
      );
      throw AuthException(
        EventErrorCode.cloudinaryError,
        'Image upload failed. Please try again.',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = json['secure_url'] as String?;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw AuthException(
        EventErrorCode.cloudinaryError,
        'Image upload failed. Please try again.',
      );
    }

    return secureUrl;
  }
}
