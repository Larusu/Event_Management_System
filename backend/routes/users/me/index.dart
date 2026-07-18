import 'dart:convert';

import 'package:backend/constants/error_codes.dart';
import 'package:backend/models/auth_request.dart';
import 'package:backend/services/firebase_auth_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:backend/utils/validators.dart';
import 'package:dart_frog/dart_frog.dart';

/// GET and PATCH /users/me
Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getProfile(context),
    HttpMethod.patch => _patchProfile(context),
    _ => Response.json(
      statusCode: 405,
      body: {'success': false, 'message': 'Method not allowed.'},
    ),
  };
}

Future<Response> _getProfile(RequestContext context) async {
  final uid = context.read<String>();
  final userDoc = context.read<Map<String, dynamic>>();

  return ResponseHelper.success(
    message: 'Profile retrieved successfully.',
    data: {
      'user': {
        'uid': uid,
        'email': userDoc['email'],
        'name': userDoc['name'],
        'contact': userDoc['contact'],
        'role': userDoc['role'],
      },
    },
  );
}

Future<Response> _patchProfile(RequestContext context) async {
  final uid = context.read<String>();
  final userDoc = context.read<Map<String, dynamic>>();
  final email = userDoc['email'] as String;

  Map<String, dynamic> jsonBody;
  try {
    final bodyString = await context.request.body();
    jsonBody = jsonDecode(bodyString) as Map<String, dynamic>;
  } catch (_) {
    return ResponseHelper.error(
      AuthException(AuthErrorCode.validationFailed, 'Invalid JSON body.'),
    );
  }

  // Never accept or process an email field
  if (jsonBody.containsKey('email')) {
    return ResponseHelper.error(
      AuthException(
        AuthErrorCode.validationFailed,
        'Invalid input. Email cannot be changed.',
      ),
    );
  }

  // FIX: Check for current_password BEFORE parsing to prevent 500 crash
  if (!jsonBody.containsKey('current_password') ||
      jsonBody['current_password'] == null ||
      jsonBody['current_password'].toString().trim().isEmpty) {
    return ResponseHelper.error(
      AuthException(
        AuthErrorCode.validationFailed,
        'Current password is required.',
      ),
    );
  }

  final request = UpdateProfileRequest.fromJson(jsonBody);

  final hasName = request.name != null && request.name!.trim().isNotEmpty;
  final hasContact =
      request.contact != null && request.contact!.trim().isNotEmpty;
  final hasNewPassword =
      request.newPassword != null && request.newPassword!.trim().isNotEmpty;

  // Reject with AUTH005 if name, contact, and new_password are all
  // absent
  if (!hasName && !hasContact && !hasNewPassword) {
    return ResponseHelper.error(
      AuthException(
        AuthErrorCode.validationFailed,
        'Invalid input. Please check your details.',
      ),
    );
  }

  // Validate individual fields using existing validators
  if (hasName) {
    final err = AuthValidationService.validateName(request.name!, 'Name');
    if (err != null) return _validationError(err);
  }

  if (hasContact) {
    final err = AuthValidationService.validateContactNumber(request.contact!);
    if (err != null) return _validationError(err);
  }

  if (hasNewPassword) {
    final err = AuthValidationService.validatePassword(request.newPassword!);
    if (err != null) return _validationError(err);
  }

  try {
    // Pass to the service layer
    final updatedUser = await FirebaseAuthService.updateOwnProfile(
      uid: uid,
      email: email,
      currentPassword: request.currentPassword,
      name: request.name,
      contact: request.contact,
      newPassword: request.newPassword,
    );

    return ResponseHelper.success(
      message: 'Profile updated successfully.',
      data: {'user': updatedUser},
    );
  } on AuthException catch (e) {
    // ResponseHelper automatically handles mapping AUTH010 to 401 and AUTH011
    // to 400!
    return ResponseHelper.error(e);
  } catch (e) {
    return ResponseHelper.error(
      AuthException(
        AuthErrorCode.internalError,
        'Something went wrong. Please try again.',
      ),
    );
  }
}

Response _validationError(String message) {
  return ResponseHelper.error(
    AuthException(AuthErrorCode.validationFailed, message),
  );
}
