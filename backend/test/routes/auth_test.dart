import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/auth/forgot-password.dart' as forgot_password_route;
import '../../routes/auth/register.dart' as register_route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

void main() {
  setUpAll(() {
    registerFallbackValue(Map<String, dynamic>.identity);
  });

  group('POST /auth/register', () {
    test('returns 405 for non-POST method', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(405));
    });

    test('returns 400 with AUTH005 for invalid email format', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) => Future<Map<String, dynamic>>.value(<String, dynamic>{
          'email': 'invalid-email',
          'password': 'password123',
          'first_name': 'John',
          'last_name': 'Doe',
          'contact': '+1234567890',
        }),
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for password less than 8 characters',
        () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) => Future<Map<String, dynamic>>.value(<String, dynamic>{
          'email': 'test@example.com',
          'password': 'short',
          'first_name': 'John',
          'last_name': 'Doe',
          'contact': '+1234567890',
        }),
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for missing first name', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) => Future<Map<String, dynamic>>.value(<String, dynamic>{
          'email': 'test@example.com',
          'password': 'password123',
          'first_name': '',
          'last_name': 'Doe',
          'contact': '+1234567890',
        }),
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });
  });

  group('POST /auth/forgot-password', () {
    test('returns 405 for non-POST method', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);

      final response = await forgot_password_route.onRequest(context);

      expect(response.statusCode, equals(405));
    });

    test('returns 400 with AUTH005 for invalid email format', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) => Future<Map<String, dynamic>>.value(<String, dynamic>{
          'email': 'not-an-email',
        }),
      );

      final response = await forgot_password_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });
  });
}
