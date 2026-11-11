import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_app/core/constants/app_dimensions.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/features/attendance/data/attendance_repository.dart';
import 'package:mobile_app/features/attendance/presentation/attendance_screen.dart';
import 'package:mobile_app/features/attendance/presentation/history_screen.dart';
import 'package:mobile_app/features/attendance/provider/attendance_provider.dart';
import 'package:mobile_app/features/auth/data/auth_repository.dart';
import 'package:mobile_app/features/auth/provider/auth_provider.dart';
import 'package:mobile_app/features/leave/data/leave_models.dart';
import 'package:mobile_app/features/leave/data/leave_repository.dart';
import 'package:mobile_app/features/leave/presentation/apply_leave_screen.dart';
import 'package:mobile_app/features/leave/presentation/leave_detail_screen.dart';
import 'package:mobile_app/features/leave/presentation/leave_screen.dart';
import 'package:mobile_app/features/leave/provider/leave_provider.dart';
import 'package:mobile_app/features/notification/data/notification_model.dart';
import 'package:mobile_app/features/notification/data/notification_repository.dart';
import 'package:mobile_app/features/notification/presentation/notification_sheet.dart';
import 'package:mobile_app/features/notification/provider/notification_provider.dart';
import 'package:mobile_app/features/overtime/data/overtime_draft_service.dart';
import 'package:mobile_app/features/overtime/data/overtime_models.dart';
import 'package:mobile_app/features/overtime/data/overtime_repository.dart';
import 'package:mobile_app/features/overtime/presentation/apply_overtime_form_screen.dart';
import 'package:mobile_app/features/overtime/presentation/overtime_day_schedule_sheet.dart';
import 'package:mobile_app/features/overtime/presentation/overtime_detail_review_screen.dart';
import 'package:mobile_app/features/overtime/presentation/overtime_detail_screen.dart';
import 'package:mobile_app/features/overtime/presentation/overtime_screen.dart';
import 'package:mobile_app/features/overtime/provider/overtime_provider.dart';
import 'package:mobile_app/features/payroll/data/payroll_models.dart';
import 'package:mobile_app/features/payroll/data/payroll_repository.dart';
import 'package:mobile_app/features/payroll/presentation/payroll_history_screen.dart';
import 'package:mobile_app/features/payroll/presentation/payroll_slip_detail_screen.dart';
import 'package:mobile_app/features/payroll/provider/payroll_provider.dart';
import 'package:mobile_app/features/profile/presentation/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DummyApiClient extends Fake implements ApiClient {}

class _MockAuthRepo extends AuthRepository {
  _MockAuthRepo() : super(_DummyApiClient());

  @override
  Future<void> logout() async {}

  @override
  Future<Map<String, dynamic>> getProfile() async => {};
}

class _MockAttendanceRepo extends AttendanceRepository {
  _MockAttendanceRepo() : super(_DummyApiClient());

  @override
  Future<Map<String, dynamic>> getTodayAttendance() async => {
        'date': '2026-11-11',
        'shift': {
          'name': 'Shift Reguler Operasional',
          'start_time': '08:00',
          'end_time': '17:00',
          'late_tolerance_minutes': 15,
        },
        'attendance': {
          'clock_in_time': '07:58',
          'clock_out_time': null,
          'status': 'on_time',
        },
      };

  @override
  Future<List<dynamic>> getAttendanceHistory({int? month, int? year}) async => [
        {
          'date': '2026-11-10',
          'clock_in_time': '08:00',
          'clock_out_time': '17:00',
          'status': 'on_time',
        },
        {
          'date': '2026-11-09',
          'clock_in_time': '08:25',
          'clock_out_time': '17:10',
          'status': 'late',
          'late_duration_minutes': 10,
        },
      ];

  @override
  Future<List<dynamic>> getAttendanceHistoryRange({
    required String startDate,
    required String endDate,
    int perPage = 100,
  }) async =>
      [
        {
          'date': '2026-11-10',
          'clock_in_time': '08:00',
          'clock_out_time': '17:00',
          'status': 'on_time',
        },
        {
          'date': '2026-11-11',
          'clock_in_time': '07:58',
          'clock_out_time': null,
          'status': 'on_time',
        },
      ];
}

class _MockLeaveRepo extends LeaveRepository {
  _MockLeaveRepo() : super(_DummyApiClient());

  @override
  Future<List<LeaveTypeModel>> getLeaveTypes() async => [
        const LeaveTypeModel(
          id_leave_types: 1,
          name: 'Cuti Tahunan',
          quota_days: 12,
          is_paid: true,
        ),
      ];

  @override
  Future<List<LeaveBalanceModel>> getLeaveBalance() async => [
        const LeaveBalanceModel(
          id_leave_types: 1,
          name: 'Cuti Tahunan',
          total_quota: 12,
          used_days: 2,
          remaining_days: 10,
        ),
      ];

  @override
  Future<List<LeaveRequestModel>> getMyRequests({String? status, int? page}) async => [
        const LeaveRequestModel(
          id_leave_requests: 1,
          leave_type: 'Cuti Tahunan',
          id_leave_types: 1,
          start_date: '2026-11-15',
          end_date: '2026-11-17',
          total_days: 3,
          reason: 'Keperluan keluarga di luar kota',
          status: LeaveStatus.rejected,
          rejection_note: 'Jadwal bersamaan dengan audit internal',
        ),
      ];

  @override
  Future<List<LeaveRequestModel>> getApprovals({String? status, int? page}) async => [
        const LeaveRequestModel(
          id_leave_requests: 55,
          id_employees: 4,
          employee_name: 'Budi Santoso',
          employee_nik: 'EMP-004',
          employee_position: 'Staff IT & Sistem Operasional',
          leave_type: 'Cuti Tahunan',
          start_date: '2026-11-18',
          end_date: '2026-11-19',
          total_days: 2,
          reason: 'Keperluan mendesak keluarga',
          status: LeaveStatus.pending,
        ),
      ];
}

class _MockOvertimeRepo extends OvertimeRepository {
  _MockOvertimeRepo() : super(_DummyApiClient());

  @override
  Future<List<OvertimeRequestModel>> getMyRequests({
    String? status,
    String? month,
    int? page,
  }) async =>
      [
        const OvertimeRequestModel(
          id_overtime_requests: 10,
          date: '2026-11-11',
          end_date: '2026-11-12',
          start_time: '22:00:00',
          end_time: '01:00:00',
          duration_hours: 3.0,
          overtime_type: 'Lembur Hari Libur',
          reason_category: 'Dukungan Operasional',
          reason: 'Deploy rilis sistem keamanan dan migrasi server',
          attachment_url: 'http://localhost:8000/storage/1/overtimes/bukti.pdf',
          status: OvertimeStatus.pending,
        ),
      ];

  @override
  Future<List<OvertimeRequestModel>> getApprovals({
    String? status,
    String? date,
    int? page,
  }) async =>
      [
        const OvertimeRequestModel(
          id_overtime_requests: 88,
          id_employees: 4,
          employee_name: 'Budi Santoso',
          employee_nik: 'EMP-004',
          employee_position: 'Staff IT & Sistem Operasional',
          date: '2026-11-11',
          end_date: '2026-11-12',
          start_time: '22:00:00',
          end_time: '00:30:00',
          duration_hours: 2.5,
          overtime_type: 'Jam Lembur',
          reason_category: 'Perbaikan / Maintenance',
          reason: 'Pemeliharaan infrastruktur jaringan kantor pusat',
          attachment_url: 'http://localhost:8000/storage/1/overtimes/sp.pdf',
          status: OvertimeStatus.pending,
        ),
      ];

  @override
  Future<Map<String, dynamic>> submitOvertimeForm({
    required List<Map<String, dynamic>> entries,
    required String reason,
    String? overtimeType,
    String? reasonCategory,
    String? attachmentPath,
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async =>
      {'success': true, 'message': 'OK'};
}

class _MockPayrollRepo extends PayrollRepository {
  _MockPayrollRepo() : super(_DummyApiClient());

  @override
  Future<List<PayrollSlipModel>> getMySlips() async => [sampleSlip];

  @override
  Future<String> downloadSlipPdf(int id) async => '/tmp/slip.pdf';
}

class _MockNotificationRepo extends NotificationRepository {
  _MockNotificationRepo() : super(_DummyApiClient());

  @override
  Future<List<NotificationModel>> getNotifications({int perPage = 30}) async => [
        NotificationModel(
          idNotifications: 1,
          idCompanies: 1,
          idUsers: 1,
          type: 'leave',
          title: 'Pengajuan Cuti Tahunan Disetujui',
          message: 'Permohonan cuti tanggal 18-19 Nov telah disetujui oleh atasan.',
          isRead: false,
          createdAt: '2026-11-11T08:00:00Z',
        ),
        NotificationModel(
          idNotifications: 2,
          idCompanies: 1,
          idUsers: 1,
          type: 'payroll',
          title: 'Slip Gaji Oktober Tersedia',
          message: 'Slip gaji periode Oktober 2026 telah diterbitkan.',
          isRead: true,
          createdAt: '2026-11-10T09:00:00Z',
        ),
      ];
}

final sampleSlip = PayrollSlipModel(
  id_payroll_slips: 1,
  id_payroll_periods: 1,
  id_employees: 1,
  basic_salary: 7500000,
  allowance_fixed: 1500000,
  overtime_pay: 500000,
  deduction_late: 0,
  deduction_absence: 0,
  deduction_other: 150000,
  net_salary: 9350000,
  period_name: 'Oktober 2026',
  payment_date: '2026-10-25',
  status: PayrollStatus.paid,
);

Finder _borderedContainersInside(Finder cardFinder) {
  return find.descendant(
    of: cardFinder,
    matching: find.byWidgetPredicate((widget) {
      if (widget is Container && widget.decoration is BoxDecoration) {
        final border = (widget.decoration! as BoxDecoration).border;
        if (border is Border) {
          return border.top != BorderSide.none &&
              border.bottom != BorderSide.none &&
              border.left != BorderSide.none &&
              border.right != BorderSide.none;
        }
        return border != null;
      }
      return false;
    }),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final employeeUser = {
    'id_users': 1,
    'name': 'Budi Pratama',
    'email': 'budi@spindo.co.id',
    'role': 'employee',
    'company': {'id_companies': 1, 'name': 'PT SPINDO'},
    'employee': {
      'id_employees': 1,
      'nik': 'EMP-001',
      'phone': '08123456789',
      'gender': 'male',
      'employment_status': 'permanent',
      'hire_date': '2023-01-15',
      'department': {'id_departments': 1, 'name': 'Operasional IT'},
      'job_position': {'id_job_positions': 1, 'name': 'System Engineer'},
      'branch': {'id_branches': 1, 'name': 'Kantor Pusat'},
    },
  };

  final managerUser = {
    'id_users': 3,
    'name': 'Norman Alaik',
    'email': 'norman@spindo.co.id',
    'role': 'manager',
    'company': {'id_companies': 1, 'name': 'PT SPINDO'},
    'employee': {
      'id_employees': 3,
      'nik': 'EMP-003',
      'job_position_name': 'Operational Manager',
      'department': {'id_departments': 1, 'name': 'Operasional IT'},
      'branch': {'id_branches': 1, 'name': 'Kantor Pusat'},
    },
  };

  void assertNoExceptions(WidgetTester tester) {
    expect(tester.takeException(), isNull);
  }

  Future<void> pumpViewport(
    WidgetTester tester, {
    required Size size,
    required Widget child,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final prevOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = (details) {
      errors.add(details);
      prevOnError?.call(details);
    };
    try {
      await tester.pumpWidget(
        MediaQuery(
          key: ObjectKey(child),
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      );
      await tester.pumpAndSettle();
    } finally {
      FlutterError.onError = prevOnError;
    }
    if (errors.isNotEmpty) {
      fail(errors.map((e) => e.toString()).join('\n---\n'));
    }
    assertNoExceptions(tester);
  }

  testWidgets('AttendanceScreen & HistoryScreen reflow cleanly without nested cards',
      (tester) async {
    final mockAuth = _MockAuthRepo();
    final mockAttRepo = _MockAttendanceRepo();

    Widget buildAttendance() => ProviderScope(
          key: const ValueKey('attendance_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: employeeUser);
              return n;
            }),
            attendanceRepositoryProvider.overrideWithValue(mockAttRepo),
          ],
          child: const MaterialApp(home: AttendanceScreen()),
        );

    // Narrow 300px: stacks Masuk / Pulang vertically, zero overflow, zero fake distance
    await pumpViewport(tester, size: const Size(300, 900), child: buildAttendance());
    expect(tester.takeException(), isNull);
    expect(find.text('Valid (18m / 50m)'), findsNothing);
    expect(find.text('Verifikasi GPS aktif'), findsOneWidget);

    final narrowIn = tester.getTopLeft(find.text('Masuk (Clock In)'));
    final narrowOut = tester.getTopLeft(find.text('Pulang (Clock Out)'));
    expect(narrowOut.dy, greaterThan(narrowIn.dy + 20));

    // Standard 375px: side-by-side Masuk / Pulang & zero inner bordered containers in cards
    await pumpViewport(tester, size: const Size(375, 900), child: buildAttendance());
    expect(tester.takeException(), isNull);
    final phoneIn = tester.getTopLeft(find.text('Masuk (Clock In)'));
    final phoneOut = tester.getTopLeft(find.text('Pulang (Clock Out)'));
    expect((phoneOut.dy - phoneIn.dy).abs(), lessThan(4.0));

    final shiftCard = find.ancestor(
      of: find.text('Shift Reguler Operasional'),
      matching: find.byType(Container),
    ).first;
    expect(_borderedContainersInside(shiftCard), findsNothing);

    final statusCard = find.ancestor(
      of: find.text('Masuk (Clock In)'),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).border != null,
      ),
    ).first;
    expect(_borderedContainersInside(statusCard), findsNothing);

    // 1.3x OS textScale at 375px: stacks Masuk / Pulang vertically cleanly
    await pumpViewport(
      tester,
      size: const Size(375, 900),
      textScale: 1.3,
      child: buildAttendance(),
    );
    expect(tester.takeException(), isNull);
    final scaledIn = tester.getTopLeft(find.text('Masuk (Clock In)'));
    final scaledOut = tester.getTopLeft(find.text('Pulang (Clock Out)'));
    expect(scaledOut.dy, greaterThan(scaledIn.dy + 20));

    // Wide 640px & HistoryScreen check
    await pumpViewport(tester, size: const Size(640, 900), child: buildAttendance());
    expect(tester.takeException(), isNull);

    Widget buildHistory() => ProviderScope(
          key: const ValueKey('history_scope'),
          overrides: [attendanceRepositoryProvider.overrideWithValue(mockAttRepo)],
          child: const MaterialApp(home: HistoryScreen()),
        );
    for (final s in [const Size(300, 900), const Size(375, 900), const Size(640, 900)]) {
      await pumpViewport(tester, size: s, child: buildHistory());
      expect(tester.takeException(), isNull);
    }
    await pumpViewport(
      tester,
      size: const Size(375, 900),
      textScale: 1.3,
      child: buildHistory(),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ProfileScreen flattens header card and reflows across breakpoints',
      (tester) async {
    final mockAuth = _MockAuthRepo();

    Widget buildProfile() => ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: employeeUser);
              return n;
            }),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        );

    // 300px: removes Tenant Organisasi/Mulai Bekerja footer and stacks _buildInfoTile rows cleanly
    await pumpViewport(tester, size: const Size(300, 900), child: buildProfile());
    expect(tester.takeException(), isNull);
    expect(find.text('Tenant Organisasi'), findsNothing);
    expect(find.text('Mulai Bekerja'), findsNothing);
    expect(find.text('Radius 50m Aktif'), findsNothing);
    expect(find.text('Verifikasi Lokasi Aktif'), findsOneWidget);

    final narrowBranchLabel = tester.getTopLeft(find.text('Kantor Cabang'));
    final narrowBranchVal = tester.getTopLeft(find.text('Kantor Pusat'));
    expect(narrowBranchVal.dy, greaterThan(narrowBranchLabel.dy + 12));

    // 375px: side-by-side _buildInfoTile rows and zero inner borders inside header card
    await pumpViewport(tester, size: const Size(375, 900), child: buildProfile());
    expect(tester.takeException(), isNull);
    final phoneBranchLabel = tester.getTopLeft(find.text('Kantor Cabang'));
    final phoneBranchVal = tester.getTopLeft(find.text('Kantor Pusat'));
    expect((phoneBranchVal.dy - phoneBranchLabel.dy).abs(), lessThan(4.0));

    final profileHeaderCard = find.ancestor(
      of: find.text('Budi Pratama'),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).border != null,
      ),
    ).first;
    expect(_borderedContainersInside(profileHeaderCard), findsNothing);

    await pumpViewport(
      tester,
      size: const Size(375, 900),
      textScale: 1.3,
      child: buildProfile(),
    );
    expect(tester.takeException(), isNull);

    await pumpViewport(tester, size: const Size(640, 900), child: buildProfile());
    expect(tester.takeException(), isNull);
  });

  testWidgets('LeaveScreen, ApplyLeaveScreen & OvertimeScreen reflow & flatten nested cards',
      (tester) async {
    final mockAuth = _MockAuthRepo();
    final mockLeaveRepo = _MockLeaveRepo();
    final mockOvertimeRepo = _MockOvertimeRepo();

    Widget buildLeaveManager() => ProviderScope(
          key: const ValueKey('leave_manager_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: managerUser);
              return n;
            }),
            leaveRepositoryProvider.overrideWithValue(mockLeaveRepo),
          ],
          child: const MaterialApp(home: LeaveScreen()),
        );

    // LeaveScreen at 300px & 1.3x: minimal card stacks dates vertically without inline action buttons or nested borders
    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildLeaveManager(),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Tolak'), findsNothing);
    expect(find.text('Setujui'), findsNothing);
    final mgrLeaveStartPos = tester.getTopLeft(find.text('Tanggal Mulai'));
    final mgrLeaveEndPos = tester.getTopLeft(find.text('Tanggal Berakhir'));
    expect(mgrLeaveEndPos.dy, greaterThan(mgrLeaveStartPos.dy + 16));

    final leaveApprovalCard = find.byKey(const Key('leave_card_55'));
    expect(leaveApprovalCard, findsOneWidget);
    expect(_borderedContainersInside(leaveApprovalCard), findsNothing);

    await pumpViewport(
      tester,
      size: const Size(375, 900),
      textScale: 1.3,
      child: buildLeaveManager(),
    );
    expect(tester.takeException(), isNull);

    await pumpViewport(tester, size: const Size(640, 900), child: buildLeaveManager());
    expect(tester.takeException(), isNull);

    // ApplyLeaveScreen: flat single surface without card wrappers; reflows date & attachment controls cleanly
    Widget buildApplyLeave() => ProviderScope(
          key: const ValueKey('apply_leave_scope'),
          overrides: [leaveRepositoryProvider.overrideWithValue(mockLeaveRepo)],
          child: const MaterialApp(home: ApplyLeaveScreen()),
        );

    await pumpViewport(tester, size: const Size(300, 900), child: buildApplyLeave());
    expect(tester.takeException(), isNull);
    expect(_borderedContainersInside(find.byType(Form)), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('leave_submit_btn'))).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );
    expect(find.text('Foto JPG atau PNG, maks. 4 MB'), findsOneWidget);
    final narrowStart = tester.getTopLeft(find.text('Tanggal Mulai'));
    final narrowEnd = tester.getTopLeft(find.text('Tanggal Selesai'));
    expect(narrowEnd.dy, greaterThan(narrowStart.dy + 20));
    final narrowCamera = tester.getTopLeft(find.text('Kamera'));
    final narrowFile = tester.getTopLeft(find.text('Galeri'));
    expect(narrowFile.dy, greaterThan(narrowCamera.dy + 20));

    await pumpViewport(tester, size: const Size(375, 900), child: buildApplyLeave());
    expect(tester.takeException(), isNull);
    expect(_borderedContainersInside(find.byType(Form)), findsNothing);
    final phoneStart = tester.getTopLeft(find.text('Tanggal Mulai'));
    final phoneEnd = tester.getTopLeft(find.text('Tanggal Selesai'));
    expect((phoneEnd.dy - phoneStart.dy).abs(), lessThan(4.0));
    final phoneCamera = tester.getTopLeft(find.text('Kamera'));
    final phoneFile = tester.getTopLeft(find.text('Galeri'));
    expect((phoneFile.dy - phoneCamera.dy).abs(), lessThan(4.0));

    await pumpViewport(
      tester,
      size: const Size(375, 900),
      textScale: 1.3,
      child: buildApplyLeave(),
    );
    expect(tester.takeException(), isNull);

    // Open leave type dropdown at 300px & 1.3x textScale to ensure 2-line items have zero overflow
    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildApplyLeave(),
    );
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Sisa 10 dari 12 hari'), findsOneWidget);
    await tester.tap(find.text('Cuti Tahunan').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // OvertimeScreen (Manager + Employee)
    Widget buildOvertimeManager() => ProviderScope(
          key: const ValueKey('overtime_manager_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: managerUser);
              return n;
            }),
            overtimeRepositoryProvider.overrideWithValue(mockOvertimeRepo),
          ],
          child: const MaterialApp(home: OvertimeScreen()),
        );

    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildOvertimeManager(),
    );
    expect(tester.takeException(), isNull);
    final mgrStartPos = tester.getTopLeft(find.text('Tanggal Mulai'));
    final mgrEndPos = tester.getTopLeft(find.text('Tanggal Berakhir'));
    expect(mgrEndPos.dy, greaterThan(mgrStartPos.dy + 16));

    final overtimeApprovalCard = find.ancestor(
      of: find.text('Budi Santoso'),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).border != null,
      ),
    ).first;
    expect(_borderedContainersInside(overtimeApprovalCard), findsNothing);

    await pumpViewport(
      tester,
      size: const Size(375, 900),
      textScale: 1.3,
      child: buildOvertimeManager(),
    );
    expect(tester.takeException(), isNull);

    await pumpViewport(tester, size: const Size(640, 900), child: buildOvertimeManager());
    expect(tester.takeException(), isNull);

    // Employee Views (LeaveScreen + OvertimeScreen)
    Widget buildLeaveEmployee() => ProviderScope(
          key: const ValueKey('leave_emp_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: employeeUser);
              return n;
            }),
            leaveRepositoryProvider.overrideWithValue(mockLeaveRepo),
          ],
          child: const MaterialApp(home: LeaveScreen()),
        );

    for (final s in [const Size(300, 900), const Size(375, 900), const Size(640, 900)]) {
      await pumpViewport(tester, size: s, child: buildLeaveEmployee());
      expect(tester.takeException(), isNull);
    }
    expect(find.textContaining('hari/tahun'), findsNothing);
    expect(find.textContaining('Periode '), findsNothing);
    await pumpViewport(
      tester,
      size: const Size(375, 900),
      textScale: 1.3,
      child: buildLeaveEmployee(),
    );
    expect(tester.takeException(), isNull);
    final leaveEmpCard = find.byKey(const Key('leave_card_1'));
    expect(leaveEmpCard, findsOneWidget);
    expect(_borderedContainersInside(leaveEmpCard), findsNothing);

    Widget buildOvertimeEmployee() => ProviderScope(
          key: const ValueKey('overtime_emp_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: employeeUser);
              return n;
            }),
            overtimeRepositoryProvider.overrideWithValue(mockOvertimeRepo),
          ],
          child: const MaterialApp(home: OvertimeScreen()),
        );

    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildOvertimeEmployee(),
    );
    expect(tester.takeException(), isNull);
    final otStartPos = tester.getTopLeft(find.text('Tanggal Mulai'));
    final otEndPos = tester.getTopLeft(find.text('Tanggal Berakhir'));
    expect(otEndPos.dy, greaterThan(otStartPos.dy + 16));
    final overtimeEmpCard = find.ancestor(
      of: find.text('Deploy rilis sistem keamanan dan migrasi server'),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).border != null,
      ),
    ).first;
    expect(_borderedContainersInside(overtimeEmpCard), findsNothing);

    await pumpViewport(
      tester,
      size: const Size(375, 900),
      textScale: 1.3,
      child: buildOvertimeEmployee(),
    );
    expect(tester.takeException(), isNull);

    await pumpViewport(tester, size: const Size(640, 900), child: buildOvertimeEmployee());
    expect(tester.takeException(), isNull);
  });

  testWidgets('OvertimeDetailScreen (Employee & Manager) reflows cleanly without nested borders',
      (tester) async {
    final mockAuth = _MockAuthRepo();
    final mockAttRepo = _MockAttendanceRepo();
    final mockOvertimeRepo = _MockOvertimeRepo();

    const detailItem = OvertimeRequestModel(
      id_overtime_requests: 647239,
      request_number: 'OVR-202611-647239',
      id_employees: 4,
      employee_name: 'Ricky Satria',
      employee_position: 'Opr. Loading Gd 13',
      shift_name: 'U5SH3OPR6',
      shift_start_time: '23:00:00',
      shift_end_time: '07:00:00',
      actual_clock_in: '20:49:00',
      actual_clock_out: '08:07:00',
      date: '2026-11-02',
      end_date: '2026-11-06',
      start_time: '21:00:00',
      end_time: '23:00:00',
      duration_hours: 2.0,
      overtime_type: 'Jam Lembur',
      reason_category: 'Lembur',
      reason: 'Support Produksi + Delivery',
      attachment_url: 'http://localhost:8000/storage/4/overtimes/bukti.pdf',
      status: OvertimeStatus.pending,
      created_at: '2026-11-06T09:13:00Z',
    );

    Widget buildEmployeeDetail() => ProviderScope(
          key: const ValueKey('ot_detail_emp_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: employeeUser);
              return n;
            }),
            overtimeRepositoryProvider.overrideWithValue(mockOvertimeRepo),
            attendanceRepositoryProvider.overrideWithValue(mockAttRepo),
          ],
          child: const MaterialApp(
            home: OvertimeDetailScreen(item: detailItem, isApprovalView: false),
          ),
        );

    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildEmployeeDetail(),
    );
    expect(tester.takeException(), isNull);
    final revPos300 = tester.getTopLeft(find.byKey(const Key('overtime_detail_revise_btn')));
    final cancelPos300 = tester.getTopLeft(find.byKey(const Key('overtime_detail_cancel_btn')));
    expect(cancelPos300.dy, greaterThan(revPos300.dy + 20));
    expect(
      tester.getSize(find.byKey(const Key('overtime_detail_cancel_btn'))).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );
    expect(
      _borderedContainersInside(find.byKey(const Key('overtime_detail_schedule_box'))),
      findsNothing,
    );

    await pumpViewport(tester, size: const Size(375, 900), child: buildEmployeeDetail());
    expect(tester.takeException(), isNull);
    final revPos375 = tester.getTopLeft(find.byKey(const Key('overtime_detail_revise_btn')));
    final cancelPos375 = tester.getTopLeft(find.byKey(const Key('overtime_detail_cancel_btn')));
    expect((cancelPos375.dy - revPos375.dy).abs(), lessThan(4.0));

    await pumpViewport(tester, size: const Size(640, 900), child: buildEmployeeDetail());
    expect(tester.takeException(), isNull);

    Widget buildManagerDetail() => ProviderScope(
          key: const ValueKey('ot_detail_mgr_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: managerUser);
              return n;
            }),
            overtimeRepositoryProvider.overrideWithValue(mockOvertimeRepo),
            attendanceRepositoryProvider.overrideWithValue(mockAttRepo),
          ],
          child: const MaterialApp(
            home: OvertimeDetailScreen(item: detailItem, isApprovalView: true),
          ),
        );

    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildManagerDetail(),
    );
    expect(tester.takeException(), isNull);
    final appPos300 = tester.getTopLeft(find.byKey(const Key('overtime_detail_approve_btn')));
    final rejPos300 = tester.getTopLeft(find.byKey(const Key('overtime_detail_reject_btn')));
    expect(rejPos300.dy, greaterThan(appPos300.dy + 20));
    expect(
      tester.getSize(find.byKey(const Key('overtime_detail_approve_btn'))).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );

    await pumpViewport(tester, size: const Size(375, 900), child: buildManagerDetail());
    expect(tester.takeException(), isNull);
    final appPos375 = tester.getTopLeft(find.byKey(const Key('overtime_detail_approve_btn')));
    final rejPos375 = tester.getTopLeft(find.byKey(const Key('overtime_detail_reject_btn')));
    expect((rejPos375.dy - appPos375.dy).abs(), lessThan(4.0));

    await pumpViewport(tester, size: const Size(640, 900), child: buildManagerDetail());
    expect(tester.takeException(), isNull);
  });

  testWidgets('LeaveDetailScreen (Employee & Manager) reflows cleanly without nested borders',
      (tester) async {
    final mockAuth = _MockAuthRepo();
    final mockLeaveRepo = _MockLeaveRepo();

    const rejectedDetail = LeaveRequestModel(
      id_leave_requests: 647301,
      request_number: 'LVR-202611-647301',
      id_employees: 4,
      employee_name: 'Budi Pratama',
      employee_position: 'System Engineer',
      leave_type: 'Cuti Tahunan',
      is_paid: true,
      start_date: '2026-11-15',
      end_date: '2026-11-17',
      total_days: 3,
      reason: 'Keperluan keluarga di luar kota',
      attachment_url: 'http://localhost:8000/storage/4/leaves/surat_cuti.pdf',
      status: LeaveStatus.rejected,
      approver_name: 'Norman Alaik',
      rejection_note: 'Jadwal bersamaan dengan audit internal',
      created_at: '2026-11-10T09:13:00Z',
    );

    const pendingDetail = LeaveRequestModel(
      id_leave_requests: 55,
      request_number: 'LVR-202611-000055',
      id_employees: 4,
      employee_name: 'Budi Santoso',
      employee_position: 'Staff IT & Sistem Operasional',
      leave_type: 'Cuti Tahunan',
      is_paid: true,
      start_date: '2026-11-18',
      end_date: '2026-11-19',
      total_days: 2,
      reason: 'Keperluan mendesak keluarga',
      status: LeaveStatus.pending,
      created_at: '2026-11-11T08:30:00Z',
    );

    Widget buildEmployeeDetail() => ProviderScope(
          key: const ValueKey('leave_detail_emp_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: employeeUser);
              return n;
            }),
            leaveRepositoryProvider.overrideWithValue(mockLeaveRepo),
          ],
          child: const MaterialApp(
            home: LeaveDetailScreen(item: rejectedDetail, isApprovalView: false),
          ),
        );

    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildEmployeeDetail(),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('leave_detail_approve_btn')), findsNothing);
    expect(find.byKey(const Key('leave_detail_reject_btn')), findsNothing);
    expect(
      _borderedContainersInside(find.byKey(const Key('leave_detail_summary_box'))),
      findsNothing,
    );

    await pumpViewport(tester, size: const Size(375, 900), child: buildEmployeeDetail());
    expect(tester.takeException(), isNull);
    await pumpViewport(tester, size: const Size(640, 900), child: buildEmployeeDetail());
    expect(tester.takeException(), isNull);

    Widget buildManagerDetail() => ProviderScope(
          key: const ValueKey('leave_detail_mgr_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: managerUser);
              return n;
            }),
            leaveRepositoryProvider.overrideWithValue(mockLeaveRepo),
          ],
          child: const MaterialApp(
            home: LeaveDetailScreen(item: pendingDetail, isApprovalView: true),
          ),
        );

    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildManagerDetail(),
    );
    expect(tester.takeException(), isNull);
    final appPos300 = tester.getTopLeft(find.byKey(const Key('leave_detail_approve_btn')));
    final rejPos300 = tester.getTopLeft(find.byKey(const Key('leave_detail_reject_btn')));
    expect(rejPos300.dy, greaterThan(appPos300.dy + 20));
    expect(
      tester.getSize(find.byKey(const Key('leave_detail_approve_btn'))).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );
    expect(
      tester.getSize(find.byKey(const Key('leave_detail_reject_btn'))).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );

    await pumpViewport(tester, size: const Size(375, 900), child: buildManagerDetail());
    expect(tester.takeException(), isNull);
    final appPos375 = tester.getTopLeft(find.byKey(const Key('leave_detail_approve_btn')));
    final rejPos375 = tester.getTopLeft(find.byKey(const Key('leave_detail_reject_btn')));
    expect((rejPos375.dy - appPos375.dy).abs(), lessThan(4.0));

    await pumpViewport(tester, size: const Size(640, 900), child: buildManagerDetail());
    expect(tester.takeException(), isNull);
  });

  testWidgets('NotificationSheet & Revision 3-step screens reflow cleanly across breakpoints',
      (tester) async {
    final mockAuth = _MockAuthRepo();
    final mockAttRepo = _MockAttendanceRepo();
    final mockOvertimeRepo = _MockOvertimeRepo();
    final mockNotifRepo = _MockNotificationRepo();

    const revisingRequest = OvertimeRequestModel(
      id_overtime_requests: 77,
      employee_name: 'Budi Pratama',
      employee_position: 'System Engineer',
      date: '2026-11-11',
      end_date: '2026-11-12',
      start_time: '22:00:00',
      end_time: '01:00:00',
      duration_hours: 3.0,
      overtime_type: 'Lembur Hari Libur',
      reason_category: 'Dukungan Operasional',
      reason: 'Migrasi jaringan core switch dan audit konfigurasi malam',
      attachment_url: 'http://localhost:8000/storage/1/overtimes/surat_revisi.pdf',
      status: OvertimeStatus.pending,
    );

    Widget buildReviseForm() => ProviderScope(
          key: const ValueKey('revise_form_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: employeeUser);
              return n;
            }),
            overtimeRepositoryProvider.overrideWithValue(mockOvertimeRepo),
            attendanceRepositoryProvider.overrideWithValue(mockAttRepo),
          ],
          child: const MaterialApp(
            home: ApplyOvertimeFormScreen(existingRequest: revisingRequest),
          ),
        );

    for (final s in [const Size(300, 900), const Size(375, 900), const Size(640, 900)]) {
      await pumpViewport(tester, size: s, child: buildReviseForm());
      expect(tester.takeException(), isNull);
    }
    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildReviseForm(),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Revisi Lembur'), findsOneWidget);
    expect(find.text('Tanggal Lembur'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('overtime_next_step_btn'))).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );
    expect(_borderedContainersInside(find.byKey(const ValueKey('revise_form_scope'))), findsNothing);

    // Check remove/undo touch target in Revision Screen 1
    await tester.ensureVisible(find.byKey(const Key('overtime_remove_file_btn')));
    await tester.tap(find.byKey(const Key('overtime_remove_file_btn')));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const Key('overtime_restore_file_btn'))).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );

    Widget buildReviseDetail() => ProviderScope(
          key: const ValueKey('revise_detail_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: employeeUser);
              return n;
            }),
            overtimeRepositoryProvider.overrideWithValue(mockOvertimeRepo),
            attendanceRepositoryProvider.overrideWithValue(mockAttRepo),
          ],
          child: MaterialApp(
            home: OvertimeDetailReviewScreen(
              employeeName: 'Budi Pratama',
              employeePosition: 'System Engineer',
              startDate: DateTime(2026, 11, 11),
              endDate: DateTime(2026, 11, 11),
              overtimeType: 'Lembur Hari Libur',
              reasonCategory: 'Dukungan Operasional',
              reason: 'Migrasi jaringan core switch',
              revisingRequestId: 77,
              hasExistingRemoteAttachment: true,
              attachmentName: 'surat_revisi.pdf',
              initialSchedules: [
                OvertimeDaySchedule(
                  date: DateTime(2026, 11, 11),
                  slots: [
                    OvertimeSlotEntry(
                      startDate: DateTime(2026, 11, 11),
                      endDate: DateTime(2026, 11, 12),
                      startTime: const TimeOfDay(hour: 22, minute: 0),
                      endTime: const TimeOfDay(hour: 1, minute: 0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildReviseDetail(),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Rincian Revisi Lembur'), findsOneWidget);
    expect(find.byKey(const Key('overtime_save_draft_btn')), findsNothing);
    expect(find.text('Simpan Revisi'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('overtime_submit_btn'))).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );
    await pumpViewport(tester, size: const Size(375, 900), child: buildReviseDetail());
    expect(tester.takeException(), isNull);
    await pumpViewport(tester, size: const Size(640, 900), child: buildReviseDetail());
    expect(tester.takeException(), isNull);

    Widget buildReviseDaySheet() => MaterialApp(
          key: const ValueKey('revise_daysheet_scope'),
          home: Scaffold(
            body: OvertimeDayScheduleSheet(
              employeeName: 'Budi Pratama',
              employeePosition: 'System Engineer',
              allowMultipleSlots: false,
              allowReset: false,
              daySchedule: OvertimeDaySchedule(
                date: DateTime(2026, 11, 11),
                slots: [
                  OvertimeSlotEntry(
                    startDate: DateTime(2026, 11, 11),
                    endDate: DateTime(2026, 11, 12),
                    startTime: const TimeOfDay(hour: 22, minute: 0),
                    endTime: const TimeOfDay(hour: 1, minute: 0),
                  ),
                ],
              ),
              shiftName: 'U5SH2OPR6',
              shiftRange: '[08:00 - 17:00]',
            ),
          ),
        );

    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildReviseDaySheet(),
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('overtime_add_slot_btn')), findsNothing);
    expect(find.byKey(const Key('overtime_slot_reset_btn')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('overtime_update_day_btn'))).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );

    Widget buildNotificationSheet() => ProviderScope(
          key: const ValueKey('notif_sheet_scope'),
          overrides: [notificationRepositoryProvider.overrideWithValue(mockNotifRepo)],
          child: const MaterialApp(home: Scaffold(body: NotificationSheet())),
        );

    for (final s in [const Size(300, 900), const Size(375, 900), const Size(640, 900)]) {
      await pumpViewport(tester, size: s, child: buildNotificationSheet());
      expect(tester.takeException(), isNull);
    }
    await pumpViewport(
      tester,
      size: const Size(375, 900),
      textScale: 1.3,
      child: buildNotificationSheet(),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('PayrollHistoryScreen & PayrollSlipDetailScreen reflow without nested cards',
      (tester) async {
    final mockAuth = _MockAuthRepo();
    final mockPayrollRepo = _MockPayrollRepo();

    Widget buildPayroll() => ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: employeeUser);
              return n;
            }),
            payrollRepositoryProvider.overrideWithValue(mockPayrollRepo),
          ],
          child: const MaterialApp(home: PayrollHistoryScreen()),
        );

    for (final s in [const Size(300, 900), const Size(375, 900), const Size(640, 900)]) {
      await pumpViewport(tester, size: s, child: buildPayroll());
      expect(tester.takeException(), isNull);
    }
    expect(find.text('PT SPINDO'), findsNothing);
    await pumpViewport(
      tester,
      size: const Size(375, 900),
      textScale: 1.3,
      child: buildPayroll(),
    );
    expect(tester.takeException(), isNull);

    final summaryCard = find.ancestor(
      of: find.text('Gaji Bersih Terakhir'),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).border != null,
      ),
    ).first;
    expect(_borderedContainersInside(summaryCard), findsNothing);

    Widget buildDetail() => ProviderScope(
          key: const ValueKey('payroll_detail_scope'),
          overrides: [payrollRepositoryProvider.overrideWithValue(mockPayrollRepo)],
          child: MaterialApp(home: PayrollSlipDetailScreen(slip: sampleSlip)),
        );

    for (final s in [const Size(300, 900), const Size(375, 900), const Size(640, 900)]) {
      await pumpViewport(tester, size: s, child: buildDetail());
      expect(tester.takeException(), isNull);
    }
    await pumpViewport(
      tester,
      size: const Size(375, 900),
      textScale: 1.3,
      child: buildDetail(),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('New 3-step Overtime flow & draft cards reflow cleanly without nested cards',
      (tester) async {
    final mockAuth = _MockAuthRepo();
    final mockAttRepo = _MockAttendanceRepo();
    final mockOvertimeRepo = _MockOvertimeRepo();

    await OvertimeDraftService().saveDraft(
      1,
      OvertimeDraftModel(
        id: 'resp_draft_1',
        startDate: DateTime(2026, 11, 11),
        endDate: DateTime(2026, 11, 13),
        overtimeType: 'Lembur Hari Libur',
        reasonCategory: 'Dukungan Operasional',
        reason: 'Persiapan audit produksi triwulan',
        attachmentName: 'jadwal_shift.pdf',
        daySchedules: [
          OvertimeDaySchedule(date: DateTime(2026, 11, 11)),
          OvertimeDaySchedule(date: DateTime(2026, 11, 12)),
          OvertimeDaySchedule(date: DateTime(2026, 11, 13)),
        ],
        savedAt: DateTime(2026, 11, 10, 18, 0),
      ),
    );

    // 1. OvertimeScreen with saved local draft card at narrow 300px & 375px @ 1.3x
    Widget buildOvertimeWithDraft() => ProviderScope(
          key: const ValueKey('ot_draft_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: employeeUser);
              return n;
            }),
            overtimeRepositoryProvider.overrideWithValue(mockOvertimeRepo),
            attendanceRepositoryProvider.overrideWithValue(mockAttRepo),
          ],
          child: const MaterialApp(home: OvertimeScreen()),
        );

    await pumpViewport(tester, size: const Size(300, 900), child: buildOvertimeWithDraft());
    expect(tester.takeException(), isNull);
    expect(find.text('Draf Tersimpan di Perangkat'), findsOneWidget);
    final resumePos300 = tester.getTopLeft(find.text('Lanjutkan'));
    final deletePos300 = tester.getTopLeft(find.text('Hapus'));
    expect(deletePos300.dy, greaterThan(resumePos300.dy + 20));
    final draftCard = find.ancestor(
      of: find.text('Persiapan audit produksi triwulan'),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).border != null,
      ),
    ).first;
    expect(_borderedContainersInside(draftCard), findsNothing);

    await pumpViewport(
      tester,
      size: const Size(375, 900),
      textScale: 1.3,
      child: buildOvertimeWithDraft(),
    );
    expect(tester.takeException(), isNull);

    // 2. ApplyOvertimeFormScreen (Screen 1) across 300px, 375px, 375px @ 1.3x, 640px
    Widget buildFormScreen() => ProviderScope(
          key: const ValueKey('ot_form_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: employeeUser);
              return n;
            }),
            overtimeRepositoryProvider.overrideWithValue(mockOvertimeRepo),
            attendanceRepositoryProvider.overrideWithValue(mockAttRepo),
          ],
          child: const MaterialApp(home: ApplyOvertimeFormScreen()),
        );

    await pumpViewport(tester, size: const Size(300, 900), child: buildFormScreen());
    expect(tester.takeException(), isNull);
    final fStart300 = tester.getTopLeft(find.text('Tanggal Mulai'));
    final fEnd300 = tester.getTopLeft(find.text('Tanggal Berakhir'));
    expect(fEnd300.dy, greaterThan(fStart300.dy + 20));
    expect(
      tester.getSize(find.byKey(const Key('overtime_next_step_btn'))).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );

    await pumpViewport(tester, size: const Size(375, 900), child: buildFormScreen());
    expect(tester.takeException(), isNull);
    final fStart375 = tester.getTopLeft(find.text('Tanggal Mulai'));
    final fEnd375 = tester.getTopLeft(find.text('Tanggal Berakhir'));
    expect((fEnd375.dy - fStart375.dy).abs(), lessThan(4.0));

    await pumpViewport(
      tester,
      size: const Size(375, 900),
      textScale: 1.3,
      child: buildFormScreen(),
    );
    expect(tester.takeException(), isNull);
    await pumpViewport(tester, size: const Size(640, 900), child: buildFormScreen());
    expect(tester.takeException(), isNull);

    // 3. OvertimeDetailReviewScreen (Screen 2) across 300px, 300px @ 1.3x, 375px, 640px
    Widget buildDetailReviewScreen() => ProviderScope(
          key: const ValueKey('ot_review_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: employeeUser);
              return n;
            }),
            overtimeRepositoryProvider.overrideWithValue(mockOvertimeRepo),
            attendanceRepositoryProvider.overrideWithValue(mockAttRepo),
          ],
          child: MaterialApp(
            home: OvertimeDetailReviewScreen(
              employeeName: 'Budi Pratama',
              employeePosition: 'System Engineer',
              startDate: DateTime(2026, 11, 11),
              endDate: DateTime(2026, 11, 12),
              overtimeType: 'Jam Lembur',
              reasonCategory: 'Lembur',
              reason: 'Support Migrasi Server Produksi',
              initialSchedules: [
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
            ),
          ),
        );

    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildDetailReviewScreen(),
    );
    expect(tester.takeException(), isNull);
    final draf300 = tester.getTopLeft(find.byKey(const Key('overtime_save_draft_btn')));
    final ajukan300 = tester.getTopLeft(find.byKey(const Key('overtime_submit_btn')));
    expect(ajukan300.dy, greaterThan(draf300.dy + 20));

    await pumpViewport(tester, size: const Size(375, 900), child: buildDetailReviewScreen());
    expect(tester.takeException(), isNull);
    final draf375 = tester.getTopLeft(find.byKey(const Key('overtime_save_draft_btn')));
    final ajukan375 = tester.getTopLeft(find.byKey(const Key('overtime_submit_btn')));
    expect((ajukan375.dy - draf375.dy).abs(), lessThan(4.0));
    final dayCard0 = find.byKey(const Key('overtime_day_card_0'));
    expect(_borderedContainersInside(dayCard0), findsOneWidget);

    await pumpViewport(tester, size: const Size(640, 900), child: buildDetailReviewScreen());
    expect(tester.takeException(), isNull);

    // 4. OvertimeDayScheduleSheet (Screen 3) across 300px @ 1.3x, 375px, 640px
    Widget buildDaySheetScreen() => MaterialApp(
          key: const ValueKey('ot_daysheet_scope'),
          home: Scaffold(
            body: OvertimeDayScheduleSheet(
              employeeName: 'Budi Pratama',
              employeePosition: 'System Engineer',
              daySchedule: OvertimeDaySchedule(
                date: DateTime(2026, 11, 11),
                slots: [
                  OvertimeSlotEntry(
                    startDate: DateTime(2026, 11, 11),
                    endDate: DateTime(2026, 11, 12),
                    startTime: const TimeOfDay(hour: 21, minute: 0),
                    endTime: const TimeOfDay(hour: 1, minute: 0),
                  ),
                ],
              ),
              shiftName: 'U5SH2OPR6',
              shiftRange: '[08:00 - 17:00]',
            ),
          ),
        );

    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildDaySheetScreen(),
    );
    expect(tester.takeException(), isNull);
    final addSlot300 = tester.getTopLeft(find.byKey(const Key('overtime_add_slot_btn')));
    final updateDay300 = tester.getTopLeft(find.byKey(const Key('overtime_update_day_btn')));
    expect(updateDay300.dy, greaterThan(addSlot300.dy + 20));
    expect(
      tester.getSize(find.byKey(const Key('overtime_add_slot_btn'))).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );

    await pumpViewport(tester, size: const Size(375, 900), child: buildDaySheetScreen());
    expect(tester.takeException(), isNull);
    await pumpViewport(tester, size: const Size(640, 900), child: buildDaySheetScreen());
    expect(tester.takeException(), isNull);

    // 5. Consolidated multi-day OvertimeDetailScreen across breakpoints (no nested bordered boxes)
    const consolidatedDetail = OvertimeRequestModel(
      id_overtime_requests: 88,
      request_number: 'OVR-202611-000088',
      employee_name: 'Budi Pratama',
      employee_position: 'System Engineer',
      shift_name: 'U5SH3OPR6',
      shift_start_time: '23:00:00',
      shift_end_time: '07:00:00',
      date: '2026-11-02',
      end_date: '2026-11-06',
      start_time: '21:00:00',
      end_time: '20:30:00',
      duration_hours: 7.5,
      overtime_type: 'Jam Lembur',
      reason_category: 'Dukungan Operasional',
      reason: 'Support Produksi + Delivery lini gudang 13',
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
    );

    Widget buildConsolidatedDetail() => ProviderScope(
          key: const ValueKey('ot_consolidated_detail_scope'),
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            authStateProvider.overrideWith((ref) {
              final n = AuthNotifier(mockAuth, ref);
              n.state = AuthState(status: AuthStatus.authenticated, user: employeeUser);
              return n;
            }),
            overtimeRepositoryProvider.overrideWithValue(mockOvertimeRepo),
            attendanceRepositoryProvider.overrideWithValue(mockAttRepo),
          ],
          child: const MaterialApp(
            home: OvertimeDetailScreen(item: consolidatedDetail),
          ),
        );

    await pumpViewport(
      tester,
      size: const Size(300, 900),
      textScale: 1.3,
      child: buildConsolidatedDetail(),
    );
    expect(tester.takeException(), isNull);
    expect(
      _borderedContainersInside(find.byKey(const Key('overtime_detail_schedule_box'))),
      findsNothing,
    );
    expect(
      tester.getSize(find.byKey(const Key('overtime_detail_revise_btn'))).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );
    expect(
      tester.getSize(find.byKey(const Key('overtime_detail_cancel_btn'))).height,
      greaterThanOrEqualTo(AppDimensions.minTouchTarget),
    );

    await pumpViewport(tester, size: const Size(375, 900), child: buildConsolidatedDetail());
    expect(tester.takeException(), isNull);
    await pumpViewport(tester, size: const Size(640, 900), child: buildConsolidatedDetail());
    expect(tester.takeException(), isNull);
  });
}
