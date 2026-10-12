import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_app/core/constants/app_colors.dart';
import 'package:mobile_app/core/constants/app_dimensions.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/network/api_exception.dart';
import 'package:mobile_app/core/widgets/app_button.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton.dart';
import 'package:mobile_app/features/leave/data/leave_models.dart';
import 'package:mobile_app/features/leave/data/leave_repository.dart';
import 'package:mobile_app/features/leave/presentation/apply_leave_screen.dart';
import 'package:mobile_app/features/leave/presentation/leave_screen.dart';
import 'package:mobile_app/features/leave/provider/leave_provider.dart';

class MockLeaveRepository extends LeaveRepository {
  MockLeaveRepository() : super(_DummyApiClient());

  List<LeaveTypeModel> typesData = [];
  List<LeaveBalanceModel> balancesData = [];
  List<LeaveRequestModel> requestsData = [];
  bool shouldThrow = false;
  String? errorMessage;

  @override
  Future<List<LeaveTypeModel>> getLeaveTypes() async {
    if (shouldThrow) throw ApiException(message: errorMessage ?? 'Error types');
    return typesData;
  }

  @override
  Future<List<LeaveBalanceModel>> getLeaveBalance() async {
    if (shouldThrow) throw ApiException(message: errorMessage ?? 'Error balance');
    return balancesData;
  }

  @override
  Future<List<LeaveRequestModel>> getMyRequests({String? status, int? page}) async {
    if (shouldThrow) throw ApiException(message: errorMessage ?? 'Error requests');
    return requestsData;
  }

  bool submitCalled = false;

  @override
  Future<Map<String, dynamic>> submitLeaveRequest({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? attachmentPath,
    Uint8List? attachmentBytes,
  }) async {
    if (shouldThrow) throw ApiException(message: errorMessage ?? 'Error submit');
    submitCalled = true;
    return {'success': true};
  }
}

class _MockDioApiClient extends Fake implements ApiClient {
  dynamic getResult;
  dynamic postResult;
  bool shouldThrow = false;
  String? errorMessage;
  String? lastGetPath;
  Map<String, dynamic>? lastGetParams;
  String? lastPostPath;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, dynamic options}) async {
    lastGetPath = path;
    lastGetParams = queryParameters;
    if (shouldThrow) throw ApiException(message: errorMessage ?? 'Error');
    return getResult;
  }

  @override
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, dynamic options}) async {
    lastPostPath = path;
    if (shouldThrow) throw ApiException(message: errorMessage ?? 'Error');
    return postResult ?? {'success': true};
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

  group('Leave Models & Status Tests', () {
    test('LeaveTypeModel parses correctly', () {
      final model = LeaveTypeModel.fromMap({
        'id_leave_types': 1,
        'name': 'Cuti Tahunan',
        'quota_days': 12,
        'is_paid': true,
      });

      expect(model.id_leave_types, 1);
      expect(model.name, 'Cuti Tahunan');
      expect(model.quota_days, 12);
      expect(model.is_paid, true);
    });

    test('LeaveBalanceModel parses and calculates remaining days', () {
      final model = LeaveBalanceModel.fromMap({
        'id_leave_types': 1,
        'name': 'Cuti Tahunan',
        'total_quota': 12,
        'used_days': 4,
        'remaining_days': 8,
      });

      expect(model.id_leave_types, 1);
      expect(model.name, 'Cuti Tahunan');
      expect(model.total_quota, 12);
      expect(model.used_days, 4);
      expect(model.remaining_days, 8);
    });

    test('LeaveStatus extensions return valid colors and labels', () {
      expect(LeaveStatus.pending.label, 'Menunggu');
      expect(LeaveStatus.pending.textColor, AppColors.warningText);
      expect(LeaveStatus.pending.backgroundColor, AppColors.warningBg);

      expect(LeaveStatus.approved.label, 'Disetujui');
      expect(LeaveStatus.approved.textColor, AppColors.successText);
      expect(LeaveStatus.approved.backgroundColor, AppColors.successBg);

      expect(LeaveStatus.rejected.label, 'Ditolak');
      expect(LeaveStatus.rejected.textColor, AppColors.dangerText);
      expect(LeaveStatus.rejected.backgroundColor, AppColors.dangerBg);
    });

    test('LeaveRequestModel parses correctly', () {
      final model = LeaveRequestModel.fromMap({
        'id_leave_requests': 10,
        'leave_type': {'id_leave_types': 1, 'name': 'Cuti Tahunan'},
        'start_date': '2026-10-05',
        'end_date': '2026-10-06',
        'total_days': 2,
        'reason': 'Acara keluarga',
        'status': 'pending',
      });

      expect(model.id_leave_requests, 10);
      expect(model.leave_type_name, 'Cuti Tahunan');
      expect(model.start_date, '2026-10-05');
      expect(model.end_date, '2026-10-06');
      expect(model.total_days, 2);
      expect(model.status, LeaveStatus.pending);
    });
  });

  group('LeaveScreen Strict 3 UI States & Accessibility', () {
    testWidgets('renders AppSkeleton when loading data', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            leaveBalanceProvider.overrideWith((ref) => Completer<List<LeaveBalanceModel>>().future),
            leaveMyRequestsProvider(null).overrideWith((ref) => Completer<List<LeaveRequestModel>>().future),
          ],
          child: const MaterialApp(
            home: LeaveScreen(),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(AppSkeleton), findsWidgets);
    });

    testWidgets('renders AppEmptyState when requests list is empty', (tester) async {
      final mockRepo = MockLeaveRepository()
        ..balancesData = [
          const LeaveBalanceModel(
            id_leave_types: 1,
            name: 'Cuti Tahunan',
            total_quota: 12,
            used_days: 0,
            remaining_days: 12,
          ),
        ]
        ..requestsData = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            leaveRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: LeaveScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Belum Ada Pengajuan'), findsOneWidget);
    });

    testWidgets('renders populated requests list with badges and action button', (tester) async {
      final mockRepo = MockLeaveRepository()
        ..balancesData = [
          const LeaveBalanceModel(
            id_leave_types: 1,
            name: 'Cuti Tahunan',
            total_quota: 12,
            used_days: 2,
            remaining_days: 10,
          ),
        ]
        ..requestsData = [
          const LeaveRequestModel(
            id_leave_requests: 1,
            leave_type: 'Cuti Tahunan',
            id_leave_types: 1,
            start_date: '2026-10-05',
            end_date: '2026-10-06',
            total_days: 2,
            reason: 'Keperluan keluarga',
            status: LeaveStatus.pending,
          ),
          const LeaveRequestModel(
            id_leave_requests: 2,
            leave_type: 'Izin Sakit',
            id_leave_types: 2,
            start_date: '2026-09-20',
            end_date: '2026-09-20',
            total_days: 1,
            reason: 'Demam flu',
            status: LeaveStatus.approved,
          ),
        ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            leaveRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: LeaveScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Cuti Tahunan'), findsWidgets);
      expect(find.text('Menunggu'), findsNWidgets(2));
      expect(find.text('Disetujui'), findsNWidgets(2));
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byTooltip('Ajukan Cuti / Izin'), findsOneWidget);
    });

    testWidgets('renders AppErrorState when requests fail', (tester) async {
      final mockRepo = MockLeaveRepository()
        ..shouldThrow = true
        ..errorMessage = 'Koneksi server terputus';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            leaveRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: LeaveScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsWidgets);
      expect(find.text('Koneksi server terputus'), findsWidgets);
    });
  });

  group('Working Days Calculation & Form Validation Helpers', () {
    test('calculateWorkingDays calculates business days correctly excluding weekends', () {
      final mon = DateTime(2026, 10, 5);
      final fri = DateTime(2026, 10, 9);
      expect(calculateWorkingDays(mon, fri), 5);

      final nextMon = DateTime(2026, 10, 12);
      expect(calculateWorkingDays(fri, nextMon), 2);

      final sat = DateTime(2026, 10, 10);
      final sun = DateTime(2026, 10, 11);
      expect(calculateWorkingDays(sat, sun), 0);

      expect(calculateWorkingDays(fri, mon), 0);
    });
  });

  group('LeaveRepository Unit Tests', () {
    test('getLeaveTypes returns parsed list from API', () async {
      final mockClient = _MockDioApiClient()
        ..getResult = [
          {
            'id_leave_types': 1,
            'name': 'Cuti Tahunan',
            'quota_days': 12,
            'is_paid': true,
          },
        ];

      final repo = LeaveRepository(mockClient);
      final types = await repo.getLeaveTypes();
      expect(types.length, 1);
      expect(types.first.name, 'Cuti Tahunan');
    });

    test('getLeaveBalance parses both list and single object response', () async {
      final mockClient = _MockDioApiClient()
        ..getResult = {
          'data': [
            {
              'id_leave_types': 1,
              'name': 'Cuti Tahunan',
              'total_quota': 12,
              'used_days': 2,
              'remaining_days': 10,
            }
          ]
        };

      final repo = LeaveRepository(mockClient);
      final balances = await repo.getLeaveBalance();
      expect(balances.length, 1);
      expect(balances.first.remaining_days, 10);

      mockClient.getResult = {
        'remaining_days': 7,
        'total_quota': 12,
        'used_days': 5,
        'name': 'Cuti Tahunan',
      };
      final balancesSingle = await repo.getLeaveBalance();
      expect(balancesSingle.length, 1);
      expect(balancesSingle.first.remaining_days, 7);
    });

    test('getMyRequests passes status query param and parses list', () async {
      final mockClient = _MockDioApiClient()
        ..getResult = [
          {
            'id_leave_requests': 1,
            'leave_type': 'Cuti Tahunan',
            'start_date': '2026-10-01',
            'end_date': '2026-10-02',
            'total_days': 2,
            'reason': 'Sakit gigi',
            'status': 'pending',
          }
        ];

      final repo = LeaveRepository(mockClient);
      final requests = await repo.getMyRequests(status: 'pending');
      expect(mockClient.lastGetParams?['status'], 'pending');
      expect(requests.length, 1);
      expect(requests.first.status, LeaveStatus.pending);
    });

    test('submitLeaveRequest sends data successfully', () async {
      final mockClient = _MockDioApiClient()..postResult = {'success': true};
      final repo = LeaveRepository(mockClient);

      final result = await repo.submitLeaveRequest(
        leaveTypeId: 1,
        startDate: '2026-10-05',
        endDate: '2026-10-07',
        reason: 'Keperluan mendesak keluarga',
        attachmentBytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      expect(result['success'], isTrue);
      expect(mockClient.lastPostPath, '/leaves/request');
    });
  });

  group('LeaveActionNotifier Tests', () {
    test('handles loading, success, and provider invalidation', () async {
      final mockRepo = MockLeaveRepository();
      final container = ProviderContainer(
        overrides: [
          leaveRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(leaveActionProvider.notifier);
      final success = await notifier.submitLeaveRequest(
        leaveTypeId: 1,
        startDate: '2026-10-05',
        endDate: '2026-10-07',
        reason: 'Urusan keluarga',
      );

      expect(success, isTrue);
      expect(mockRepo.submitCalled, isTrue);
      expect(container.read(leaveActionProvider).isSuccess, isTrue);
      expect(container.read(leaveActionProvider).isLoading, isFalse);

      notifier.reset();
      expect(container.read(leaveActionProvider).isSuccess, isFalse);
    });

    test('captures error message on failure', () async {
      final mockRepo = MockLeaveRepository()
        ..shouldThrow = true
        ..errorMessage = 'Saldo cuti tidak mencukupi.';

      final container = ProviderContainer(
        overrides: [
          leaveRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final notifier = container.read(leaveActionProvider.notifier);
      final success = await notifier.submitLeaveRequest(
        leaveTypeId: 1,
        startDate: '2026-10-05',
        endDate: '2026-10-07',
        reason: 'Urusan keluarga',
      );

      expect(success, isFalse);
      expect(
        container.read(leaveActionProvider).errorMessage,
        contains('Saldo cuti tidak mencukupi.'),
      );
    });
  });

  group('ApplyLeaveScreen UI & Form Tests', () {
    testWidgets('renders all form fields with min 48px touch targets and validates empty submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockLeaveRepository()
        ..typesData = [
          const LeaveTypeModel(
            id_leave_types: 1,
            name: 'Cuti Tahunan',
            quota_days: 12,
            is_paid: true,
          ),
        ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            leaveRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: ApplyLeaveScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Ajukan Cuti & Izin'), findsOneWidget);
      expect(find.text('Jenis Cuti / Izin'), findsOneWidget);
      expect(find.text('Tanggal Mulai'), findsOneWidget);
      expect(find.text('Tanggal Selesai'), findsOneWidget);
      expect(find.text('Durasi: 0 Hari Kerja'), findsOneWidget);
      expect(find.text('Alasan Cuti / Izin'), findsOneWidget);
      expect(find.text('Surat Dokter / Bukti Izin'), findsOneWidget);

      final submitFinder = find.widgetWithText(AppButton, 'Kirim Pengajuan');
      expect(submitFinder, findsOneWidget);
      final size = tester.getSize(submitFinder);
      expect(size.height, greaterThanOrEqualTo(AppDimensions.minTouchTarget));

      // Tap submit without filling
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text('Jenis cuti wajib dipilih.'), findsOneWidget);
      expect(find.text('Alasan cuti wajib diisi.'), findsOneWidget);
    });

    testWidgets('renders remaining quota card when leave type is selected in ApplyLeaveScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockLeaveRepository()
        ..typesData = [
          const LeaveTypeModel(
            id_leave_types: 1,
            name: 'Cuti Tahunan',
            quota_days: 12,
            is_paid: true,
          ),
          const LeaveTypeModel(
            id_leave_types: 2,
            name: 'Izin Sakit',
            quota_days: 0,
            is_paid: true,
          ),
        ]
        ..balancesData = [
          const LeaveBalanceModel(
            id_leave_types: 1,
            name: 'Cuti Tahunan',
            total_quota: 12,
            used_days: 2,
            remaining_days: 10,
          ),
        ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            leaveRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: ApplyLeaveScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Sisa cuti tahunan: 10 hari'), findsOneWidget);

      final dropdownFinder = find.byType(DropdownButtonFormField<int>);
      expect(dropdownFinder, findsOneWidget);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      final dropdownItem = find.text('Cuti Tahunan (12 hari)').last;
      await tester.tap(dropdownItem);
      await tester.pumpAndSettle();

      expect(find.text('Sisa Kuota: 10 Hari'), findsOneWidget);
      expect(find.text('Terpakai: 2 hari'), findsOneWidget);
      expect(find.text('Total Kuota: 12 hari'), findsOneWidget);
    });
  });
}
