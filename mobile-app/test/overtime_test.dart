import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/network/api_exception.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton.dart';
import 'package:mobile_app/features/attendance/data/attendance_repository.dart';
import 'package:mobile_app/features/attendance/provider/attendance_provider.dart';
import 'package:mobile_app/features/auth/data/auth_repository.dart';
import 'package:mobile_app/features/auth/provider/auth_provider.dart';
import 'package:mobile_app/features/overtime/data/overtime_draft_service.dart';
import 'package:mobile_app/features/overtime/data/overtime_models.dart';
import 'package:mobile_app/features/overtime/data/overtime_repository.dart';
import 'package:mobile_app/features/overtime/presentation/apply_overtime_form_screen.dart';
import 'package:mobile_app/features/overtime/presentation/overtime_day_schedule_sheet.dart';
import 'package:mobile_app/features/overtime/presentation/overtime_detail_review_screen.dart';
import 'package:mobile_app/features/overtime/presentation/overtime_detail_screen.dart';
import 'package:mobile_app/features/overtime/presentation/overtime_screen.dart';
import 'package:mobile_app/features/overtime/provider/overtime_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DummyApiClient extends Fake implements ApiClient {}

class MockOvertimeRepository extends OvertimeRepository {
  MockOvertimeRepository() : super(_DummyApiClient());

  List<OvertimeRequestModel> requestsData = [];
  List<OvertimeRequestModel> approvalsData = [];
  bool shouldThrow = false;
  String? errorMessage;
  bool cancelCalled = false;
  int? lastCancelledId;
  String? lastCancelReason;
  bool updateCalled = false;
  int? lastUpdatedId;
  String? lastUpdatedDate;
  String? lastUpdatedEndDate;
  String? lastUpdatedStartTime;
  String? lastUpdatedEndTime;
  String? lastUpdatedReason;
  List<Map<String, dynamic>>? lastUpdatedEntries;
  String? lastUpdatedType;
  String? lastUpdatedCategory;
  String? lastUpdatedAttachmentName;
  Uint8List? lastUpdatedAttachmentBytes;
  bool lastRemovedAttachment = false;
  bool applyCalled = false;
  String? lastApplyDate;
  String? lastApplyStartTime;
  String? lastApplyEndTime;
  String? lastApplyReason;
  bool applyBatchCalled = false;
  List<Map<String, dynamic>>? lastBatchEntries;
  String? lastBatchReason;
  bool submitFormCalled = false;
  List<Map<String, dynamic>>? lastSubmitEntries;
  String? lastSubmitReason;
  String? lastSubmitType;
  String? lastSubmitCategory;
  String? lastSubmitAttachmentName;
  Uint8List? lastSubmitAttachmentBytes;
  bool approvalActionCalled = false;
  int? lastApprovalId;
  String? lastApprovalAction;
  String? lastApprovalNotes;

  @override
  Future<List<OvertimeRequestModel>> getApprovals({
    String? status,
    String? date,
    int? page,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage ?? 'Terjadi kesalahan sistem.');
    }
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
    if (shouldThrow) {
      throw ApiException(message: errorMessage ?? 'Gagal memproses lembur.');
    }
    approvalActionCalled = true;
    lastApprovalId = id;
    lastApprovalAction = action;
    lastApprovalNotes = notes;
    return {'success': true, 'message': 'Status pengajuan lembur berhasil diperbarui.'};
  }

  @override
  Future<List<OvertimeRequestModel>> getMyRequests({
    String? status,
    String? month,
    int? page,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage ?? 'Terjadi kesalahan sistem.');
    }
    if (status != null && status != 'all') {
      return requestsData
          .where((r) => r.status.name == status)
          .toList();
    }
    return requestsData;
  }

  @override
  Future<Map<String, dynamic>> cancelOvertime({
    required int id,
    String? reason,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage ?? 'Gagal membatalkan lembur.');
    }
    cancelCalled = true;
    lastCancelledId = id;
    lastCancelReason = reason;
    return {'success': true, 'message': 'Pengajuan lembur berhasil dibatalkan.'};
  }

  @override
  Future<Map<String, dynamic>> applyOvertime({
    required String date,
    required String startTime,
    required String endTime,
    required String reason,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage ?? 'Gagal mengirim lembur.');
    }
    applyCalled = true;
    lastApplyDate = date;
    lastApplyStartTime = startTime;
    lastApplyEndTime = endTime;
    lastApplyReason = reason;
    return {'success': true, 'message': 'Pengajuan lembur berhasil dikirim.'};
  }

  @override
  Future<Map<String, dynamic>> applyOvertimeBatch({
    required List<Map<String, dynamic>> entries,
    required String reason,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage ?? 'Gagal mengirim lembur batch.');
    }
    applyBatchCalled = true;
    lastBatchEntries = entries;
    lastBatchReason = reason;
    return {'success': true, 'message': '${entries.length} pengajuan lembur berhasil dikirim.'};
  }

  @override
  Future<Map<String, dynamic>> submitOvertimeForm({
    required List<Map<String, dynamic>> entries,
    required String reason,
    String? overtimeType,
    String? reasonCategory,
    String? attachmentPath,
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage ?? 'Gagal mengirim form lembur.');
    }
    submitFormCalled = true;
    lastSubmitEntries = entries;
    lastSubmitReason = reason;
    lastSubmitType = overtimeType;
    lastSubmitCategory = reasonCategory;
    lastSubmitAttachmentName = attachmentName;
    lastSubmitAttachmentBytes = attachmentBytes;
    return {'success': true, 'message': '${entries.length} pengajuan lembur berhasil dikirim.'};
  }

  @override
  Future<Map<String, dynamic>> updateOvertime({
    required int id,
    required String date,
    String? endDate,
    required String startTime,
    required String endTime,
    required String reason,
    List<Map<String, dynamic>>? entries,
    String? overtimeType,
    String? reasonCategory,
    String? attachmentPath,
    Uint8List? attachmentBytes,
    String? attachmentName,
    bool removeAttachment = false,
  }) async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage ?? 'Gagal memperbarui lembur.');
    }
    updateCalled = true;
    lastUpdatedId = id;
    lastUpdatedDate = date;
    lastUpdatedEndDate = endDate;
    lastUpdatedStartTime = startTime;
    lastUpdatedEndTime = endTime;
    lastUpdatedReason = reason;
    lastUpdatedEntries = entries;
    lastUpdatedType = overtimeType;
    lastUpdatedCategory = reasonCategory;
    lastUpdatedAttachmentName = attachmentName;
    lastUpdatedAttachmentBytes = attachmentBytes;
    lastRemovedAttachment = removeAttachment;
    return {'success': true, 'message': 'Pengajuan lembur berhasil diperbarui.'};
  }
}

class _MockAuthRepo extends AuthRepository {
  _MockAuthRepo() : super(_DummyApiClient());
}

class _MockAttendanceRepo extends AttendanceRepository {
  _MockAttendanceRepo() : super(_DummyApiClient());

  @override
  Future<Map<String, dynamic>> getTodayAttendance() async => {
        'date': '2026-11-11',
        'shift': {
          'name': 'U5SH2OPR6',
          'start_time': '08:00',
          'end_time': '17:00',
        },
        'attendance': {
          'clock_in_time': '07:55',
          'clock_out_time': '17:05',
          'status': 'on_time',
        },
      };

  @override
  Future<List<dynamic>> getAttendanceHistoryRange({
    required String startDate,
    required String endDate,
    int perPage = 100,
  }) async =>
      [
        {
          'date': '2026-11-11',
          'clock_in_time': '07:55',
          'clock_out_time': '17:05',
          'status': 'on_time',
        },
      ];
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OvertimeStatus Enum & Model Tests', () {
    test('OvertimeStatus parses correctly including cancelled', () {
      expect(OvertimeStatus.fromString('pending'), OvertimeStatus.pending);
      expect(OvertimeStatus.fromString('menunggu'), OvertimeStatus.pending);
      expect(OvertimeStatus.fromString('approved'), OvertimeStatus.approved);
      expect(OvertimeStatus.fromString('disetujui'), OvertimeStatus.approved);
      expect(OvertimeStatus.fromString('rejected'), OvertimeStatus.rejected);
      expect(OvertimeStatus.fromString('ditolak'), OvertimeStatus.rejected);
      expect(OvertimeStatus.fromString('cancelled'), OvertimeStatus.cancelled);
      expect(OvertimeStatus.fromString('dibatalkan'), OvertimeStatus.cancelled);
      expect(OvertimeStatus.fromString('unknown'), OvertimeStatus.pending);
    });

    test('OvertimeStatus label & colors are defined', () {
      expect(OvertimeStatus.pending.label, 'Menunggu');
      expect(OvertimeStatus.approved.label, 'Disetujui');
      expect(OvertimeStatus.rejected.label, 'Ditolak');
      expect(OvertimeStatus.cancelled.label, 'Dibatalkan');

      expect(OvertimeStatus.cancelled.textColor, isA<Color>());
      expect(OvertimeStatus.cancelled.backgroundColor, isA<Color>());
      expect(OvertimeStatus.cancelled.borderColor, isA<Color>());
    });

    test('OvertimeRequestModel parses JSON map and calculates duration', () {
      final map = {
        'id_overtime_requests': 101,
        'id_employees': 5,
        'date': '2026-10-30',
        'start_time': '18:00:00',
        'end_time': '21:00:00',
        'duration_hours': 3.0,
        'reason': 'Deploying hotfix to production',
        'status': 'cancelled',
        'rejected_reason': 'Dibatalkan oleh karyawan: Tidak jadi lembur',
      };

      final model = OvertimeRequestModel.fromMap(map);
      expect(model.id_overtime_requests, 101);
      expect(model.date, '2026-10-30');
      expect(model.duration_hours, 3.0);
      expect(model.formattedDuration, '3 jam');
      expect(model.formattedRequestedDurationLong, '3 jam 0 menit');
      expect(model.displayRequestNumber, 'OVR-202610-000101');
      expect(model.status, OvertimeStatus.cancelled);
      expect(model.rejected_reason, contains('Tidak jadi lembur'));
    });

    test('OvertimeRequestModel parses request_number, employee shift, actual attendance, and rounds duration cleanly', () {
      final map = {
        'id_overtime_requests': 42,
        'request_number': 'OVR-202611-000042',
        'id_employees': 7,
        'date': '2026-11-11',
        'end_date': '2026-11-12',
        'start_time': '22:00:00',
        'end_time': '00:30:00',
        'duration_hours': 2.5,
        'actual_clock_in': '07:55:10',
        'actual_clock_out': '17:04:00',
        'overtime_type': 'Lembur Hari Libur',
        'reason_category': 'Dukungan Operasional',
        'reason': 'Cutover malam',
        'status': 'pending',
        'employee': {
          'nik': 'EMP-007',
          'job_position_name': 'Teknisi Jaringan',
          'user': {'name': 'Ricky Satria'},
          'shift': {
            'name': 'U5SH3OPR6',
            'start_time': '23:00:00',
            'end_time': '07:00:00',
          },
        },
      };

      final model = OvertimeRequestModel.fromMap(map);
      expect(model.displayRequestNumber, 'OVR-202611-000042');
      expect(model.employee_name, 'Ricky Satria');
      expect(model.employee_position, 'Teknisi Jaringan');
      expect(model.shift_name, 'U5SH3OPR6');
      expect(model.formattedShiftRange, '[23:00 - 07:00]');
      expect(OvertimeRequestModel.trimHm(model.actual_clock_in), '07:55');
      expect(OvertimeRequestModel.trimHm(model.actual_clock_out), '17:04');
      expect(model.formattedRequestedDurationLong, '2 jam 30 menit');

      const carryCheck = OvertimeRequestModel(
        id_overtime_requests: 99,
        date: '2026-11-11',
        start_time: '18:00:00',
        end_time: '20:00:00',
        duration_hours: 1.999,
        reason: 'Carry rounding',
        status: OvertimeStatus.pending,
      );
      expect(carryCheck.formattedRequestedDurationLong, '2 jam 0 menit');
    });
  });

  group('OvertimeScreen UI & Interactions', () {
    late MockOvertimeRepository mockRepo;
    late _MockAuthRepo mockAuthRepo;

    setUp(() {
      mockRepo = MockOvertimeRepository();
      mockAuthRepo = _MockAuthRepo();
    });

    final testUserData = {
      'id_users': 1,
      'name': 'Budi Test',
      'email': 'budi@test.com',
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
      },
    };

    Widget createTestWidget({required MockOvertimeRepository repo}) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          authStateProvider.overrideWith((ref) {
            final notifier = AuthNotifier(mockAuthRepo, ref);
            notifier.state = AuthState(
              status: AuthStatus.authenticated,
              user: testUserData,
            );
            return notifier;
          }),
          overtimeRepositoryProvider.overrideWithValue(repo),
          attendanceRepositoryProvider.overrideWithValue(_MockAttendanceRepo()),
        ],
        child: const MaterialApp(
          home: OvertimeScreen(),
        ),
      );
    }

    testWidgets('renders skeleton during loading state', (tester) async {
      await tester.pumpWidget(createTestWidget(repo: mockRepo));
      expect(find.byType(AppSkeleton), findsWidgets);
      await tester.pumpAndSettle();
    });

    testWidgets('renders empty state when no requests exist', (tester) async {
      mockRepo.requestsData = [];
      await tester.pumpWidget(createTestWidget(repo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Belum Ada Pengajuan Lembur'), findsOneWidget);
    });

    testWidgets('renders minimal list cards and navigates to OvertimeDetailScreen on tap',
        (tester) async {
      mockRepo.requestsData = [
        const OvertimeRequestModel(
          id_overtime_requests: 1,
          request_number: 'OVR-202610-000001',
          date: '2026-10-28',
          start_time: '18:00:00',
          end_time: '20:30:00',
          duration_hours: 2.5,
          overtime_type: 'Jam Lembur',
          reason_category: 'Lembur',
          reason: 'Menyelesaikan laporan bulanan',
          status: OvertimeStatus.pending,
        ),
        const OvertimeRequestModel(
          id_overtime_requests: 2,
          request_number: 'OVR-202610-000002',
          date: '2026-10-25',
          start_time: '17:00:00',
          end_time: '19:00:00',
          duration_hours: 2.0,
          reason: 'Maintenance server',
          status: OvertimeStatus.approved,
          approver_name: 'Manager HR',
        ),
      ];

      await tester.pumpWidget(createTestWidget(repo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.text('OVR-202610-000001'), findsOneWidget);
      expect(find.text('OVR-202610-000002'), findsOneWidget);
      expect(find.text('Menyelesaikan laporan bulanan'), findsOneWidget);
      expect(find.text('Maintenance server'), findsOneWidget);
      expect(find.text('Budi Test'), findsNWidgets(2));
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Disetujui'), findsOneWidget);

      // Minimal list card omits inline action buttons & approver notes
      expect(find.text('Revisi'), findsNothing);
      expect(find.text('Batalkan'), findsNothing);
      expect(find.text('Disetujui oleh: Manager HR'), findsNothing);

      // Tap pending card -> opens Rincian Pengajuan Lembur with actions
      await tester.tap(find.byKey(const Key('overtime_card_1')));
      await tester.pumpAndSettle();

      expect(find.text('Rincian Pengajuan Lembur'), findsOneWidget);
      expect(find.text('DETAIL PENGAJUAN LEMBUR'), findsOneWidget);
      expect(find.text('Durasi diajukan 2 jam 30 menit'), findsOneWidget);
      expect(find.byKey(const Key('overtime_detail_revise_btn')), findsOneWidget);
      expect(find.byKey(const Key('overtime_detail_cancel_btn')), findsOneWidget);

      // Navigate back and open approved card -> read-only without action buttons
      await tester.tap(find.byKey(const Key('overtime_detail_back_btn')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('overtime_card_2')));
      await tester.pumpAndSettle();

      expect(find.text('OVR-202610-000002'), findsOneWidget);
      expect(find.text('Disetujui oleh: Manager HR'), findsOneWidget);
      expect(find.byKey(const Key('overtime_detail_revise_btn')), findsNothing);
      expect(find.byKey(const Key('overtime_detail_cancel_btn')), findsNothing);
    });

    testWidgets('tapping "Batalkan" on detail screen opens confirmation dialog and can cancel',
        (tester) async {
      mockRepo.requestsData = [
        const OvertimeRequestModel(
          id_overtime_requests: 12,
          date: '2026-10-29',
          start_time: '18:00:00',
          end_time: '21:00:00',
          duration_hours: 3.0,
          reason: 'Persiapan audit tahunan',
          status: OvertimeStatus.pending,
        ),
      ];

      await tester.pumpWidget(createTestWidget(repo: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('overtime_card_12')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('overtime_detail_cancel_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Batalkan Lembur?'), findsOneWidget);
      expect(find.text('Ya, Batalkan'), findsOneWidget);
      expect(find.text('Alasan Pembatalan (Opsional):'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'Jadwal diundur oleh atasan',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ya, Batalkan'));
      await tester.pumpAndSettle();

      expect(mockRepo.cancelCalled, isTrue);
      expect(mockRepo.lastCancelledId, 12);
      expect(mockRepo.lastCancelReason, 'Jadwal diundur oleh atasan');
      expect(find.text('Pengajuan lembur berhasil dibatalkan.'), findsOneWidget);
    });

    testWidgets('manager sees Persetujuan Staf tab, isolates staff actual attendance, and approves via Detail screen',
        (tester) async {
      mockRepo.approvalsData = [
        const OvertimeRequestModel(
          id_overtime_requests: 88,
          id_employees: 4,
          employee_name: 'Budi Santoso',
          employee_nik: 'EMP-004',
          employee_position: 'Staff IT & Sistem',
          shift_name: 'U5SH3OPR6',
          shift_start_time: '23:00:00',
          shift_end_time: '07:00:00',
          actual_clock_in: '22:50:00',
          actual_clock_out: '07:05:00',
          date: '2026-11-11',
          end_date: '2026-11-12',
          start_time: '07:00:00',
          end_time: '09:00:00',
          duration_hours: 2.0,
          reason: 'Deployment rilis produksi',
          status: OvertimeStatus.pending,
        ),
        const OvertimeRequestModel(
          id_overtime_requests: 89,
          id_employees: 5,
          employee_name: 'Siti Aminah',
          date: '2026-11-11',
          start_time: '18:00:00',
          end_time: '20:00:00',
          duration_hours: 2.0,
          reason: 'Audit stok gudang',
          status: OvertimeStatus.pending,
        ),
      ];

      final managerUserData = {
        'id_users': 3,
        'name': 'Norman Alaik',
        'email': 'norman.alaik@hris.com',
        'role': 'manager',
        'employee': {
          'id_employees': 3,
          'nik': 'EMP-003',
          'shift': {
            'name': 'SHIFT-MANAGER-ONLY',
            'start_time': '09:00:00',
            'end_time': '18:00:00',
          },
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
                user: managerUserData,
              );
              return notifier;
            }),
            overtimeRepositoryProvider.overrideWithValue(mockRepo),
            attendanceRepositoryProvider.overrideWithValue(_MockAttendanceRepo()),
          ],
          child: const MaterialApp(
            home: OvertimeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Persetujuan Staf'), findsOneWidget);
      expect(find.text('Pengajuan Saya'), findsOneWidget);
      expect(find.text('OVR-202611-000088'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Setujui'), findsNothing);
      expect(find.text('Tolak'), findsNothing);

      // Open Siti Aminah (no shift/attendance attached): must NOT leak manager's shift/attendance
      await tester.ensureVisible(find.byKey(const Key('overtime_card_89')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('overtime_card_89')));
      await tester.pumpAndSettle();
      expect(find.textContaining('SHIFT-MANAGER-ONLY'), findsNothing);
      expect(find.text('07:55 | 11 Nov'), findsNothing);
      expect(find.text('--:--'), findsNWidgets(2));

      await tester.tap(find.byKey(const Key('overtime_detail_back_btn')));
      await tester.pumpAndSettle();

      // Open Budi Santoso (with staff shift & actual attendance) and approve
      await tester.ensureVisible(find.byKey(const Key('overtime_card_88')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('overtime_card_88')));
      await tester.pumpAndSettle();

      expect(find.text('U5SH3OPR6 [23:00 - 07:00]'), findsOneWidget);
      expect(find.text('22:50 | 11 Nov'), findsOneWidget);
      expect(find.text('07:05 | 12 Nov'), findsOneWidget);

      await tester.tap(find.byKey(const Key('overtime_detail_approve_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Setujui Lembur Staf?'), findsOneWidget);
      await tester.tap(find.text('Ya, Setujui'));
      await tester.pumpAndSettle();

      expect(mockRepo.approvalActionCalled, isTrue);
      expect(mockRepo.lastApprovalId, 88);
      expect(mockRepo.lastApprovalAction, 'approved');
      expect(find.text('Status pengajuan lembur berhasil diperbarui.'), findsOneWidget);
    });
  });

  group('3-Step Overtime Revision Flow', () {
    late MockOvertimeRepository mockRepo;
    late _MockAuthRepo mockAuthRepo;
    late _MockAttendanceRepo mockAttRepo;

    final employeeUser = {
      'id_users': 4,
      'name': 'Budi Santoso',
      'email': 'budi@hris.com',
      'role': 'employee',
      'employee': {
        'id_employees': 4,
        'nik': 'EMP-004',
        'job_position_name': 'Staff IT & Sistem',
        'shift': {
          'name': 'U5SH2OPR6',
          'start_time': '08:00:00',
          'end_time': '17:00:00',
        },
      },
    };

    setUp(() {
      mockRepo = MockOvertimeRepository();
      mockAuthRepo = _MockAuthRepo();
      mockAttRepo = _MockAttendanceRepo();
    });

    Widget wrapWithScope(Widget child) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          authStateProvider.overrideWith((ref) {
            final notifier = AuthNotifier(mockAuthRepo, ref);
            notifier.state = AuthState(
              status: AuthStatus.authenticated,
              user: employeeUser,
            );
            return notifier;
          }),
          overtimeRepositoryProvider.overrideWithValue(mockRepo),
          attendanceRepositoryProvider.overrideWithValue(mockAttRepo),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets('OvertimeScreen card -> Detail Revisi button opens 3-step Revisi Lembur, supports file remove/undo, shifts date, and submits',
        (tester) async {
      final now = DateTime.now();
      final baseDate = DateTime(now.year, now.month, 10);
      final baseNext = baseDate.add(const Duration(days: 1));
      final targetDate = DateTime(now.year, now.month, 15);
      final targetNext = targetDate.add(const Duration(days: 1));
      final baseIso = OvertimeSlotEntry.formatIsoDate(baseDate);
      final baseNextIso = OvertimeSlotEntry.formatIsoDate(baseNext);
      final targetIso = OvertimeSlotEntry.formatIsoDate(targetDate);
      final targetNextIso = OvertimeSlotEntry.formatIsoDate(targetNext);

      mockRepo.requestsData = [
        OvertimeRequestModel(
          id_overtime_requests: 77,
          employee_name: 'Budi Santoso',
          employee_position: 'Staff IT & Sistem',
          date: baseIso,
          end_date: baseNextIso,
          start_time: '22:00:00',
          end_time: '01:00:00',
          duration_hours: 3.0,
          overtime_type: 'Lembur Hari Libur',
          reason_category: 'Dukungan Operasional',
          reason: 'Deployment rilis tengah malam',
          attachment_url: 'http://localhost:8000/storage/4/overtimes/surat_lama.pdf',
          status: OvertimeStatus.pending,
        ),
      ];

      await tester.pumpWidget(wrapWithScope(const OvertimeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('overtime_card_77')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('overtime_detail_revise_btn')));
      await tester.pumpAndSettle();

      // Screen 1 in Revision mode
      expect(find.text('Revisi Lembur'), findsOneWidget);
      expect(find.text('Tanggal Lembur'), findsOneWidget);
      expect(find.text('Tanggal Berakhir'), findsNothing);
      expect(find.text('Lembur Hari Libur'), findsOneWidget);
      expect(find.text('Dukungan Operasional'), findsOneWidget);
      expect(find.text('Deployment rilis tengah malam'), findsOneWidget);
      expect(find.text('surat_lama.pdf'), findsOneWidget);
      expect(find.text('Lampiran tersimpan saat ini'), findsOneWidget);

      // Remove remote attachment -> undo -> remove again
      await tester.ensureVisible(find.byKey(const Key('overtime_remove_file_btn')));
      await tester.tap(find.byKey(const Key('overtime_remove_file_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('overtime_restore_file_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('overtime_restore_file_btn')));
      await tester.pumpAndSettle();
      expect(find.text('surat_lama.pdf'), findsOneWidget);

      await tester.tap(find.byKey(const Key('overtime_remove_file_btn')));
      await tester.pumpAndSettle();
      expect(
        find.text('Lampiran sebelumnya akan dihapus saat revisi disimpan.'),
        findsOneWidget,
      );

      // Change Tanggal Lembur from day 10 to day 15 -> preserves 22:00 - 01:00 (+1 hr)
      await tester.ensureVisible(find.byKey(const Key('overtime_start_date_btn')));
      await tester.tap(find.byKey(const Key('overtime_start_date_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('overtime_next_step_btn')));
      await tester.pumpAndSettle();

      // Screen 2 in Revision mode
      expect(find.text('Rincian Revisi Lembur'), findsOneWidget);
      expect(find.byKey(const Key('overtime_save_draft_btn')), findsNothing);
      expect(find.text('Simpan Revisi'), findsOneWidget);
      expect(find.text('Lampiran: Akan dihapus saat revisi disimpan'), findsOneWidget);
      expect(find.text('Mulai: 22:00 | Berakhir: 01:00 (+1 hr)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('overtime_submit_btn')));
      await tester.pumpAndSettle();

      expect(mockRepo.updateCalled, isTrue);
      expect(mockRepo.lastUpdatedId, 77);
      expect(mockRepo.lastUpdatedDate, targetIso);
      expect(mockRepo.lastUpdatedEndDate, targetNextIso);
      expect(mockRepo.lastUpdatedStartTime, '22:00');
      expect(mockRepo.lastUpdatedEndTime, '01:00');
      expect(mockRepo.lastRemovedAttachment, isTrue);
      expect(find.text('Revisi pengajuan lembur berhasil disimpan.'), findsOneWidget);
    });

    testWidgets('Revision Screen 1-2-3 edits metadata & replacement attachment while ignoring self in overlap check',
        (tester) async {
      PickedOvertimeAttachment? mockPicked = PickedOvertimeAttachment(
        name: 'surat_revisi_baru.pdf',
        bytes: Uint8List.fromList([7, 8, 9, 10]),
        size: 1024,
        extension: 'pdf',
      );

      const existing = OvertimeRequestModel(
        id_overtime_requests: 77,
        employee_name: 'Budi Santoso',
        employee_position: 'Staff IT & Sistem',
        date: '2026-11-11',
        end_date: '2026-11-11',
        start_time: '18:00:00',
        end_time: '20:00:00',
        duration_hours: 2.0,
        overtime_type: 'Jam Lembur',
        reason_category: 'Lembur',
        reason: 'Revisi awal tugas',
        attachment_url: 'http://localhost:8000/storage/4/overtimes/lama.pdf',
        status: OvertimeStatus.pending,
      );

      // Active requests include #77 itself AND another active request #88 later that night
      mockRepo.requestsData = [
        existing,
        const OvertimeRequestModel(
          id_overtime_requests: 88,
          date: '2026-11-11',
          end_date: '2026-11-11',
          start_time: '21:00:00',
          end_time: '23:00:00',
          duration_hours: 2.0,
          reason: 'Lembur lain',
          status: OvertimeStatus.pending,
        ),
      ];

      await tester.pumpWidget(
        wrapWithScope(
          ApplyOvertimeFormScreen(
            existingRequest: existing,
            onPickAttachment: () async => mockPicked,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Replace attachment on Screen 1
      await tester.ensureVisible(find.byKey(const Key('overtime_remove_file_btn')));
      await tester.tap(find.byKey(const Key('overtime_remove_file_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('overtime_pick_file_btn')));
      await tester.pumpAndSettle();
      expect(find.text('surat_revisi_baru.pdf'), findsOneWidget);

      // Update dropdowns and reason
      await tester.ensureVisible(find.byKey(const Key('overtime_type_dropdown')));
      await tester.tap(find.byKey(const Key('overtime_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lembur Setelah Shift').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('overtime_reason_category_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perbaikan / Maintenance').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('overtime_reason_input')),
        'Revisi perbaikan switch inti',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('overtime_next_step_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Rincian Revisi Lembur'), findsOneWidget);
      expect(find.text('Lampiran: surat_revisi_baru.pdf'), findsOneWidget);

      // Open Screen 3 day sheet -> Tambah Lagi & Reset must be hidden in Revision mode
      await tester.tap(find.byKey(const Key('overtime_day_card_0')));
      await tester.pumpAndSettle();
      expect(find.text('KEHADIRAN AKTUAL'), findsOneWidget);
      expect(find.byKey(const Key('overtime_add_slot_btn')), findsNothing);
      expect(find.byKey(const Key('overtime_slot_reset_btn')), findsNothing);

      await tester.tap(find.byKey(const Key('overtime_update_day_btn')));
      await tester.pumpAndSettle();

      // Submitting must ignore self (#77) and succeed
      await tester.tap(find.byKey(const Key('overtime_submit_btn')));
      await tester.pumpAndSettle();

      expect(mockRepo.updateCalled, isTrue);
      expect(mockRepo.lastUpdatedId, 77);
      expect(mockRepo.lastUpdatedType, 'Lembur Setelah Shift');
      expect(mockRepo.lastUpdatedCategory, 'Perbaikan / Maintenance');
      expect(mockRepo.lastUpdatedReason, 'Revisi perbaikan switch inti');
      expect(mockRepo.lastUpdatedAttachmentName, 'surat_revisi_baru.pdf');
      expect(mockRepo.lastRemovedAttachment, isFalse);
    });

    testWidgets('Revision Screen 2 blocks overlap against a different active overtime request',
        (tester) async {
      mockRepo.requestsData = [
        const OvertimeRequestModel(
          id_overtime_requests: 77,
          date: '2026-11-11',
          end_date: '2026-11-11',
          start_time: '17:00:00',
          end_time: '19:00:00',
          duration_hours: 2.0,
          reason: 'Pengajuan ini',
          status: OvertimeStatus.pending,
        ),
        const OvertimeRequestModel(
          id_overtime_requests: 88,
          date: '2026-11-11',
          end_date: '2026-11-11',
          start_time: '20:00:00',
          end_time: '22:00:00',
          duration_hours: 2.0,
          reason: 'Pengajuan bentrok lain',
          status: OvertimeStatus.approved,
        ),
      ];

      await tester.pumpWidget(
        wrapWithScope(
          OvertimeDetailReviewScreen(
            employeeName: 'Budi Santoso',
            employeePosition: 'Staff IT & Sistem',
            startDate: DateTime(2026, 11, 11),
            endDate: DateTime(2026, 11, 11),
            overtimeType: 'Jam Lembur',
            reasonCategory: 'Lembur',
            reason: 'Mencoba jam bentrok',
            revisingRequestId: 77,
            initialSchedules: [
              OvertimeDaySchedule(
                date: DateTime(2026, 11, 11),
                slots: [
                  OvertimeSlotEntry(
                    startDate: DateTime(2026, 11, 11),
                    endDate: DateTime(2026, 11, 11),
                    startTime: const TimeOfDay(hour: 20, minute: 30),
                    endTime: const TimeOfDay(hour: 22, minute: 30),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('overtime_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.textContaining('tumpang tindih dengan pengajuan aktif'), findsWidgets);
      expect(mockRepo.updateCalled, isFalse);
    });
  });

  group('OvertimeSlotEntry, Draft Model & Draft Service', () {
    test('calculates same-day and cross-day overnight duration accurately', () {
      final sameDay = OvertimeSlotEntry(
        startDate: DateTime(2026, 11, 11),
        endDate: DateTime(2026, 11, 11),
        startTime: const TimeOfDay(hour: 18, minute: 0),
        endTime: const TimeOfDay(hour: 21, minute: 30),
      );
      expect(sameDay.isValid, isTrue);
      expect(sameDay.durationHours, 3.5);

      final overnight = OvertimeSlotEntry(
        startDate: DateTime(2026, 11, 11),
        endDate: DateTime(2026, 11, 12),
        startTime: const TimeOfDay(hour: 22, minute: 0),
        endTime: const TimeOfDay(hour: 2, minute: 0),
      );
      expect(overnight.isValid, isTrue);
      expect(overnight.durationHours, 4.0);

      final reverseInvalid = OvertimeSlotEntry(
        startDate: DateTime(2026, 11, 11),
        endDate: DateTime(2026, 11, 11),
        startTime: const TimeOfDay(hour: 20, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
      );
      expect(reverseInvalid.isValid, isFalse);
      expect(reverseInvalid.durationHours, 0.0);

      final over24hInvalid = OvertimeSlotEntry(
        startDate: DateTime(2026, 11, 11),
        endDate: DateTime(2026, 11, 12),
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 12, minute: 0),
      );
      expect(over24hInvalid.isValid, isFalse);
      expect(over24hInvalid.durationHours, 0.0);
    });

    test('OvertimeDraftModel serializes & deserializes multi-session schedules', () {
      final draft = OvertimeDraftModel(
        id: 'd_1',
        startDate: DateTime(2026, 11, 11),
        endDate: DateTime(2026, 11, 12),
        overtimeType: 'Lembur Hari Libur',
        reasonCategory: 'Dukungan Operasional',
        reason: 'Maintenance server produksi malam',
        attachmentName: 'surat.pdf',
        savedAt: DateTime(2026, 11, 10, 15, 30),
        daySchedules: [
          OvertimeDaySchedule(
            date: DateTime(2026, 11, 11),
            slots: [
              OvertimeSlotEntry(
                startDate: DateTime(2026, 11, 11),
                endDate: DateTime(2026, 11, 11),
                startTime: const TimeOfDay(hour: 18, minute: 0),
                endTime: const TimeOfDay(hour: 20, minute: 0),
              ),
              OvertimeSlotEntry(
                startDate: DateTime(2026, 11, 11),
                endDate: DateTime(2026, 11, 12),
                startTime: const TimeOfDay(hour: 22, minute: 0),
                endTime: const TimeOfDay(hour: 1, minute: 0),
              ),
            ],
          ),
          OvertimeDaySchedule(date: DateTime(2026, 11, 12)),
        ],
      );

      final decoded = OvertimeDraftModel.fromJson(draft.toJson());
      expect(decoded.id, 'd_1');
      expect(decoded.overtimeType, 'Lembur Hari Libur');
      expect(decoded.reasonCategory, 'Dukungan Operasional');
      expect(decoded.reason, 'Maintenance server produksi malam');
      expect(decoded.attachmentName, 'surat.pdf');
      expect(decoded.configuredDayCount, 1);
      expect(decoded.daySchedules, hasLength(2));
      expect(decoded.daySchedules[0].slots, hasLength(2));
      expect(decoded.daySchedules[0].totalHours, 5.0);
      expect(decoded.daySchedules[1].isConfigured, isFalse);
    });

    test('OvertimeDraftService isolates drafts per userId and deletes cleanly', () async {
      final service = OvertimeDraftService();
      final d1 = OvertimeDraftModel(
        id: 'u1_old',
        startDate: DateTime(2026, 11, 10),
        endDate: DateTime(2026, 11, 10),
        overtimeType: 'Jam Lembur',
        reasonCategory: 'Lembur',
        reason: 'Tugas pertama',
        daySchedules: [OvertimeDaySchedule(date: DateTime(2026, 11, 10))],
        savedAt: DateTime(2026, 11, 10, 9, 0),
      );
      final d2 = OvertimeDraftModel(
        id: 'u1_new',
        startDate: DateTime(2026, 11, 11),
        endDate: DateTime(2026, 11, 11),
        overtimeType: 'Lembur Setelah Shift',
        reasonCategory: 'Inventaris / Audit',
        reason: 'Audit stok',
        daySchedules: [OvertimeDaySchedule(date: DateTime(2026, 11, 11))],
        savedAt: DateTime(2026, 11, 10, 12, 0),
      );
      final dOther = OvertimeDraftModel(
        id: 'u2_only',
        startDate: DateTime(2026, 11, 12),
        endDate: DateTime(2026, 11, 12),
        overtimeType: 'Jam Lembur',
        reasonCategory: 'Lembur',
        reason: 'Draft user lain',
        daySchedules: [OvertimeDaySchedule(date: DateTime(2026, 11, 12))],
        savedAt: DateTime(2026, 11, 10, 13, 0),
      );

      await service.saveDraft(10, d1);
      await service.saveDraft(10, d2);
      await service.saveDraft(20, dOther);

      final user10List = await service.loadDrafts(10);
      final user20List = await service.loadDrafts(20);
      expect(user10List.map((e) => e.id).toList(), ['u1_new', 'u1_old']);
      expect(user20List.map((e) => e.id).toList(), ['u2_only']);

      await service.deleteDraft(10, 'u1_old');
      final afterDelete = await service.loadDrafts(10);
      expect(afterDelete.map((e) => e.id).toList(), ['u1_new']);
      expect((await service.loadDrafts(20)).map((e) => e.id).toList(), ['u2_only']);
    });
  });

  group('3-Step Overtime Workflow (Form -> Detail -> Day Sheet)', () {
    late MockOvertimeRepository mockRepo;
    late _MockAuthRepo mockAuthRepo;
    late _MockAttendanceRepo mockAttRepo;

    final employeeUser = {
      'id_users': 4,
      'name': 'Budi Santoso',
      'email': 'budi@hris.com',
      'role': 'employee',
      'employee': {
        'id_employees': 4,
        'nik': 'EMP-004',
        'job_position_name': 'Staff IT & Sistem',
        'shift': {
          'name': 'U5SH2OPR6',
          'start_time': '08:00:00',
          'end_time': '17:00:00',
        },
      },
    };

    setUp(() {
      mockRepo = MockOvertimeRepository();
      mockAuthRepo = _MockAuthRepo();
      mockAttRepo = _MockAttendanceRepo();
    });

    Widget wrapWithScope(Widget child) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          authStateProvider.overrideWith((ref) {
            final notifier = AuthNotifier(mockAuthRepo, ref);
            notifier.state = AuthState(
              status: AuthStatus.authenticated,
              user: employeeUser,
            );
            return notifier;
          }),
          overtimeRepositoryProvider.overrideWithValue(mockRepo),
          attendanceRepositoryProvider.overrideWithValue(mockAttRepo),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets('Screen 1 validates reason, handles attachment limits, and forwards metadata to Screen 2',
        (tester) async {
      PickedOvertimeAttachment? mockPicked;

      await tester.pumpWidget(
        wrapWithScope(
          ApplyOvertimeFormScreen(
            onPickAttachment: () async => mockPicked,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Form Lembur'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);

      // Empty reason validation
      await tester.tap(find.byKey(const Key('overtime_next_step_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Keterangan wajib diisi.'), findsOneWidget);

      // Short reason validation
      await tester.enterText(find.byKey(const Key('overtime_reason_input')), 'abc');
      await tester.tap(find.byKey(const Key('overtime_next_step_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Keterangan minimal 5 karakter.'), findsOneWidget);

      // Reject >5MB file
      mockPicked = PickedOvertimeAttachment(
        name: 'terlalu_besar.pdf',
        bytes: Uint8List.fromList([1, 2, 3]),
        size: 6 * 1024 * 1024,
        extension: 'pdf',
      );
      await tester.ensureVisible(find.byKey(const Key('overtime_pick_file_btn')));
      await tester.tap(find.byKey(const Key('overtime_pick_file_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Ukuran berkas melebihi batas maksimal 5 MB.'), findsOneWidget);
      expect(find.text('terlalu_besar.pdf'), findsNothing);

      // Reject unsupported extension
      mockPicked = PickedOvertimeAttachment(
        name: 'malware.exe',
        bytes: Uint8List.fromList([1, 2, 3]),
        size: 1024,
        extension: 'exe',
      );
      await tester.tap(find.byKey(const Key('overtime_pick_file_btn')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Format berkas tidak didukung. Gunakan txt, doc, docx, xls, xlsx, pdf, jpg, png, gif, atau jpeg.',
        ),
        findsOneWidget,
      );

      // Accept valid file then remove then re-pick
      mockPicked = PickedOvertimeAttachment(
        name: 'surat_perintah.pdf',
        bytes: Uint8List.fromList([10, 20, 30, 40]),
        size: 2048,
        extension: 'pdf',
      );
      await tester.tap(find.byKey(const Key('overtime_pick_file_btn')));
      await tester.pumpAndSettle();
      expect(find.text('surat_perintah.pdf'), findsOneWidget);

      await tester.tap(find.byKey(const Key('overtime_remove_file_btn')));
      await tester.pumpAndSettle();
      expect(find.text('surat_perintah.pdf'), findsNothing);

      await tester.tap(find.byKey(const Key('overtime_pick_file_btn')));
      await tester.pumpAndSettle();
      expect(find.text('surat_perintah.pdf'), findsOneWidget);

      // Change dropdowns
      await tester.tap(find.byKey(const Key('overtime_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lembur Hari Libur').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('overtime_reason_category_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dukungan Operasional').last);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('overtime_reason_input')),
        'Support Produksi Lini 2',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('overtime_next_step_btn')));
      await tester.pumpAndSettle();

      // Now on Screen 2 (Rincian Form Lembur)
      expect(find.text('Rincian Form Lembur'), findsOneWidget);
      expect(find.text('Lembur Hari Libur'), findsOneWidget);
      expect(find.text('Dukungan Operasional'), findsOneWidget);
      expect(find.text('Support Produksi Lini 2'), findsOneWidget);
      expect(find.text('Lampiran: surat_perintah.pdf'), findsOneWidget);
      expect(find.text('0/1 hari'), findsOneWidget);
      expect(find.text('U5SH2OPR6'), findsOneWidget);
    });

    testWidgets('Screen 2 & 3 support picking slots, Tambah Lagi, Preserving Back, Draf, and partial submit',
        (tester) async {
      await tester.pumpWidget(
        wrapWithScope(
          OvertimeDetailReviewScreen(
            employeeName: 'Budi Santoso',
            employeePosition: 'Staff IT & Sistem',
            startDate: DateTime(2026, 11, 11),
            endDate: DateTime(2026, 11, 12),
            overtimeType: 'Jam Lembur',
            reasonCategory: 'Lembur',
            reason: 'Support Migrasi Server Malam',
            initialSchedules: [
              OvertimeDaySchedule(date: DateTime(2026, 11, 11)),
              OvertimeDaySchedule(date: DateTime(2026, 11, 12)),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0/2 hari'), findsOneWidget);
      expect(find.byKey(const Key('overtime_day_card_0')), findsOneWidget);
      expect(find.byKey(const Key('overtime_day_card_1')), findsOneWidget);

      // Submit while 0 days configured shows error
      await tester.tap(find.byKey(const Key('overtime_submit_btn')));
      await tester.pumpAndSettle();
      expect(
        find.text('Atur jam lembur minimal pada 1 hari sebelum mengajukan.'),
        findsWidgets,
      );

      // Tap Day 1 card to open Screen 3 bottom sheet
      await tester.tap(find.byKey(const Key('overtime_day_card_0')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(OvertimeDayScheduleSheet),
          matching: find.text('Lembur'),
        ),
        findsOneWidget,
      );
      expect(find.text('KEHADIRAN AKTUAL'), findsOneWidget);
      expect(find.text('07:55 | 11 Nov'), findsOneWidget);
      expect(find.text('17:05 | 11 Nov'), findsOneWidget);
      expect(find.text('U5SH2OPR6\n[08:00 - 17:00]'), findsOneWidget);

      // Configure Overtime 1 (defaults: 17:00 -> 19:00 via time picker OK)
      await tester.ensureVisible(find.byKey(const Key('overtime_slot_0_start_time')));
      await tester.tap(find.byKey(const Key('overtime_slot_0_start_time')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('overtime_slot_0_end_time')));
      await tester.tap(find.byKey(const Key('overtime_slot_0_end_time')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Add second slot via Tambah Lagi and confirm overlap detection if identical times picked
      await tester.tap(find.byKey(const Key('overtime_add_slot_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Overtime 2'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('overtime_slot_1_start_time')));
      await tester.tap(find.byKey(const Key('overtime_slot_1_start_time')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('overtime_slot_1_end_time')));
      await tester.tap(find.byKey(const Key('overtime_slot_1_end_time')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('overtime_update_day_btn')));
      await tester.pumpAndSettle();
      expect(
        find.text('Overtime 1 dan Overtime 2 memiliki jam yang tumpang tindih.'),
        findsOneWidget,
      );

      // Remove overlapping Overtime 2 and save Day 1 with 17:00 - 19:00
      await tester.ensureVisible(find.byKey(const Key('overtime_slot_remove_1')));
      await tester.tap(find.byKey(const Key('overtime_slot_remove_1')));
      await tester.pumpAndSettle();
      expect(find.text('Overtime 2'), findsNothing);

      await tester.tap(find.byKey(const Key('overtime_update_day_btn')));
      await tester.pumpAndSettle();

      expect(find.text('1/2 hari'), findsOneWidget);
      expect(find.text('Mulai: 17:00 | Berakhir: 19:00'), findsOneWidget);
      expect(find.text('2.0 jam'), findsOneWidget);

      // Partial-day submit opens confirmation dialog
      await tester.tap(find.byKey(const Key('overtime_submit_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi Pengajuan'), findsOneWidget);
      await tester.tap(find.text('Ajukan 1 Hari'));
      await tester.pumpAndSettle();

      expect(mockRepo.submitFormCalled, isTrue);
      expect(mockRepo.lastSubmitReason, 'Support Migrasi Server Malam');
      expect(mockRepo.lastSubmitType, 'Jam Lembur');
      expect(mockRepo.lastSubmitCategory, 'Lembur');
      expect(mockRepo.lastSubmitEntries, hasLength(1));
      expect(mockRepo.lastSubmitEntries![0]['date'], '2026-11-11');
      expect(mockRepo.lastSubmitEntries![0]['end_date'], '2026-11-11');
      expect(mockRepo.lastSubmitEntries![0]['start_time'], '17:00');
      expect(mockRepo.lastSubmitEntries![0]['end_time'], '19:00');
    });

    testWidgets('Screen 2 blocks overlapping existing requests and deletes draft upon successful submit',
        (tester) async {
      final draftService = OvertimeDraftService();
      await draftService.saveDraft(
        4,
        OvertimeDraftModel(
          id: 'draft_resume_99',
          startDate: DateTime(2026, 11, 14),
          endDate: DateTime(2026, 11, 14),
          overtimeType: 'Lembur Setelah Shift',
          reasonCategory: 'Perbaikan / Maintenance',
          reason: 'Penggantian PLC Lini 4',
          daySchedules: [
            OvertimeDaySchedule(
              date: DateTime(2026, 11, 14),
              slots: [
                OvertimeSlotEntry(
                  startDate: DateTime(2026, 11, 14),
                  endDate: DateTime(2026, 11, 15),
                  startTime: const TimeOfDay(hour: 22, minute: 0),
                  endTime: const TimeOfDay(hour: 2, minute: 0),
                ),
              ],
            ),
          ],
          savedAt: DateTime(2026, 11, 11, 10, 0),
        ),
      );

      mockRepo.requestsData = [
        const OvertimeRequestModel(
          id_overtime_requests: 500,
          date: '2026-11-14',
          end_date: '2026-11-15',
          start_time: '23:00:00',
          end_time: '01:00:00',
          duration_hours: 2.0,
          reason: 'Lembur existing aktif',
          status: OvertimeStatus.pending,
        ),
      ];

      await tester.pumpWidget(wrapWithScope(const OvertimeScreen()));
      await tester.pumpAndSettle();

      // Draft card appears on OvertimeScreen
      expect(find.text('Draf Tersimpan di Perangkat'), findsOneWidget);
      expect(find.text('Penggantian PLC Lini 4'), findsOneWidget);

      // Tap Lanjutkan on draft card -> Form Lembur populated with draft
      await tester.tap(find.byKey(const ValueKey('overtime_draft_resume_draft_resume_99')));
      await tester.pumpAndSettle();
      expect(find.text('Form Lembur'), findsOneWidget);
      expect(find.text('Penggantian PLC Lini 4'), findsOneWidget);
      expect(find.text('Lembur Setelah Shift'), findsOneWidget);

      await tester.tap(find.byKey(const Key('overtime_next_step_btn')));
      await tester.pumpAndSettle();

      // Overnight label rendered on card
      expect(find.text('Mulai: 22:00 | Berakhir: 02:00 (+1 hr)'), findsOneWidget);

      // Overlap with existing active request blocks submission
      await tester.tap(find.byKey(const Key('overtime_submit_btn')));
      await tester.pumpAndSettle();
      expect(find.textContaining('tumpang tindih dengan pengajuan aktif'), findsWidgets);
      expect(mockRepo.submitFormCalled, isFalse);

      // Clear conflicting active request, invalidate, and retry submit
      mockRepo.requestsData = [];
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('overtime_submit_btn'))),
      );
      container.invalidate(myOvertimeListProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('overtime_submit_btn')));
      await tester.pumpAndSettle();

      expect(mockRepo.submitFormCalled, isTrue);
      expect(mockRepo.lastSubmitEntries![0]['date'], '2026-11-14');
      expect(mockRepo.lastSubmitEntries![0]['end_date'], '2026-11-15');
      expect(await draftService.loadDrafts(4), isEmpty);
    });

    testWidgets('OvertimeScreen deletes draft cleanly and opens Detail with cross-day schedule, metadata & attachment modal',
        (tester) async {
      final draftService = OvertimeDraftService();
      await draftService.saveDraft(
        4,
        OvertimeDraftModel(
          id: 'draft_del_1',
          startDate: DateTime(2026, 11, 20),
          endDate: DateTime(2026, 11, 20),
          overtimeType: 'Jam Lembur',
          reasonCategory: 'Lembur',
          reason: 'Draft untuk dihapus',
          daySchedules: [OvertimeDaySchedule(date: DateTime(2026, 11, 20))],
          savedAt: DateTime(2026, 11, 11, 11, 0),
        ),
      );

      mockRepo.requestsData = [
        const OvertimeRequestModel(
          id_overtime_requests: 301,
          request_number: 'OVR-202611-000301',
          date: '2026-11-11',
          end_date: '2026-11-12',
          start_time: '22:00:00',
          end_time: '02:00:00',
          duration_hours: 4.0,
          overtime_type: 'Lembur Hari Libur',
          reason_category: 'Dukungan Operasional',
          reason: 'Cutover sistem ERP lintas malam',
          attachment_url: 'http://localhost:8000/storage/1/overtimes/bukti.pdf',
          status: OvertimeStatus.pending,
        ),
      ];

      await tester.pumpWidget(wrapWithScope(const OvertimeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Draft untuk dihapus'), findsOneWidget);
      expect(find.text('OVR-202611-000301'), findsOneWidget);
      expect(find.text('11 Nov 2026'), findsOneWidget);
      expect(find.text('12 Nov 2026'), findsOneWidget);
      expect(find.text('Cutover sistem ERP lintas malam'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('overtime_draft_delete_draft_del_1')));
      await tester.pumpAndSettle();

      expect(find.text('Draft untuk dihapus'), findsNothing);
      expect(await draftService.loadDrafts(4), isEmpty);

      // Navigate into Detail Screen and verify cross-day & attachment preview modal
      await tester.tap(find.byKey(const Key('overtime_card_301')));
      await tester.pumpAndSettle();

      expect(find.text('Lembur Hari Libur'), findsOneWidget);
      expect(find.text('Dukungan Operasional'), findsOneWidget);
      expect(find.text('22:00 | 11 Nov'), findsOneWidget);
      expect(find.text('02:00 | 12 Nov'), findsOneWidget);
      expect(find.text('Durasi diajukan 4 jam 0 menit'), findsOneWidget);
      expect(find.byKey(const Key('overtime_detail_attachment_btn')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('overtime_detail_attachment_btn')));
      await tester.tap(find.byKey(const Key('overtime_detail_attachment_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Lampiran Pengajuan'), findsOneWidget);
      expect(find.text('bukti.pdf'), findsWidgets);
      expect(find.byKey(const Key('overtime_attachment_copy_btn')), findsOneWidget);
    });

    testWidgets('OvertimeDetailScreen displays rejected/cancelled banners cleanly without sticky action bar',
        (tester) async {
      const rejectedItem = OvertimeRequestModel(
        id_overtime_requests: 404,
        request_number: 'OVR-202611-000404',
        employee_name: 'Budi Santoso',
        employee_position: 'Staff IT & Sistem',
        date: '2026-11-11',
        end_date: '2026-11-11',
        start_time: '18:00:00',
        end_time: '20:00:00',
        duration_hours: 2.0,
        overtime_type: 'Jam Lembur',
        reason_category: 'Lembur',
        reason: 'Pengecekan log server',
        status: OvertimeStatus.rejected,
        rejected_reason: 'Kuota lembur departemen bulan ini sudah terpenuhi',
      );

      await tester.pumpWidget(
        wrapWithScope(const OvertimeDetailScreen(item: rejectedItem)),
      );
      await tester.pumpAndSettle();

      expect(find.text('OVR-202611-000404'), findsOneWidget);
      expect(find.text('Ditolak'), findsOneWidget);
      expect(
        find.text('Alasan penolakan: Kuota lembur departemen bulan ini sudah terpenuhi'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('overtime_detail_revise_btn')), findsNothing);
      expect(find.byKey(const Key('overtime_detail_cancel_btn')), findsNothing);
    });

    testWidgets('OvertimeDayScheduleSheet reset button clears configured day cleanly', (tester) async {
      final schedule = OvertimeDaySchedule(
        date: DateTime(2026, 11, 11),
        slots: [
          OvertimeSlotEntry(
            startDate: DateTime(2026, 11, 11),
            endDate: DateTime(2026, 11, 11),
            startTime: const TimeOfDay(hour: 18, minute: 0),
            endTime: const TimeOfDay(hour: 21, minute: 0),
          ),
        ],
      );

      List<OvertimeSlotEntry>? poppedResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    poppedResult = await showModalBottomSheet<List<OvertimeSlotEntry>>(
                      context: ctx,
                      isScrollControlled: true,
                      builder: (_) => OvertimeDayScheduleSheet(
                        employeeName: 'Budi Santoso',
                        daySchedule: schedule,
                        shiftName: 'U5SH2OPR6',
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('18:00'), findsOneWidget);
      expect(find.text('21:00'), findsOneWidget);
      expect(find.byKey(const Key('overtime_slot_reset_btn')), findsOneWidget);

      await tester.tap(find.byKey(const Key('overtime_slot_reset_btn')));
      await tester.pumpAndSettle();
      expect(find.text('HH:mm'), findsNWidgets(2));

      await tester.tap(find.byKey(const Key('overtime_update_day_btn')));
      await tester.pumpAndSettle();

      expect(poppedResult, isNotNull);
      expect(poppedResult!, hasLength(1));
      expect(poppedResult![0].isValid, isFalse);
    });

    test('OvertimeRequestModel parses nested consolidated items and date coverage helpers', () {
      final model = OvertimeRequestModel.fromMap({
        'id_overtime_requests': 24,
        'request_number': 'OVR-202611-000024',
        'date': '2026-11-02',
        'end_date': '2026-11-06',
        'start_time': '21:00:00',
        'end_time': '23:00:00',
        'duration_hours': 5.5,
        'reason': 'Support Produksi + Delivery',
        'status': 'pending',
        'items': [
          {
            'id_overtime_request_items': 101,
            'date': '2026-11-02',
            'end_date': '2026-11-02',
            'start_time': '21:00:00',
            'end_time': '23:00:00',
            'duration_hours': 2.0,
            'actual_clock_in': '20:49:00',
            'actual_clock_out': '08:07:00',
          },
          {
            'id_overtime_request_items': 102,
            'date': '2026-11-06',
            'end_date': '2026-11-06',
            'start_time': '17:00:00',
            'end_time': '20:30:00',
            'duration_hours': 3.5,
            'actual_clock_in': '07:55:00',
            'actual_clock_out': '17:02:00',
          },
        ],
      });

      expect(model.items, hasLength(2));
      expect(model.effectiveItems, hasLength(2));
      expect(model.effectiveEndDate, '2026-11-06');
      expect(model.distinctDaysCount, 2);
      expect(model.coversIsoDate('2026-11-02'), isTrue);
      expect(model.coversIsoDate('2026-11-06'), isTrue);
      expect(model.coversIsoDate('2026-11-04'), isFalse);

      const nullItemsModel = OvertimeRequestModel(
        id_overtime_requests: 25,
        date: '2026-11-05',
        start_time: '17:00:00',
        end_time: '19:00:00',
        duration_hours: 2.0,
        reason: 'Null items defensive check',
        status: OvertimeStatus.pending,
        items: null,
      );
      expect(nullItemsModel.effectiveItems, hasLength(1));
      expect(nullItemsModel.effectiveEndDate, '2026-11-05');
      expect(nullItemsModel.distinctDaysCount, 1);
      expect(nullItemsModel.coversIsoDate('2026-11-05'), isTrue);
      expect(nullItemsModel.toMap()['items'], isEmpty);
    });

    testWidgets('Consolidated multi-day request shows 1 card in list and unified schedule box in detail',
        (tester) async {
      mockRepo.requestsData = [
        const OvertimeRequestModel(
          id_overtime_requests: 647239,
          request_number: 'OVR-202611-647239',
          employee_name: 'Budi Santoso',
          employee_position: 'Staff IT & Sistem',
          shift_name: 'U5SH3OPR6',
          shift_start_time: '23:00:00',
          shift_end_time: '07:00:00',
          date: '2026-11-02',
          end_date: '2026-11-06',
          start_time: '21:00:00',
          end_time: '20:30:00',
          duration_hours: 7.5,
          overtime_type: 'Jam Lembur',
          reason_category: 'Lembur',
          reason: 'Support Produksi + Delivery',
          status: OvertimeStatus.pending,
          created_at: '2026-11-06T09:00:00Z',
          items: [
            OvertimeRequestItemModel(
              id_overtime_request_items: 1,
              date: '2026-11-02',
              end_date: '2026-11-02',
              start_time: '21:00:00',
              end_time: '23:00:00',
              duration_hours: 2.0,
              actual_clock_in: '20:49:00',
              actual_clock_out: '08:07:00',
            ),
            OvertimeRequestItemModel(
              id_overtime_request_items: 2,
              date: '2026-11-02',
              end_date: '2026-11-03',
              start_time: '23:30:00',
              end_time: '01:30:00',
              duration_hours: 2.0,
              actual_clock_in: '20:49:00',
              actual_clock_out: '08:07:00',
            ),
            OvertimeRequestItemModel(
              id_overtime_request_items: 3,
              date: '2026-11-06',
              end_date: '2026-11-06',
              start_time: '17:00:00',
              end_time: '20:30:00',
              duration_hours: 3.5,
              actual_clock_in: '07:55:00',
              actual_clock_out: '17:05:00',
            ),
          ],
        ),
      ];

      await tester.pumpWidget(wrapWithScope(const OvertimeScreen()));
      await tester.pumpAndSettle();

      // Single consolidated card in list
      expect(find.byKey(const Key('overtime_card_647239')), findsOneWidget);
      expect(find.text('OVR-202611-647239'), findsOneWidget);
      expect(find.text('2 Nov 2026'), findsOneWidget);
      expect(find.text('6 Nov 2026'), findsOneWidget);
      expect(find.text('2 hari • 3 sesi • 7.5 jam'), findsOneWidget);

      await tester.tap(find.byKey(const Key('overtime_card_647239')));
      await tester.pumpAndSettle();

      // Single consolidated DETAIL PENGAJUAN LEMBUR box containing both days + all 3 slots
      expect(find.byKey(const Key('overtime_detail_schedule_box')), findsOneWidget);
      expect(find.text('2 Nov 2026'), findsWidgets);
      expect(find.text('6 Nov 2026'), findsWidgets);
      expect(find.text('20:49 | 2 Nov'), findsOneWidget);
      expect(find.text('08:07 | 3 Nov'), findsOneWidget);
      expect(find.text('07:55 | 6 Nov'), findsOneWidget);
      expect(find.text('17:05 | 6 Nov'), findsOneWidget);
      expect(find.text('21:00 | 2 Nov'), findsOneWidget);
      expect(find.text('23:00 | 2 Nov'), findsOneWidget);
      expect(find.text('23:30 | 2 Nov'), findsOneWidget);
      expect(find.text('01:30 | 3 Nov'), findsOneWidget);
      expect(find.text('17:00 | 6 Nov'), findsOneWidget);
      expect(find.text('20:30 | 6 Nov'), findsOneWidget);
      expect(find.text('Overtime 1'), findsNWidgets(2));
      expect(find.text('Overtime 2'), findsOneWidget);
      expect(find.text('Durasi diajukan 2 jam 0 menit'), findsNWidgets(2));
      expect(find.text('Durasi diajukan 3 jam 30 menit'), findsOneWidget);
      expect(find.text('Total Diajukan (2 hari, 3 sesi)'), findsOneWidget);
      expect(find.text('7 jam 30 menit'), findsOneWidget);

      // Revising a multi-entry request preserves Tanggal Mulai / Berakhir & sends entries payload
      await tester.tap(find.byKey(const Key('overtime_detail_revise_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Revisi Lembur'), findsOneWidget);
      expect(find.text('Tanggal Mulai'), findsOneWidget);
      expect(find.text('Tanggal Berakhir'), findsOneWidget);

      await tester.tap(find.byKey(const Key('overtime_next_step_btn')));
      await tester.pumpAndSettle();

      expect(find.text('2/5 hari'), findsOneWidget);

      await tester.tap(find.byKey(const Key('overtime_submit_btn')));
      await tester.pumpAndSettle();
      // 2 of 5 days configured in Nov 2..Nov 6 confirmation
      await tester.tap(find.text('Ajukan 2 Hari'));
      await tester.pumpAndSettle();

      expect(mockRepo.updateCalled, isTrue);
      expect(mockRepo.lastUpdatedId, 647239);
      expect(mockRepo.lastUpdatedEntries, hasLength(3));
      expect(mockRepo.lastUpdatedEntries![0]['date'], '2026-11-02');
      expect(mockRepo.lastUpdatedEntries![2]['date'], '2026-11-06');
    });
  });
}
