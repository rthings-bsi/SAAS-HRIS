import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_app/core/constants/app_colors.dart';
import 'package:mobile_app/core/constants/app_dimensions.dart';
import 'package:mobile_app/core/constants/api_endpoints.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/network/api_exception.dart';
import 'package:mobile_app/core/widgets/app_button.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton.dart';
import 'package:mobile_app/features/auth/data/auth_repository.dart';
import 'package:mobile_app/features/auth/provider/auth_provider.dart';
import 'package:mobile_app/features/leave/data/leave_models.dart';
import 'package:mobile_app/features/leave/data/leave_repository.dart';
import 'package:mobile_app/features/leave/presentation/apply_leave_screen.dart';
import 'package:mobile_app/features/leave/presentation/leave_detail_screen.dart';
import 'package:mobile_app/features/leave/presentation/leave_screen.dart';
import 'package:mobile_app/features/leave/provider/leave_provider.dart';

class _MockAuthRepo extends AuthRepository {
  _MockAuthRepo() : super(_DummyApiClient());
}

class MockLeaveRepository extends LeaveRepository {
  MockLeaveRepository() : super(_DummyApiClient());

  List<LeaveTypeModel> typesData = [];
  List<LeaveBalanceModel> balancesData = [];
  List<LeaveRequestModel> requestsData = [];
  List<LeaveRequestModel> approvalsData = [];
  bool shouldThrow = false;
  String? errorMessage;
  bool approvalActionCalled = false;
  int? lastApprovalId;
  String? lastApprovalAction;
  String? lastApprovalNotes;

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

  @override
  Future<List<LeaveRequestModel>> getApprovals({String? status, int? page}) async {
    if (shouldThrow) throw ApiException(message: errorMessage ?? 'Error approvals');
    if (status != null && status != 'all') {
      return approvalsData.where((r) => r.status.name == status).toList();
    }
    return approvalsData;
  }

  @override
  Future<Map<String, dynamic>> takeApprovalAction({
    required int id,
    required String action,
    String? notes,
  }) async {
    if (shouldThrow) throw ApiException(message: errorMessage ?? 'Error approval action');
    approvalActionCalled = true;
    lastApprovalId = id;
    lastApprovalAction = action;
    lastApprovalNotes = notes;
    return {'success': true, 'message': 'Pengajuan cuti berhasil diproses.'};
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
      expect(model.pending_days, 0);

      final backendFormat = LeaveBalanceModel.fromMap({
        'id_leave_types': 2,
        'name': 'Cuti Sakit',
        'quota_days': 14,
        'used_days': 2,
        'pending_days': 1,
        'remaining_days': 12,
      });
      expect(backendFormat.total_quota, 14);
      expect(backendFormat.used_days, 2);
      expect(backendFormat.pending_days, 1);
      expect(backendFormat.remaining_days, 12);
    });

    test('LeaveStatus extensions return valid AA colors and labels', () {
      expect(LeaveStatus.pending.label, 'Menunggu');
      expect(LeaveStatus.pending.textColor, const Color(0xFFB45309));
      expect(LeaveStatus.pending.backgroundColor, AppColors.warningBg);

      expect(LeaveStatus.approved.label, 'Disetujui');
      expect(LeaveStatus.approved.textColor, const Color(0xFF047857));
      expect(LeaveStatus.approved.backgroundColor, AppColors.successBg);

      expect(LeaveStatus.rejected.label, 'Ditolak');
      expect(LeaveStatus.rejected.textColor, const Color(0xFFB91C1C));
      expect(LeaveStatus.rejected.backgroundColor, AppColors.dangerBg);

      expect(LeaveStatus.cancelled.label, 'Dibatalkan');
      expect(LeaveStatus.cancelled.textColor, const Color(0xFF475569));
      expect(LeaveStatus.cancelled.backgroundColor, const Color(0xFFF1F5F9));
    });

    test('LeaveRequestModel parses correctly including displayRequestNumber & attachment resolution', () {
      final model = LeaveRequestModel.fromMap({
        'id_leave_requests': 10,
        'leave_type': {'id_leave_types': 1, 'name': 'Cuti Tahunan', 'is_paid': true},
        'start_date': '2026-10-05',
        'end_date': '2026-10-06',
        'total_days': 2,
        'reason': 'Acara keluarga',
        'attachment_url': '/storage/1/leaves/surat.pdf',
        'status': 'pending',
      });

      expect(model.id_leave_requests, 10);
      expect(model.leave_type_name, 'Cuti Tahunan');
      expect(model.start_date, '2026-10-05');
      expect(model.end_date, '2026-10-06');
      expect(model.total_days, 2);
      expect(model.status, LeaveStatus.pending);
      expect(model.displayRequestNumber, 'LVR-202610-000010');
      expect(model.categoryLabel, 'Berbayar');
      final origin = Uri.parse(ApiEndpoints.baseUrl).origin;
      expect(model.resolvedAttachmentUrl, '$origin/storage/1/leaves/surat.pdf');

      final explicitUnpaid = LeaveRequestModel.fromMap({
        'id_leave_requests': 11,
        'request_number': 'LVR-202611-000011',
        'leave_type': 'Cuti Tanpa Gaji',
        'is_paid': false,
        'start_date': '2026-11-01',
        'end_date': '2026-11-01',
        'total_days': 1,
        'reason': 'Urusan pribadi',
        'status': 'cancelled',
      });
      expect(explicitUnpaid.displayRequestNumber, 'LVR-202611-000011');
      expect(explicitUnpaid.categoryLabel, 'Tanpa Gaji');
      expect(explicitUnpaid.status, LeaveStatus.cancelled);
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

    testWidgets('renders populated minimal cards, opens LeaveDetailScreen, and shows filter dialog', (tester) async {
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

      expect(find.text('Pengajuan Cuti'), findsOneWidget);
      expect(find.text('LVR-202610-000001'), findsOneWidget);
      expect(find.text('Cuti Tahunan'), findsWidgets);
      expect(find.text('2 hari'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Disetujui'), findsOneWidget);
      expect(find.byTooltip('Filter Tanggal & Status'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byTooltip('Ajukan Cuti / Izin'), findsOneWidget);

      // Tap minimal card to navigate to LeaveDetailScreen (own view -> no approve/reject bar)
      await tester.tap(find.byKey(const Key('leave_card_1')));
      await tester.pumpAndSettle();

      expect(find.byType(LeaveDetailScreen), findsOneWidget);
      expect(find.text('Rincian Pengajuan Cuti'), findsOneWidget);
      expect(find.text('DETAIL PENGAJUAN CUTI'), findsOneWidget);
      expect(find.text('Berbayar'), findsOneWidget);
      expect(find.byKey(const Key('leave_detail_approve_btn')), findsNothing);
      expect(find.byKey(const Key('leave_detail_reject_btn')), findsNothing);

      await tester.tap(find.byKey(const Key('leave_detail_back_btn')));
      await tester.pumpAndSettle();
      expect(find.byType(LeaveScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Filter Tanggal & Status'));
      await tester.pumpAndSettle();

      expect(find.text('Filter Pengajuan'), findsOneWidget);
      expect(find.text('Semua Tanggal'), findsOneWidget);
      expect(find.text('Ditolak'), findsOneWidget);
      expect(find.text('Dibatalkan'), findsOneWidget);
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
      expect(find.text('Tanggal Cuti'), findsNothing);
      expect(find.text('Tanggal Mulai'), findsOneWidget);
      expect(find.text('Tanggal Selesai'), findsOneWidget);
      expect(find.textContaining('Durasi:'), findsNothing);
      expect(find.text('Alasan Cuti / Izin'), findsOneWidget);
      expect(find.text('Surat Dokter / Bukti Izin'), findsOneWidget);
      expect(find.text('Opsional'), findsOneWidget);
      expect(find.text('Foto JPG atau PNG, maks. 4 MB'), findsOneWidget);
      expect(find.textContaining('Jadwal Cuti Aktif'), findsNothing);
      expect(find.text('Hari Efektif'), findsNothing);
      expect(find.text('Status Kalender Permohonan Cuti'), findsNothing);
      expect(find.text('Opsional / Lampiran'), findsNothing);

      final submitFinder = find.widgetWithText(AppButton, 'Kirim Pengajuan');
      expect(submitFinder, findsOneWidget);
      final size = tester.getSize(submitFinder);
      expect(size.height, greaterThanOrEqualTo(AppDimensions.minTouchTarget));

      // Tap submit without filling
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text('Jenis cuti wajib dipilih.'), findsOneWidget);
      expect(find.text('Tanggal mulai wajib dipilih.'), findsOneWidget);
      expect(find.text('Tanggal selesai wajib dipilih.'), findsOneWidget);
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

      expect(find.textContaining('Sisa cuti tahunan:'), findsNothing);

      final dropdownFinder = find.byType(DropdownButtonFormField<int>);
      expect(dropdownFinder, findsOneWidget);
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      expect(find.text('Sisa 10 dari 12 hari'), findsOneWidget);
      final dropdownItem = find.text('Cuti Tahunan').last;
      await tester.tap(dropdownItem);
      await tester.pumpAndSettle();

      expect(find.text('Cuti Tahunan (Sisa 10/12 hari)'), findsOneWidget);
      expect(find.textContaining('Sisa Kuota:'), findsNothing);
      expect(find.textContaining('Terpakai:'), findsNothing);
      expect(find.textContaining('Total Kuota:'), findsNothing);
    });

    testWidgets('hides redundant calendar booked list while preserving date validation data', (tester) async {
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
        ]
        ..requestsData = [
          const LeaveRequestModel(
            id_leave_requests: 101,
            leave_type: 'Cuti Tahunan',
            start_date: '2026-06-10',
            end_date: '2026-06-12',
            total_days: 3,
            reason: 'Acara Keluarga',
            status: LeaveStatus.approved,
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

      expect(find.text('Tanggal Mulai'), findsOneWidget);
      expect(find.text('Tanggal Selesai'), findsOneWidget);
      expect(find.text('Tanggal Cuti'), findsNothing);
      expect(find.textContaining('Jadwal Cuti Aktif'), findsNothing);
      expect(find.text('Status Kalender Permohonan Cuti'), findsNothing);
      expect(find.text('1 jadwal terdaftar'), findsNothing);
      expect(find.text('Jadwal Cuti yang Sedang Berjalan / Menunggu:'), findsNothing);
    });
  });

  group('Manager & Admin Leave Approval Flow Tests', () {
    testWidgets('renders minimal approval list and approves via LeaveDetailScreen', (tester) async {
      final mockAuthRepo = _MockAuthRepo();
      final mockRepo = MockLeaveRepository()
        ..approvalsData = [
          const LeaveRequestModel(
            id_leave_requests: 55,
            id_employees: 4,
            employee_name: 'Budi Santoso',
            employee_nik: 'EMP-004',
            employee_position: 'Staff IT & Sistem',
            leave_type: 'Cuti Tahunan',
            start_date: '2026-11-12',
            end_date: '2026-11-13',
            total_days: 2,
            reason: 'Keperluan keluarga mendesak',
            status: LeaveStatus.pending,
          ),
        ];

      final managerUser = {
        'id_users': 3,
        'name': 'Norman Alaik',
        'email': 'norman.alaik@hris.com',
        'role': 'manager',
        'employee': {
          'id_employees': 3,
          'nik': 'EMP-003',
          'job_position_name': 'Operational Manager',
        },
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            authStateProvider.overrideWith((ref) {
              final notifier = AuthNotifier(mockAuthRepo, ref);
              notifier.state = AuthState(
                status: AuthStatus.authenticated,
                user: managerUser,
              );
              return notifier;
            }),
            leaveRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: LeaveScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Persetujuan Staf'), findsOneWidget);
      expect(find.text('Pengajuan Saya'), findsOneWidget);
      expect(find.text('Daftar Permohonan Staf'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('LVR-202611-000055'), findsOneWidget);
      expect(find.text('Setujui'), findsNothing);
      expect(find.text('Tolak'), findsNothing);

      await tester.tap(find.byKey(const Key('leave_card_55')));
      await tester.pumpAndSettle();

      expect(find.byType(LeaveDetailScreen), findsOneWidget);
      expect(find.text('Rincian Pengajuan Cuti'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsWidgets);
      expect(find.text('Staff IT & Sistem'), findsWidgets);
      expect(find.text('2 hari kerja'), findsOneWidget);
      expect(find.byKey(const Key('leave_detail_approve_btn')), findsOneWidget);
      expect(find.byKey(const Key('leave_detail_reject_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('leave_detail_approve_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Setujui Cuti Staf?'), findsOneWidget);
      await tester.tap(find.text('Ya, Setujui'));
      await tester.pumpAndSettle();

      expect(mockRepo.approvalActionCalled, isTrue);
      expect(mockRepo.lastApprovalId, 55);
      expect(mockRepo.lastApprovalAction, 'approved');
      expect(find.byType(LeaveScreen), findsOneWidget);
    });

    testWidgets('validates required note on rejection and submits rejected action from LeaveDetailScreen', (tester) async {
      final mockAuthRepo = _MockAuthRepo();
      final mockRepo = MockLeaveRepository()
        ..approvalsData = [
          const LeaveRequestModel(
            id_leave_requests: 56,
            id_employees: 4,
            employee_name: 'Siti Aminah',
            employee_position: 'Analis HR',
            leave_type: 'Cuti Tahunan',
            start_date: '2026-11-16',
            end_date: '2026-11-17',
            total_days: 2,
            reason: 'Acara keluarga di luar kota',
            status: LeaveStatus.pending,
          ),
        ];

      final managerUser = {
        'id_users': 3,
        'name': 'Norman Alaik',
        'role': 'manager',
        'employee': {'id_employees': 3},
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            authStateProvider.overrideWith((ref) {
              final notifier = AuthNotifier(mockAuthRepo, ref);
              notifier.state = AuthState(
                status: AuthStatus.authenticated,
                user: managerUser,
              );
              return notifier;
            }),
            leaveRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(home: LeaveScreen()),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('leave_card_56')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('leave_detail_reject_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Tolak Cuti Staf?'), findsOneWidget);
      await tester.tap(find.text('Tolak Pengajuan'));
      await tester.pumpAndSettle();

      expect(find.text('Alasan penolakan wajib diisi.'), findsOneWidget);
      expect(mockRepo.approvalActionCalled, isFalse);

      await tester.enterText(
        find.byType(TextField),
        'Kuota divisi penuh minggu ini',
      );
      await tester.tap(find.text('Tolak Pengajuan'));
      await tester.pumpAndSettle();

      expect(mockRepo.approvalActionCalled, isTrue);
      expect(mockRepo.lastApprovalId, 56);
      expect(mockRepo.lastApprovalAction, 'rejected');
      expect(mockRepo.lastApprovalNotes, 'Kuota divisi penuh minggu ini');
    });

    testWidgets('opens attachment modal with Salin Tautan on LeaveDetailScreen', (tester) async {
      final mockAuthRepo = _MockAuthRepo();
      final mockRepo = MockLeaveRepository();

      const detailItem = LeaveRequestModel(
        id_leave_requests: 70,
        id_employees: 4,
        employee_name: 'Siti Aminah',
        employee_position: 'Analis HR',
        leave_type: 'Cuti Sakit',
        is_paid: true,
        start_date: '2026-11-16',
        end_date: '2026-11-17',
        total_days: 2,
        reason: 'Demam tinggi sesuai surat dokter',
        attachment_url: '/storage/1/leaves/surat_sakit.pdf',
        status: LeaveStatus.pending,
        created_at: '2026-11-15T08:00:00Z',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepo),
            leaveRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: LeaveDetailScreen(item: detailItem, isApprovalView: false),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('surat_sakit.pdf'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('leave_detail_attachment_btn')),
      );
      await tester.tap(find.byKey(const Key('leave_detail_attachment_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Lampiran Pengajuan'), findsOneWidget);
      expect(find.byKey(const Key('leave_attachment_copy_btn')), findsOneWidget);
      expect(find.text('Salin Tautan'), findsOneWidget);
    });
  });
}
