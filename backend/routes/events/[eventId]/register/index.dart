import 'dart:convert';

import 'package:backend/constants/event_error_codes.dart';
import 'package:backend/constants/event_exception.dart';
import 'package:backend/services/registration_service.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String eventId) async {
  if (context.request.method == HttpMethod.post) {
    return _handlePost(context, eventId);
  }

  if (context.request.method == HttpMethod.delete) {
    return _handleDelete(context, eventId);
  }

  return Response.json(
    statusCode: 405,
    body: {'success': false, 'message': 'Method not allowed.'},
  );
}

Future<Response> _handlePost(RequestContext context, String eventId) async {
  final uid = context.read<String>();
  final userDoc = context.read<Map<String, dynamic>>();
  final role = userDoc['role'] as String? ?? '';

  try {
    final bodyString = await context.request.body();
    if (bodyString.isNotEmpty) {
      return ResponseHelper.error(
        AuthException(
          EventErrorCode.validationError,
          'Request body must be empty.',
        ),
      );
    }

    await RegistrationService.register(eventId, uid, role);

    return Response.json(
      statusCode: 201,
      body: {'success': true, 'message': 'Registered successfully.'},
    );
  } on EventException catch (e) {
    return ResponseHelper.errorFromException(e);
  } catch (e, stack) {
    print('${EventErrorCode.internalError} register error: $e\n$stack');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'code': EventErrorCode.internalError,
        'message': 'Internal server error',
      },
    );
  }
}

Future<Response> _handleDelete(RequestContext context, String eventId) async {
  final uid = context.read<String>();

  try {
    await RegistrationService.cancel(eventId, uid);

    return Response.json(
      body: {'success': true, 'message': 'Registration cancelled.'},
    );
  } on EventException catch (e) {
    return ResponseHelper.errorFromException(e);
  } catch (e, stack) {
    print('${EventErrorCode.internalError} cancel error: $e\n$stack');
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'code': EventErrorCode.internalError,
        'message': 'Internal server error',
      },
    );
  }
}
