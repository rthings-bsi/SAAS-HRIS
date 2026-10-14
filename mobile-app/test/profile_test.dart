import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/features/auth/data/auth_repository.dart';
import 'package:mobile_app/features/auth/provider/auth_provider.dart';
import 'package:mobile_app/features/home/presentation/home_screen.dart';
import 'package:mobile_app/features/profile/presentation/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeApiClient extends Fake implements ApiClient {}

class _MockAuthRepo extends AuthRepository {
  _MockAuthRepo() : super(_FakeApiClient());

  bool logoutCalled = false;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    return {
      'id_users': 1,
      'name': 'Ahmad Fauzi',
      'email': 'ahmad.fauzi@example.com',
      'role': 'employee',
      'company': {
        'id_companies': 1,
        'name': 'PT Nusantara Tech',
      },
      'employee': {
        'id_employees': 1,
        'nik': 'EMP-001',
        'phone': '08123456789',
        'gender': 'male',
        'employment_status': 'permanent',
        'hire_date': '2023-01-15',
        'bank_name': 'Bank BCA',
        'bank_account_number': '1234567890',
        'bank_account_holder': 'Ahmad Fauzi',
        'department': {'id_departments': 1, 'name': 'Engineering'},
        'job_position': {'id_job_positions': 1, 'name': 'Software Engineer'},
        'branch': {'id_branches': 1, 'name': 'Kantor Pusat Jakarta'},
      },
    };
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final testUserData = {
    'id_users': 1,
    'name': 'Ahmad Fauzi',
    'email': 'ahmad.fauzi@example.com',
    'role': 'employee',
    'company': {
      'id_companies': 1,
      'name': 'PT Nusantara Tech',
    },
    'employee': {
      'id_employees': 1,
      'nik': 'EMP-001',
      'phone': '08123456789',
      'gender': 'male',
      'employment_status': 'permanent',
      'hire_date': '2023-01-15',
      'bank_name': 'Bank BCA',
      'bank_account_number': '1234567890',
      'bank_account_holder': 'Ahmad Fauzi',
      'department': {'id_departments': 1, 'name': 'Engineering'},
      'job_position': {'id_job_positions': 1, 'name': 'Software Engineer'},
      'branch': {'id_branches': 1, 'name': 'Kantor Pusat Jakarta'},
    },
  };

  testWidgets('ProfileScreen renders employee details correctly', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _MockAuthRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith((ref) {
            final notifier = AuthNotifier(repo, ref);
            notifier.state = AuthState(
              status: AuthStatus.authenticated,
              user: testUserData,
            );
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Profil Saya'), findsOneWidget);
    expect(find.text('Ahmad Fauzi'), findsWidgets);
    expect(find.text('Software Engineer'), findsWidgets);
    expect(find.text('Karyawan Tetap'), findsOneWidget);
    expect(find.text('NIK: EMP-001'), findsOneWidget);
    expect(find.text('PT Nusantara Tech'), findsOneWidget);
    expect(find.text('Kantor Pusat Jakarta'), findsOneWidget);
    expect(find.text('Engineering'), findsOneWidget);
    expect(find.text('ahmad.fauzi@example.com'), findsOneWidget);
    expect(find.text('08123456789'), findsOneWidget);
    expect(find.text('Laki-laki'), findsOneWidget);
    expect(find.text('Bank BCA'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Keluar dari Akun'), 300);
    expect(find.text('Keluar dari Akun'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows confirmation dialog and logs out when confirmed',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _MockAuthRepo();

    late AuthNotifier authNotifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith((ref) {
            authNotifier = AuthNotifier(repo, ref);
            authNotifier.state = AuthState(
              status: AuthStatus.authenticated,
              user: testUserData,
            );
            return authNotifier;
          }),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Keluar dari Akun'), 300);
    final logoutButton = find.text('Keluar dari Akun');
    expect(logoutButton, findsOneWidget);

    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    // Verify confirmation dialog
    expect(find.text('Keluar Akun'), findsOneWidget);
    expect(
      find.text(
        'Apakah Anda yakin ingin keluar dari sesi aplikasi HR Hub pada perangkat ini?',
      ),
      findsOneWidget,
    );
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);

    // Confirm logout
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();

    expect(authNotifier.state.status, AuthStatus.unauthenticated);
    expect(repo.logoutCalled, isTrue);
  });

  testWidgets('HomeScreen has 5 navigation tabs and can navigate to Profile',
      (tester) async {
    final repo = _MockAuthRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith((ref) {
            final notifier = AuthNotifier(repo, ref);
            notifier.state = AuthState(
              status: AuthStatus.authenticated,
              user: testUserData,
            );
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all 5 tabs exist in floating bottom nav
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Lembur'), findsOneWidget);
    expect(find.text('Cuti'), findsOneWidget);
    expect(find.text('Gaji'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Tap Profil tab
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    // Verify ProfileScreen is displayed
    expect(find.text('Profil Saya'), findsOneWidget);
    expect(find.text('Ahmad Fauzi'), findsWidgets);
  });
}
