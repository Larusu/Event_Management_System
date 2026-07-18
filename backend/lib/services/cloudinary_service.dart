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

    final request = http.MultipartRequest('POST', uri)
      ..fields['api_key'] = CloudinaryConfig.apiKey
      ..fields['timestamp'] = timestamp.toString()
      ..fields['signature'] = signature
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          contentType: MediaType.parse(contentType),
        ),
      );

    final streamedResponse = await request.send();
    final response =
        await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
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
