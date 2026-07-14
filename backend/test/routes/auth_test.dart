import 'dart:convert';

import 'package:backend/models/auth_request.dart';
import 'package:backend/utils/validators.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/auth/forgot-password.dart' as forgot_password_route;
import '../../routes/auth/register.dart' as register_route;
import '../../routes/auth/signin.dart' as signin_route;

class _MockRequestContext extends Mock implements RequestContext {}
class _MockRequest extends Mock implements Request {}

void main() {
  setUpAll(() {
    registerFallbackValue(Map<String, dynamic>.identity());
  });

  group('Validators - edge cases', () {
    test('email with a single space fails regex before space check', () {
      final result = AuthValidationService.validateEmail('test @example.com');
      expect(result, equals('Invalid email format'));
    });

    test('email with multiple spaces fails regex', () {
      final result = AuthValidationService.validateEmail('te st @ex ample.com');
      expect(result, equals('Invalid email format'));
    });

    test('email trimmed to empty after leading/trailing whitespace', () {
      final result = AuthValidationService.validateEmail('   ');
      expect(result, equals('Invalid email format'));
    });

    test('email preserves value when valid', () {
      final result = AuthValidationService.validateEmail('user@example.com');
      expect(result, isNull);
    });

    test('password exactly 8 chars passes minimum', () {
      final result = AuthValidationService.validatePassword('12345678');
      expect(result, isNull);
    });

    test('password 7 chars fails', () {
      final result = AuthValidationService.validatePassword('1234567');
      expect(result, equals('Password must be at least 8 characters'));
    });

    test('password empty fails', () {
      final result = AuthValidationService.validatePassword('');
      expect(result, equals('Password is required'));
    });

    test('password with unicode characters passes if length >= 8', () {
      final result = AuthValidationService.validatePassword('パスワード1234');
      expect(result, isNull);
    });

    test('name single whitespace fails whitespace check', () {
      final result = AuthValidationService.validateName(' ', 'First name');
      expect(result, equals('First name cannot be empty or whitespace only'));
    });

    test('name tab-only fails whitespace check', () {
      final result = AuthValidationService.validateName('\t\t', 'Last name');
      expect(result, equals('Last name cannot be empty or whitespace only'));
    });

    test('name non-whitespace passes', () {
      final result = AuthValidationService.validateName('John', 'First name');
      expect(result, isNull);
    });

    test('contact number 09xxxxxxxxx passes', () {
      final result =
          AuthValidationService.validateContactNumber('09123456789');
      expect(result, isNull);
    });

    test('contact number 0912345678 (10 digits) fails', () {
      final result =
          AuthValidationService.validateContactNumber('0912345678');
      expect(result, contains('11 digits'));
    });

    test('contact number 091234567891 (12 digits) fails', () {
      final result =
          AuthValidationService.validateContactNumber('091234567891');
      expect(result, contains('11 digits'));
    });

    test('contact number starting with 10 fails', () {
      final result =
          AuthValidationService.validateContactNumber('10123456789');
      expect(result, contains('09'));
    });

    test('contact number with plus prefix fails', () {
      final result =
          AuthValidationService.validateContactNumber('+09123456789');
      expect(result, contains('09'));
    });

    test('contact number with letters fails', () {
      final result =
          AuthValidationService.validateContactNumber('09a23456789');
      expect(result, contains('09'));
    });

    test('contact number with dashes fails', () {
      final result =
          AuthValidationService.validateContactNumber('0912-345-789');
      expect(result, contains('09'));
    });

    test('contact number empty fails', () {
      final result = AuthValidationService.validateContactNumber('');
      expect(result, equals('Contact number is required'));
    });

    test('contact number whitespace only fails', () {
      final result = AuthValidationService.validateContactNumber('   ');
      expect(
        result,
        equals('Contact number cannot be empty or whitespace only'),
      );
    });
  });

  group('POST /auth/register', () {
    test('returns 405 for GET', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(405));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['message'], contains('Method not allowed'));
    });

    test('returns 400 with AUTH005 for invalid email format', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': 'invalid-email',
          'password': 'password123',
          'first_name': 'John',
          'last_name': 'Doe',
          'contact': '09123456789',
        },
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for missing email', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': '',
          'password': 'password123',
          'first_name': 'John',
          'last_name': 'Doe',
          'contact': '09123456789',
        },
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
      expect(body['message'], contains('required'));
    });

    test('returns 400 with AUTH005 for empty email', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': '',
          'password': 'password123',
          'first_name': 'John',
          'last_name': 'Doe',
          'contact': '09123456789',
        },
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
        (_) async => <String, dynamic>{
          'email': 'test@example.com',
          'password': 'short',
          'first_name': 'John',
          'last_name': 'Doe',
          'contact': '09123456789',
        },
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
        (_) async => <String, dynamic>{
          'email': 'test@example.com',
          'password': 'password123',
          'first_name': '',
          'last_name': 'Doe',
          'contact': '09123456789',
        },
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for whitespace-only first name', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': 'test@example.com',
          'password': 'password123',
          'first_name': '   ',
          'last_name': 'Doe',
          'contact': '09123456789',
        },
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for missing last name', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': 'test@example.com',
          'password': 'password123',
          'first_name': 'John',
          'last_name': '',
          'contact': '09123456789',
        },
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for whitespace-only last name', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': 'test@example.com',
          'password': 'password123',
          'first_name': 'John',
          'last_name': '  ',
          'contact': '09123456789',
        },
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for missing contact number', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': 'test@example.com',
          'password': 'password123',
          'first_name': 'John',
          'last_name': 'Doe',
          'contact': '',
        },
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for whitespace-only contact number',
        () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': 'test@example.com',
          'password': 'password123',
          'first_name': 'John',
          'last_name': 'Doe',
          'contact': '   ',
        },
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for invalid contact number', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': 'test@example.com',
          'password': 'password123',
          'first_name': 'John',
          'last_name': 'Doe',
          'contact': '1234567890',
        },
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
      expect(body['message'], contains('11 digits'));
    });

    test('returns 400 with AUTH005 for contact number starting with +09',
        () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': 'test@example.com',
          'password': 'password123',
          'first_name': 'John',
          'last_name': 'Doe',
          'contact': '+09123456789',
        },
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for contact number with letters', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': 'test@example.com',
          'password': 'password123',
          'first_name': 'John',
          'last_name': 'Doe',
          'contact': '09a23456789',
        },
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for contact number with dashes', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': 'test@example.com',
          'password': 'password123',
          'first_name': 'John',
          'last_name': 'Doe',
          'contact': '0912-345-789',
        },
      );

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 500 with AUTH009 for malformed JSON body', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenThrow(const FormatException('malformed'));

      final response = await register_route.onRequest(context);

      expect(response.statusCode, equals(500));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH009'));
    });

    test('request model ignores extra fields', () async {
      expect(
        () => RegisterRequest.fromJson(<String, dynamic>{
          'email': 'test@example.com',
          'password': 'password123',
          'first_name': 'John',
          'last_name': 'Doe',
          'contact': '09123456789',
          'role': 'admin',
        }),
        returnsNormally,
      );
    });
  });

  group('POST /auth/signin', () {
    test('returns 405 for PUT', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.put);

      final response = await signin_route.onRequest(context);

      expect(response.statusCode, equals(405));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['message'], contains('Method not allowed'));
    });

    test('returns 400 with AUTH005 for invalid email format', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': 'not-an-email',
          'password': 'password123',
        },
      );

      final response = await signin_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for empty email', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': '',
          'password': 'password123',
        },
      );

      final response = await signin_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for empty password', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': 'test@example.com',
          'password': '',
        },
      );

      final response = await signin_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 500 with AUTH009 for malformed JSON body', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenThrow(const FormatException('malformed'));

      final response = await signin_route.onRequest(context);

      expect(response.statusCode, equals(500));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH009'));
    });
  });

  group('POST /auth/forgot-password', () {
    test('returns 405 for DELETE', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.delete);

      final response = await forgot_password_route.onRequest(context);

      expect(response.statusCode, equals(405));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['message'], contains('Method not allowed'));
    });

    test('returns 400 with AUTH005 for invalid email format', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': 'not-an-email',
        },
      );

      final response = await forgot_password_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });

    test('returns 400 with AUTH005 for missing email', () async {
      final context = _MockRequestContext();
      final request = _MockRequest();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.post);
      when(request.json).thenAnswer(
        (_) async => <String, dynamic>{
          'email': '',
        },
      );

      final response = await forgot_password_route.onRequest(context);

      expect(response.statusCode, equals(400));
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['code'], equals('AUTH005'));
    });
  });
}
