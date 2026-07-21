import 'dart:async';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/services/cloudinary_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mime/mime.dart';

/// Maximum file size: 5 MB.
const _maxFileSize = 5 * 1024 * 1024;

/// Accepted MIME types for cover images.
const _allowedTypes = {'image/jpeg', 'image/png'};

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed.'},
    );
  }

  try {
    // --- Validate Content-Type ---
    final contentType =
        context.request.headers['content-type'] ?? '';
    if (!contentType.contains('multipart/form-data')) {
      return ResponseHelper.error(
        AuthException(
          EventErrorCode.validationFailed,
          'Invalid image file.',
        ),
      );
    }

    final boundary = _extractBoundary(contentType);
    if (boundary == null) {
      return ResponseHelper.error(
        AuthException(
          EventErrorCode.validationFailed,
          'Invalid image file.',
        ),
      );
    }

    // --- Read raw body bytes ---
    // Read the body as a byte stream. We must NOT use request.body(),
    // which decodes the body as a UTF-8 string; binary image data is not
    // valid UTF-8 and throws a FormatException before we ever reach
    // Cloudinary.
    final bodyBytes = await context.request.bytes().fold<List<int>>(
          <int>[],
          (prev, chunk) => prev..addAll(chunk),
        );

    // --- Parse multipart ---
    final transformer = MimeMultipartTransformer(boundary);
    final parts = await transformer
        .bind(Stream<List<int>>.value(bodyBytes))
        .toList();

    // Find the file part named "image".
    List<int>? imageBytes;
    String? partContentType;

    for (final part in parts) {
      final disposition =
          part.headers['content-disposition'] ?? '';
      if (disposition.contains('name="image"')) {
        partContentType =
            part.headers['content-type'] ?? 'image/jpeg';
        imageBytes = await part.fold<List<int>>(
          <int>[],
          (prev, chunk) => prev..addAll(chunk),
        );
        break;
      }
    }

    if (imageBytes == null || imageBytes.isEmpty) {
      return ResponseHelper.error(
        AuthException(
          EventErrorCode.validationFailed,
          'Invalid image file.',
        ),
      );
    }

    // --- Validate type ---
    if (!_allowedTypes.contains(partContentType)) {
      return ResponseHelper.error(
        AuthException(
          EventErrorCode.validationFailed,
          'Unsupported image type. Please use a JPEG or PNG.',
        ),
      );
    }

    // --- Validate size ---
    if (imageBytes.length > _maxFileSize) {
      return ResponseHelper.error(
        AuthException(
          EventErrorCode.validationFailed,
          'Image is too large. Maximum size is 5 MB.',
        ),
      );
    }

    // --- Upload to Cloudinary ---
    final secureUrl = await CloudinaryService.uploadImage(
      imageBytes: imageBytes,
      contentType: partContentType!,
    );

    return Response.json(
      body: {
        'success': true,
        'cover_image_url': secureUrl,
      },
    );
  } on AuthException catch (e) {
    return ResponseHelper.error(e);
  } catch (e, stack) {
    // Only genuine Cloudinary failures are thrown as AuthException with
    // EVT006 above. Anything reaching here is an unexpected server error,
    // so report EVT008 instead of blaming Cloudinary.
    return ResponseHelper.error(
      AuthException(
        EventErrorCode.internalError,
        'Internal server error',
      ),
    );
  }
}

/// Extracts the multipart boundary from the Content-Type header.
String? _extractBoundary(String contentType) {
  for (final part in contentType.split(';')) {
    final trimmed = part.trim();
    if (trimmed.toLowerCase().startsWith('boundary=')) {
      var boundary =
          trimmed.substring('boundary='.length).trim();
      if (boundary.startsWith('"') &&
          boundary.endsWith('"')) {
        boundary =
            boundary.substring(1, boundary.length - 1);
      }
      return boundary.isEmpty ? null : boundary;
    }
  }
  return null;
}
