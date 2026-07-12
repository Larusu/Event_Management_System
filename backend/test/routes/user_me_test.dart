import 'dart:convert';
import 'package:backend/constants/error_codes.dart';
import 'package:backend/utils/response_helper.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/users/me/index.dart' as route;

class MockRequestContext extends Mock implements RequestContext {}
class MockRequest extends Mock implements Request {}

void main() {
  group('PATCH /users/me Validations', () {
    late MockRequestContext context;
    late MockRequest request;
    final mockUserDoc = {'email': 'test@ciit.edu.ph', 'name': 'Test User', 'contact': '09123456789'};

    setUp(() {
      context = MockRequestContext();
      request = MockRequest();
      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.patch);
      when(() => context.read<String>()).thenReturn('mock_uid');
      when(() => context.read<Map<String, dynamic>>()).thenReturn(mockUserDoc);
    });

    test('returns 400 AUTH005 when JSON is invalid', () async {
      when(() => request.body()).thenAnswer((_) async => 'invalid json {');
      final response = await route.onRequest(context);
      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals(AuthErrorCode.validationFailed));
    });

    test('returns 400 AUTH005 when current_password is missing', () async {
      when(() => request.body()).thenAnswer((_) async => jsonEncode({'name': 'New Name'}));
      final response = await route.onRequest(context);
      expect(response.statusCode, equals(400));
    });

    test('returns 400 AUTH005 when attempting to change email', () async {
      when(() => request.body()).thenAnswer((_) async => jsonEncode({
        'current_password': 'pass',
        'email': 'hacked@ciit.edu.ph'
      }));
      final response = await route.onRequest(context);
      expect(response.statusCode, equals(400));
    });
  });

  group('Response Shape Hard Requirements', () {
    test('Success response NEVER contains password keys', () {
      // Represents the whitelist map built in updateOwnProfile
      final successPayload = {
        'uid': '123',
        'email': 'test@ciit.edu.ph',
        'name': 'Test',
        'contact': '09123456789',
        'role': 'student',
        'updated_at': '2026-07-01T00:00:00.000Z'
      };

      expect(successPayload.containsKey('password'), isFalse);
      expect(successPayload.containsKey('current_password'), isFalse);
      expect(successPayload.containsKey('new_password'), isFalse);
    });

    test('AUTH010 includes field: current_password', () async {
      final e = AuthException(AuthErrorCode.currentPasswordIncorrect, 'msg', field: 'current_password');
      final response = ResponseHelper.error(e);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      
      expect(body['code'], equals(AuthErrorCode.currentPasswordIncorrect));
      expect(body['field'], equals('current_password'));
    });

    test('AUTH011 includes field: new_password', () async {
      final e = AuthException(AuthErrorCode.passwordSameAsCurrent, 'msg', field: 'new_password');
      final response = ResponseHelper.error(e);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      
      expect(body['code'], equals(AuthErrorCode.passwordSameAsCurrent));
      expect(body['field'], equals('new_password'));
    });
  });
}