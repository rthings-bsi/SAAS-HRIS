import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_app/core/constants/app_colors.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/network/api_exception.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton.dart';
import 'package:mobile_app/features/attendance/data/attendance_models.dart';
import 'package:mobile_app/features/attendance/data/attendance_repository.dart';
import 'package:mobile_app/features/attendance/data/camera_service.dart';
import 'package:mobile_app/features/attendance/data/location_service.dart';
import 'package:mobile_app/features/attendance/presentation/attendance_screen.dart';
import 'package:mobile_app/features/attendance/presentation/history_screen.dart';
import 'package:mobile_app/features/attendance/provider/attendance_provider.dart';

class MockLocationService implements LocationService {
  bool isMocked = false;
  double latitude = -6.2088;
  double longitude = 106.8456;
  bool shouldThrow = false;

  @override
  Future<Position> getCurrentPosition() async {
    if (shouldThrow) {
      throw const LocationServiceException('GPS tidak aktif.');
    }
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      isMocked: isMocked,
    );
  }
}

class MockCameraService implements CameraService {
  bool wasCalled = false;
  bool returnNull = false;

  @override
  Future<XFile?> capturePhoto() async {
    wasCalled = true;
    if (returnNull) return null;
    return XFile('test_photo.jpg');
  }
}

class MockAttendanceRepository extends AttendanceRepository {
  MockAttendanceRepository() : super(_DummyApiClient());

  bool clockInCalled = false;
  bool clockOutCalled = false;
  bool shouldThrow = false;
  String? apiErrorMessage;
  Map<String, dynamic> todayData = {
    'date': '2026-10-01',
    'shift': {
      'name': 'Shift Reguler Pagi',
      'start_time': '08:00',
      'end_time': '17:00',
      'late_tolerance_minutes': 15,
    },
    'attendance': null,
  };
  List<dynamic> historyData = [];

  @override
  Future<Map<String, dynamic>> getTodayAttendance() async {
    if (shouldThrow) throw ApiException(message: apiErrorMessage ?? 'Server error');
    return todayData;
  }

  @override
  Future<Map<String, dynamic>> clockIn({
    required double latitude,
    required double longitude,
    String? photoPath,
    Uint8List? photoBytes,
    bool isMocked = false,
  }) async {
    if (shouldThrow) throw ApiException(message: apiErrorMessage ?? 'Radius error');
    clockInCalled = true;
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> clockOut({
    required double latitude,
    required double longitude,
    String? photoPath,
    Uint8List? photoBytes,
    bool isMocked = false,
  }) async {
    if (shouldThrow) throw ApiException(message: apiErrorMessage ?? 'Radius error');
    clockOutCalled = true;
    return {'success': true};
  }

  @override
  Future<List<dynamic>> getAttendanceHistory({int? month, int? year}) async {
    if (shouldThrow) throw ApiException(message: apiErrorMessage ?? 'Error history');
    return historyData;
  }
}

class _DummyApiClient extends Fake implements ApiClient {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (_) {}
  });

  group('Attendance Models & Badge Status', () {
    test('determines Belum Hadir badge status correctly', () {
      final data = TodayAttendanceData.fromMap({
        'shift_name': 'Shift Pagi',
        'start_time': '08:00',
        'end_time': '17:00',
        'late_tolerance_minutes': 15,
        'clock_in': null,
        'clock_out': null,
      });

      expect(data.badgeStatus, AttendanceBadgeStatus.belumHadir);
      expect(data.badgeStatus.label, 'Belum Hadir');
      expect(data.badgeStatus.textColor, AppColors.inkMuted);
      expect(data.badgeStatus.backgroundColor, AppColors.surfaceMuted);
      expect(data.badgeStatus.borderColor, AppColors.borderNeutral);
    });

    test('determines Hadir Tepat Waktu badge status correctly', () {
      final data = TodayAttendanceData.fromMap({
        'shift_name': 'Shift Pagi',
        'start_time': '08:00',
        'end_time': '17:00',
        'late_tolerance_minutes': 15,
        'clock_in': '08:00',
        'clock_out': null,
        'status': 'on_time',
        'late_duration_minutes': 0,
      });

      expect(data.badgeStatus, AttendanceBadgeStatus.tepatWaktu);
      expect(data.badgeStatus.label, 'Hadir Tepat Waktu');
      expect(data.badgeStatus.textColor, AppColors.successText);
      expect(data.badgeStatus.backgroundColor, AppColors.successBg);
      expect(data.badgeStatus.borderColor, AppColors.successBorder);
    });

    test('determines Terlambat badge status correctly', () {
      final data = TodayAttendanceData.fromMap({
        'shift_name': 'Shift Pagi',
        'start_time': '08:00',
        'end_time': '17:00',
        'late_tolerance_minutes': 15,
        'clock_in': '08:30',
        'clock_out': null,
        'status': 'late',
        'late_duration_minutes': 15,
      });

      expect(data.badgeStatus, AttendanceBadgeStatus.terlambat);
      expect(data.badgeStatus.label, 'Terlambat');
      expect(data.badgeStatus.textColor, AppColors.warningText);
      expect(data.badgeStatus.backgroundColor, AppColors.warningBg);
      expect(data.badgeStatus.borderColor, AppColors.warningBorder);
    });

    test('determines Sudah Clock Out badge status correctly', () {
      final data = TodayAttendanceData.fromMap({
        'shift_name': 'Shift Pagi',
        'start_time': '08:00',
        'end_time': '17:00',
        'late_tolerance_minutes': 15,
        'clock_in': '08:00',
        'clock_out': '17:05',
        'status': 'on_time',
      });

      expect(data.badgeStatus, AttendanceBadgeStatus.sudahClockOut);
      expect(data.badgeStatus.label, 'Sudah Clock Out');
      expect(data.badgeStatus.textColor, AppColors.clockOutText);
      expect(data.badgeStatus.backgroundColor, AppColors.clockOutBg);
      expect(data.badgeStatus.borderColor, AppColors.clockOutBorder);
    });
  });

  group('AttendanceActionNotifier & Mock Location Security', () {
    test('halts immediately and sets error when position.isMocked is true', () async {
      final mockLocation = MockLocationService()..isMocked = true;
      final mockCamera = MockCameraService();
      final mockRepo = MockAttendanceRepository();

      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(mockLocation),
          cameraServiceProvider.overrideWithValue(mockCamera),
          attendanceRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(attendanceActionProvider.notifier);
      final result = await notifier.recordAttendance(isClockIn: true);

      expect(result, isFalse);
      expect(
        container.read(attendanceActionProvider).errorMessage,
        'Presensi ditolak. Terdeteksi penggunaan Fake GPS / Mock Location.',
      );
      // Ensure camera and repository were NOT called
      expect(mockCamera.wasCalled, isFalse);
      expect(mockRepo.clockInCalled, isFalse);
    });

    test('successfully clocks in when GPS is authentic', () async {
      final mockLocation = MockLocationService()..isMocked = false;
      final mockCamera = MockCameraService();
      final mockRepo = MockAttendanceRepository();

      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(mockLocation),
          cameraServiceProvider.overrideWithValue(mockCamera),
          attendanceRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(attendanceActionProvider.notifier);
      final result = await notifier.recordAttendance(
        isClockIn: true,
        overridePhotoBytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(result, isTrue);
      expect(mockRepo.clockInCalled, isTrue);
      expect(
        container.read(attendanceActionProvider).successMessage,
        'Presensi masuk berhasil dicatat.',
      );
    });

    test('successfully clocks out when GPS is authentic', () async {
      final mockLocation = MockLocationService()..isMocked = false;
      final mockCamera = MockCameraService();
      final mockRepo = MockAttendanceRepository();

      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(mockLocation),
          cameraServiceProvider.overrideWithValue(mockCamera),
          attendanceRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(attendanceActionProvider.notifier);
      final result = await notifier.recordAttendance(
        isClockIn: false,
        overridePhotoBytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(result, isTrue);
      expect(mockRepo.clockOutCalled, isTrue);
      expect(
        container.read(attendanceActionProvider).successMessage,
        'Presensi pulang berhasil dicatat.',
      );
    });

    test('shows error message on radius validation failure', () async {
      final mockLocation = MockLocationService()..isMocked = false;
      final mockCamera = MockCameraService();
      final mockRepo = MockAttendanceRepository()
        ..shouldThrow = true
        ..apiErrorMessage = 'Jarak perangkat 120m, melebihi batas toleransi 50m.';

      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(mockLocation),
          cameraServiceProvider.overrideWithValue(mockCamera),
          attendanceRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(attendanceActionProvider.notifier);
      final result = await notifier.recordAttendance(
        isClockIn: true,
        overridePhotoBytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(result, isFalse);
      expect(
        container.read(attendanceActionProvider).errorMessage,
        'Jarak perangkat 120m, melebihi batas toleransi 50m.',
      );
    });
  });

  group('AttendanceScreen UI Widgets', () {
    testWidgets('renders shift card, status badge, and "Clock In Sekarang" button',
        (tester) async {
      final mockRepo = MockAttendanceRepository()
        ..todayData = {
          'date': '2026-10-01',
          'shift': {
            'name': 'Shift Reguler Pagi',
            'start_time': '08:00',
            'end_time': '17:00',
            'late_tolerance_minutes': 15,
          },
          'attendance': null,
        };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: AttendanceScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Shift Reguler Pagi'), findsOneWidget);
      expect(find.text('Jam Masuk'), findsOneWidget);
      expect(find.text('Jam Pulang'), findsOneWidget);
      expect(find.text('15 Menit'), findsOneWidget);
      expect(find.text('Belum Hadir'), findsOneWidget);
      expect(find.text('Clock In Sekarang'), findsOneWidget);

      final seeAllFinder = find.widgetWithText(InkWell, 'Lihat Semua');
      expect(seeAllFinder, findsOneWidget);
      final seeAllSize = tester.getSize(seeAllFinder);
      expect(seeAllSize.width, greaterThanOrEqualTo(48.0));
      expect(seeAllSize.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('renders "Clock Out Sekarang" button when clocked in',
        (tester) async {
      final mockRepo = MockAttendanceRepository()
        ..todayData = {
          'date': '2026-10-01',
          'shift': {
            'name': 'Shift Reguler Pagi',
            'start_time': '08:00',
            'end_time': '17:00',
            'late_tolerance_minutes': 15,
          },
          'attendance': {
            'clock_in_time': '08:02',
            'clock_out_time': null,
            'status': 'on_time',
          },
        };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: AttendanceScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Hadir Tepat Waktu'), findsOneWidget);
      expect(find.text('Clock Out Sekarang'), findsOneWidget);
    });

    testWidgets('renders "Presensi Selesai" when already clocked out',
        (tester) async {
      final mockRepo = MockAttendanceRepository()
        ..todayData = {
          'date': '2026-10-01',
          'shift': {
            'name': 'Shift Reguler Pagi',
            'start_time': '08:00',
            'end_time': '17:00',
            'late_tolerance_minutes': 15,
          },
          'attendance': {
            'clock_in_time': '08:02',
            'clock_out_time': '17:05',
            'status': 'on_time',
          },
        };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: AttendanceScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Sudah Clock Out'), findsOneWidget);
      expect(find.text('Presensi Selesai'), findsOneWidget);
    });
  });

  group('HistoryScreen Strict 3 UI States', () {
    testWidgets('renders AppSkeleton placeholders while fetching history',
        (tester) async {
      final completer = Completer<List<AttendanceRecord>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceHistoryProvider.overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(AppSkeleton), findsWidgets);

      completer.complete([]);
      await tester.pump();
      await tester.pumpAndSettle();
    });

    testWidgets('renders AppEmptyState when history is empty', (tester) async {
      final mockRepo = MockAttendanceRepository()..historyData = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Belum ada riwayat kehadiran tercatat.'), findsOneWidget);
    });

    testWidgets('renders AppErrorState when history fetch fails', (tester) async {
      final mockRepo = MockAttendanceRepository()..shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Gagal memuat riwayat kehadiran.'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('renders populated history list with date, times, and badges',
        (tester) async {
      final mockRepo = MockAttendanceRepository()
        ..historyData = [
          {
            'date': '2026-10-01',
            'clock_in_time': '08:00',
            'clock_out_time': '17:00',
            'status': 'on_time',
          },
          {
            'date': '2026-09-30',
            'clock_in_time': '08:25',
            'clock_out_time': null,
            'status': 'late',
            'late_duration_minutes': 10,
          },
        ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            attendanceRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: HistoryScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Sudah Clock Out'), findsOneWidget);
      expect(find.text('Terlambat'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('17:00'), findsOneWidget);
      expect(find.text('08:25'), findsOneWidget);
    });
  });
}
