import 'dart:convert';

import 'package:backend/constants/error_codes.dart';
import 'package:backend/services/firebase_auth_service.dart';
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
    final mockUserDoc = {
      'email': 'test@ciit.edu.ph',
      'name': 'Test User',
      'contact': '09123456789',
    };

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
      when(
        () => request.body(),
      ).thenAnswer((_) async => jsonEncode({'name': 'New Name'}));
      final response = await route.onRequest(context);
      expect(response.statusCode, equals(400));
    });

    test('returns 400 AUTH005 when attempting to change email', () async {
      when(() => request.body()).thenAnswer(
        (_) async => jsonEncode({
          'current_password': 'pass',
          'email': 'hacked@ciit.edu.ph',
        }),
      );
      final response = await route.onRequest(context);
      expect(response.statusCode, equals(400));
    });

    test(
      'no reachable PATCH error response leaks password keys or values',
      () async {
        const secret = 'SuperSecret123';
        final bodies = <String>[
          'invalid json {',
          jsonEncode({'name': 'New Name'}), // missing current_password
          jsonEncode({
            'current_password': secret,
            'email': 'x@ciit.edu.ph',
          }), // email change
          jsonEncode({
            'current_password': secret,
          }), // all optional fields absent
        ];

        for (final b in bodies) {
          when(() => request.body()).thenAnswer((_) async => b);
          final response = await route.onRequest(context);
          final body =
              jsonDecode(await response.body()) as Map<String, dynamic>;
          assertNoPasswordLeak(body, secret: secret);
        }
      },
    );
  });

  group('Response Shape Hard Requirements', () {
    test(
      'publicUserFields strips password-like fields even if the doc has them',
      () {
        final dirtyDoc = {
          'uid': '123', 'email': 'test@ciit.edu.ph', 'name': 'Test',
          'contact': '09123456789', 'role': 'student',
          'updated_at': '2026-07-01T00:00:00.000Z',
          // Simulate a doc that accidentally carries secrets:
          'password': 'hunter2', 'current_password': 'hunter2',
          'new_password': 'newpass123', 'password_hash': 'abc',
        };

        final result = FirebaseAuthService.publicUserFields(dirtyDoc);

        assertNoPasswordLeak(result, secret: 'hunter2');
        expect(
          result.keys.toSet(),
          equals({'uid', 'email', 'name', 'contact', 'role', 'updated_at'}),
        );
      },
    );

    test('AUTH010 includes field: current_password', () async {
      final e = AuthException(
        AuthErrorCode.currentPasswordIncorrect,
        'msg',
        field: 'current_password',
      );
      final response = ResponseHelper.error(e);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(body['code'], equals(AuthErrorCode.currentPasswordIncorrect));
      expect(body['field'], equals('current_password'));
    });

    test('AUTH011 includes field: new_password', () async {
      final e = AuthException(
        AuthErrorCode.passwordSameAsCurrent,
        'msg',
        field: 'new_password',
      );
      final response = ResponseHelper.error(e);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;

      expect(body['code'], equals(AuthErrorCode.passwordSameAsCurrent));
      expect(body['field'], equals('new_password'));
    });
  });
}

void assertNoPasswordLeak(dynamic node, {String? secret}) {
  const forbiddenKeys = {'password', 'current_password', 'new_password'};
  if (node is Map) {
    for (final entry in node.entries) {
      expect(
        forbiddenKeys.contains(entry.key),
        isFalse,
        reason: 'Response leaked forbidden key: ${entry.key}',
      );
      if (secret != null) {
        expect(
          entry.value == secret,
          isFalse,
          reason: 'Response echoed the submitted password value',
        );
      }
      assertNoPasswordLeak(entry.value, secret: secret);
    }
  } else if (node is List) {
    for (final item in node) {
      assertNoPasswordLeak(item, secret: secret);
    }
  }
}
