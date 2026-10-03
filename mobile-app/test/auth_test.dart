import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/network/api_exception.dart';
import 'package:mobile_app/core/network/auth_interceptor.dart';
import 'package:mobile_app/core/network/network_provider.dart';
import 'package:mobile_app/features/auth/data/auth_repository.dart';
import 'package:mobile_app/features/auth/presentation/login_screen.dart';
import 'package:mobile_app/features/auth/provider/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepository extends AuthRepository {
  MockAuthRepository() : super(_DummyApiClient());

  bool shouldFail = false;
  String? failMessage;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw ApiException(
        message: failMessage ?? 'Email atau password salah.',
        statusCode: 401,
      );
    }
    return {
      'access_token': 'mock_token_123',
      'token_type': 'Bearer',
      'user': {
        'id_users': 1,
        'name': 'Budi Santoso',
        'email': email,
        'role': 'employee',
      },
    };
  }

  @override
  Future<void> logout() async {}

  @override
  Future<Map<String, dynamic>> getProfile() async {
    return {
      'id_users': 1,
      'name': 'Budi Santoso',
      'email': 'budi@example.com',
    };
  }
}

class _DummyApiClient extends Fake implements ApiClient {}

class _MockErrorHandler extends Fake implements ErrorInterceptorHandler {
  bool nextCalled = false;
  @override
  void next(DioException err) {
    nextCalled = true;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthNotifier & SharedPreferences', () {
    test('login saves token and user data to SharedPreferences on success', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      final success = await notifier.login('budi@example.com', 'secret123');

      expect(success, isTrue);
      expect(container.read(authStateProvider).status, AuthStatus.authenticated);
      expect(container.read(authStateProvider).user?['name'], 'Budi Santoso');

      final prefs = await container.read(sharedPreferencesProvider.future);
      expect(prefs.getString(AuthInterceptor.tokenKey), 'mock_token_123');
      expect(prefs.getString(AuthNotifier.userKey), contains('Budi Santoso'));
    });

    test('login sets error message on invalid credentials', () async {
      final mockRepo = MockAuthRepository()..shouldFail = true;
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      final success = await notifier.login('wrong@example.com', 'wrongpassword');

      expect(success, isFalse);
      expect(container.read(authStateProvider).status, AuthStatus.initial);
      expect(
        container.read(authStateProvider).errorMessage,
        'Email atau password salah.',
      );
    });

    test('logout clears SharedPreferences and resets state', () async {
      SharedPreferences.setMockInitialValues({
        AuthInterceptor.tokenKey: 'existing_token',
        AuthNotifier.userKey: '{"name":"Budi"}',
      });

      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(authStateProvider.notifier);
      await notifier.logout();

      expect(container.read(authStateProvider).status, AuthStatus.unauthenticated);

      final prefs = await container.read(sharedPreferencesProvider.future);
      expect(prefs.getString(AuthInterceptor.tokenKey), isNull);
      expect(prefs.getString(AuthNotifier.userKey), isNull);
    });

    test('AuthInterceptor clears token and triggers onUnauthorized callback on 401', () async {
      SharedPreferences.setMockInitialValues({
        AuthInterceptor.tokenKey: 'expired_jwt_token',
      });

      bool unauthorizedTriggered = false;
      final interceptor = AuthInterceptor(
        prefsProvider: () => SharedPreferences.getInstance(),
        onUnauthorized: () {
          unauthorizedTriggered = true;
        },
      );

      final handler = _MockErrorHandler();
      final exception = DioException(
        requestOptions: RequestOptions(path: '/api/attendance/today'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/attendance/today'),
          statusCode: 401,
        ),
      );

      interceptor.onError(exception, handler);
      await Future.delayed(const Duration(milliseconds: 50));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(AuthInterceptor.tokenKey), isNull);
      expect(unauthorizedTriggered, isTrue);
      expect(handler.nextCalled, isTrue);
    });
  });

  group('LoginScreen UI', () {
    testWidgets('renders input fields, button, and validates required fields',
        (tester) async {
      final mockRepo = MockAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Email Kerja'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Masuk ke Akun'), findsOneWidget);

      // Tap login without inputs
      await tester.tap(find.text('Masuk ke Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Email kerja wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    });

    testWidgets('displays error banner when login fails', (tester) async {
      final mockRepo = MockAuthRepository()..shouldFail = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email Kerja'),
        'wrong@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Kata Sandi'),
        'wrongpwd',
      );

      await tester.tap(find.text('Masuk ke Akun'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_error_banner')), findsOneWidget);
      expect(find.text('Email atau password salah.'), findsOneWidget);
    });
  });
}
