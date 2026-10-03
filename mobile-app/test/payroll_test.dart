import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_app/core/constants/api_endpoints.dart';
import 'package:mobile_app/core/constants/app_colors.dart';
import 'package:mobile_app/core/constants/app_dimensions.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/network/api_exception.dart';
import 'package:mobile_app/core/widgets/app_button.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';
import 'package:mobile_app/core/widgets/app_skeleton.dart';
import 'package:mobile_app/features/payroll/data/payroll_models.dart';
import 'package:mobile_app/features/payroll/data/payroll_repository.dart';
import 'package:mobile_app/features/payroll/presentation/payroll_history_screen.dart';
import 'package:mobile_app/features/payroll/presentation/payroll_slip_detail_screen.dart';
import 'package:mobile_app/features/payroll/provider/payroll_provider.dart';

class MockPayrollRepository extends PayrollRepository {
  MockPayrollRepository() : super(_DummyApiClient());

  List<PayrollSlipModel> slipsData = [];
  bool shouldThrow = false;
  String? errorMessage;
  bool downloadCalled = false;
  int? downloadedSlipId;

  @override
  Future<List<PayrollSlipModel>> getMySlips() async {
    if (shouldThrow) {
      throw ApiException(message: errorMessage ?? 'Gagal memuat data');
    }
    return slipsData;
  }

  @override
  Future<String> downloadSlipPdf(int slipId) async {
    downloadedSlipId = slipId;
    downloadCalled = true;
    if (shouldThrow) {
      throw ApiException(message: errorMessage ?? 'Gagal mengunduh berkas');
    }
    return 'https://example.com/slips/slip-$slipId.pdf';
  }
}

class _MockDioApiClient extends Fake implements ApiClient {
  dynamic getResult;
  bool shouldThrow = false;
  String? errorMessage;
  String? lastGetPath;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, dynamic options}) async {
    lastGetPath = path;
    if (shouldThrow) throw ApiException(message: errorMessage ?? 'Network error');
    return getResult;
  }
}

class _DummyApiClient extends Fake implements ApiClient {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (_) {}
  });

  group('Payroll Models & Formatters Unit Tests', () {
    test('PayrollPeriodModel parses JSON with primary key id_payroll_periods', () {
      final json = {
        'id_payroll_periods': 101,
        'name': 'Maret 2026',
        'start_date': '2026-03-01',
        'end_date': '2026-03-31',
        'payment_date': '2026-03-25',
        'status': 'finalized',
      };

      final period = PayrollPeriodModel.fromMap(json);
      expect(period.id_payroll_periods, 101);
      expect(period.name, 'Maret 2026');
      expect(period.start_date, '2026-03-01');
      expect(period.end_date, '2026-03-31');
      expect(period.payment_date, '2026-03-25');
      expect(period.status, 'finalized');

      final mapped = period.toMap();
      expect(mapped['id_payroll_periods'], 101);
      expect(mapped['name'], 'Maret 2026');
    });

    test('PayrollSlipModel parses from JSON with safe null-handling and numbers', () {
      final json = {
        'id_payroll_slips': 501,
        'id_payroll_periods': 101,
        'id_employees': 201,
        'basic_salary': '5000000',
        'allowance_fixed': 1000000,
        'overtime_pay': 500000.0,
        'deduction_late': '50000',
        'deduction_absence': 0,
        'deduction_other': 25000,
        'net_salary': '6425000',
        'pdf_url': 'https://example.com/slip-501.pdf',
        'period_name': 'Maret 2026',
        'payment_date': '2026-03-25',
        'status': 'paid',
      };

      final slip = PayrollSlipModel.fromMap(json);
      expect(slip.id_payroll_slips, 501);
      expect(slip.id_payroll_periods, 101);
      expect(slip.id_employees, 201);
      expect(slip.basic_salary, 5000000.0);
      expect(slip.allowance_fixed, 1000000.0);
      expect(slip.overtime_pay, 500000.0);
      expect(slip.deduction_late, 50000.0);
      expect(slip.deduction_absence, 0.0);
      expect(slip.deduction_other, 25000.0);
      expect(slip.net_salary, 6425000.0);
      expect(slip.pdf_url, 'https://example.com/slip-501.pdf');
      expect(slip.period_name, 'Maret 2026');
      expect(slip.payment_date, '2026-03-25');
      expect(slip.status, PayrollStatus.paid);

      expect(slip.totalEarnings, 6500000.0);
      expect(slip.totalDeductions, 75000.0);

      expect(slip.formattedNetSalary, contains('6.425.000'));
      expect(slip.formattedBasicSalary, contains('5.000.000'));
      expect(slip.formattedAllowanceFixed, contains('1.000.000'));
      expect(slip.formattedOvertimePay, contains('500.000'));
      expect(slip.formattedDeductionLate, contains('50.000'));
      expect(slip.formattedDeductionAbsence, contains('0'));
      expect(slip.formattedDeductionOther, contains('25.000'));
      expect(slip.formattedTotalEarnings, contains('6.500.000'));
      expect(slip.formattedTotalDeductions, contains('75.000'));
      expect(slip.formattedPaymentDate, contains('2026'));
    });

    test('PayrollSlipModel handles nested payroll_period map and null values', () {
      final json = {
        'id_payroll_slips': '701',
        'id_payroll_periods': '102',
        'id_employees': '301',
        'basic_salary': null,
        'allowance_fixed': null,
        'overtime_pay': null,
        'deduction_late': null,
        'deduction_absence': null,
        'deduction_other': null,
        'net_salary': null,
        'payroll_period': {
          'id_payroll_periods': 102,
          'name': 'Februari 2026',
          'start_date': '2026-02-01',
          'end_date': '2026-02-28',
          'payment_date': '2026-02-25',
          'status': 'locked',
        },
      };

      final slip = PayrollSlipModel.fromMap(json);
      expect(slip.id_payroll_slips, 701);
      expect(slip.id_payroll_periods, 102);
      expect(slip.id_employees, 301);
      expect(slip.basic_salary, 0.0);
      expect(slip.net_salary, 0.0);
      expect(slip.period_name, 'Februari 2026');
      expect(slip.payment_date, '2026-02-25');
      expect(slip.status, PayrollStatus.locked);
      expect(slip.payroll_period, isNotNull);
      expect(slip.payroll_period!.id_payroll_periods, 102);
    });

    test('PayrollStatus enum parses variants and returns WCAG AA badges', () {
      expect(PayrollStatus.fromString('paid'), PayrollStatus.paid);
      expect(PayrollStatus.fromString('dibayar'), PayrollStatus.paid);
      expect(PayrollStatus.fromString('selesai'), PayrollStatus.paid);

      expect(PayrollStatus.fromString('locked'), PayrollStatus.locked);
      expect(PayrollStatus.fromString('finalized'), PayrollStatus.locked);
      expect(PayrollStatus.fromString('final'), PayrollStatus.locked);

      expect(PayrollStatus.fromString('draft'), PayrollStatus.draft);
      expect(PayrollStatus.fromString('draf'), PayrollStatus.draft);
      expect(PayrollStatus.fromString(null), PayrollStatus.draft);
      expect(PayrollStatus.fromString('unknown'), PayrollStatus.draft);

      expect(PayrollStatus.paid.label, 'Dibayar');
      expect(PayrollStatus.paid.textColor, AppColors.successText);
      expect(PayrollStatus.paid.backgroundColor, AppColors.successBg);
      expect(PayrollStatus.paid.borderColor, AppColors.successBorder);

      expect(PayrollStatus.locked.label, 'Final');
      expect(PayrollStatus.locked.textColor, AppColors.warningText);

      expect(PayrollStatus.draft.label, 'Draf');
      expect(PayrollStatus.draft.textColor, AppColors.inkMuted);
    });
  });

  group('PayrollRepository Unit Tests', () {
    test('getMySlips returns parsed list from direct List response', () async {
      final apiClient = _MockDioApiClient();
      apiClient.getResult = [
        {
          'id_payroll_slips': 1,
          'id_payroll_periods': 10,
          'id_employees': 20,
          'basic_salary': 4000000,
          'allowance_fixed': 500000,
          'overtime_pay': 0,
          'deduction_late': 0,
          'deduction_absence': 0,
          'deduction_other': 0,
          'net_salary': 4500000,
          'period_name': 'Januari 2026',
        }
      ];

      final repo = PayrollRepository(apiClient);
      final slips = await repo.getMySlips();

      expect(apiClient.lastGetPath, ApiEndpoints.payrollMySlips);
      expect(slips.length, 1);
      expect(slips.first.id_payroll_slips, 1);
      expect(slips.first.period_name, 'Januari 2026');
      expect(slips.first.net_salary, 4500000.0);
    });

    test('getMySlips returns parsed list from wrapped {"data": [...]} response', () async {
      final apiClient = _MockDioApiClient();
      apiClient.getResult = {
        'success': true,
        'data': [
          {
            'id_payroll_slips': 2,
            'id_payroll_periods': 11,
            'id_employees': 20,
            'basic_salary': 5000000,
            'allowance_fixed': 1000000,
            'overtime_pay': 200000,
            'deduction_late': 0,
            'deduction_absence': 0,
            'deduction_other': 0,
            'net_salary': 6200000,
            'period_name': 'Februari 2026',
          }
        ]
      };

      final repo = PayrollRepository(apiClient);
      final slips = await repo.getMySlips();

      expect(slips.length, 1);
      expect(slips.first.id_payroll_slips, 2);
      expect(slips.first.period_name, 'Februari 2026');
    });

    test('downloadSlipPdf calls payrollMySlipDownload endpoint and extracts result', () async {
      final apiClient = _MockDioApiClient();
      apiClient.getResult = [37, 80, 68, 70, 45, 49, 46, 52];

      final repo = PayrollRepository(apiClient);
      final filePath = await repo.downloadSlipPdf(42);

      expect(apiClient.lastGetPath, ApiEndpoints.payrollMySlipDownload(42));
      expect(filePath, contains('slip_gaji_42.pdf'));
      expect(File(filePath).existsSync(), isTrue);
    });
  });

  group('PayrollDownloadNotifier Tests', () {
    test('successfully manages download state lifecycle', () async {
      final mockRepo = MockPayrollRepository();
      final notifier = PayrollDownloadNotifier(mockRepo);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.isSuccess, false);

      final future = notifier.downloadSlipPdf(99);
      expect(notifier.state.isLoading, true);

      final success = await future;
      expect(success, true);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.isSuccess, true);
      expect(notifier.state.resultMessage, contains('99'));
      expect(mockRepo.downloadCalled, true);
      expect(mockRepo.downloadedSlipId, 99);

      notifier.reset();
      expect(notifier.state.isLoading, false);
      expect(notifier.state.isSuccess, false);
    });

    test('handles download errors appropriately', () async {
      final mockRepo = MockPayrollRepository();
      mockRepo.shouldThrow = true;
      mockRepo.errorMessage = 'Gagal unduh slip PDF';

      final notifier = PayrollDownloadNotifier(mockRepo);
      final success = await notifier.downloadSlipPdf(99);

      expect(success, false);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.isSuccess, false);
      expect(notifier.state.errorMessage, contains('Gagal unduh slip PDF'));
    });
  });

  group('PayrollHistoryScreen Strict 3 UI States & Interaction Tests', () {
    final sampleSlip1 = PayrollSlipModel(
      id_payroll_slips: 10,
      id_payroll_periods: 1,
      id_employees: 100,
      basic_salary: 5000000,
      allowance_fixed: 1000000,
      overtime_pay: 500000,
      deduction_late: 50000,
      deduction_absence: 0,
      deduction_other: 0,
      net_salary: 6450000,
      period_name: 'Maret 2026',
      payment_date: '2026-03-25',
      status: PayrollStatus.paid,
    );

    final sampleSlip2 = PayrollSlipModel(
      id_payroll_slips: 9,
      id_payroll_periods: 2,
      id_employees: 100,
      basic_salary: 5000000,
      allowance_fixed: 1000000,
      overtime_pay: 0,
      deduction_late: 0,
      deduction_absence: 0,
      deduction_other: 0,
      net_salary: 6000000,
      period_name: 'Februari 2026',
      payment_date: '2026-02-25',
      status: PayrollStatus.locked,
    );

    Widget createHistoryScreen({
      required MockPayrollRepository repo,
      Completer<List<PayrollSlipModel>>? delayCompleter,
    }) {
      return ProviderScope(
        overrides: [
          payrollRepositoryProvider.overrideWithValue(repo),
          if (delayCompleter != null)
            myPayrollSlipsProvider.overrideWith((ref) => delayCompleter.future),
        ],
        child: const MaterialApp(
          home: PayrollHistoryScreen(),
        ),
      );
    }

    testWidgets('State 1: Loading state renders AppSkeleton widgets', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final completer = Completer<List<PayrollSlipModel>>();
      final mockRepo = MockPayrollRepository();

      await tester.pumpWidget(createHistoryScreen(
        repo: mockRepo,
        delayCompleter: completer,
      ));
      await tester.pump();

      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.text('Slip Gaji'), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('State 2: Empty state renders AppEmptyState ("Belum Ada Slip Gaji")', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockPayrollRepository();
      mockRepo.slipsData = [];

      await tester.pumpWidget(createHistoryScreen(repo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Belum Ada Slip Gaji'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    });

    testWidgets('State 3: Error state renders AppErrorState with retry button', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockPayrollRepository();
      mockRepo.shouldThrow = true;
      mockRepo.errorMessage = 'Koneksi internet bermasalah';

      await tester.pumpWidget(createHistoryScreen(repo: mockRepo));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Gagal Memuat Slip Gaji'), findsOneWidget);
      expect(find.text('Muat Ulang'), findsOneWidget);

      // Now fix mock and click retry
      mockRepo.shouldThrow = false;
      mockRepo.slipsData = [sampleSlip1];

      await tester.tap(find.text('Muat Ulang'));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsNothing);
      expect(find.text('Maret 2026'), findsWidgets);
    });

    testWidgets('Populated state renders summary banner, slips list with badges, and navigates to detail', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockPayrollRepository();
      mockRepo.slipsData = [sampleSlip1, sampleSlip2];

      await tester.pumpWidget(createHistoryScreen(repo: mockRepo));
      await tester.pumpAndSettle();

      // Verify Summary Card
      expect(find.text('Gaji Bersih Terakhir'), findsOneWidget);
      expect(find.text('Riwayat Slip Gaji'), findsOneWidget);

      // Verify status badges
      expect(find.text('Dibayar'), findsWidgets);
      expect(find.text('Final'), findsOneWidget);

      // Verify slips present
      expect(find.text('Maret 2026'), findsWidgets);
      expect(find.text('Februari 2026'), findsOneWidget);

      // Verify chevron icons
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(2));

      // Tap on first slip to navigate to detail
      await tester.tap(find.text('Februari 2026'));
      await tester.pumpAndSettle();

      // Verify navigation to PayrollSlipDetailScreen
      expect(find.byType(PayrollSlipDetailScreen), findsOneWidget);
      expect(find.text('Detail Slip Gaji'), findsOneWidget);
      expect(find.text('Rincian Penerimaan'), findsOneWidget);
      expect(find.text('Rincian Potongan'), findsOneWidget);
    });
  });

  group('PayrollSlipDetailScreen Widget Tests', () {
    final testSlip = PayrollSlipModel(
      id_payroll_slips: 42,
      id_payroll_periods: 5,
      id_employees: 12,
      basic_salary: 8000000,
      allowance_fixed: 2000000,
      overtime_pay: 1500000,
      deduction_late: 100000,
      deduction_absence: 200000,
      deduction_other: 50000,
      net_salary: 11150000,
      period_name: 'Maret 2026',
      payment_date: '2026-03-25',
      status: PayrollStatus.paid,
    );

    Widget createDetailScreen({required MockPayrollRepository repo}) {
      return ProviderScope(
        overrides: [
          payrollRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: PayrollSlipDetailScreen(slip: testSlip),
        ),
      );
    }

    testWidgets('renders all breakdown cards and highlighted take home pay', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockPayrollRepository();

      await tester.pumpWidget(createDetailScreen(repo: mockRepo));
      await tester.pumpAndSettle();

      // Check header info
      expect(find.text('Detail Slip Gaji'), findsOneWidget);
      expect(find.text('Periode Gaji'), findsOneWidget);
      expect(find.text('Maret 2026'), findsOneWidget);
      expect(find.text('Dibayar'), findsOneWidget);

      // Check Rincian Penerimaan
      expect(find.text('Rincian Penerimaan'), findsOneWidget);
      expect(find.text('Gaji Pokok'), findsOneWidget);
      expect(find.text('Tunjangan Tetap'), findsOneWidget);
      expect(find.text('Lembur'), findsOneWidget);
      expect(find.text('Total Penerimaan'), findsOneWidget);

      // Check Rincian Potongan
      expect(find.text('Rincian Potongan'), findsOneWidget);
      expect(find.text('Keterlambatan'), findsOneWidget);
      expect(find.text('Ketidakhadiran'), findsOneWidget);
      expect(find.text('Potongan Lain'), findsOneWidget);
      expect(find.text('Total Potongan'), findsOneWidget);

      // Check Total Gaji Bersih (Take Home Pay)
      expect(find.text('Total Gaji Bersih (Take Home Pay)'), findsOneWidget);

      // Check Primary Button minTouchTarget >= 48px
      final buttonFinder = find.byType(AppButton);
      expect(buttonFinder, findsOneWidget);
      final buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.height, greaterThanOrEqualTo(AppDimensions.minTouchTarget));
      expect(find.text('Unduh Slip Gaji (PDF)'), findsOneWidget);

      // Verify SafeArea wraps body
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.body, isA<SafeArea>());
    });

    testWidgets('tapping Unduh Slip Gaji (PDF) calls download API and displays SnackBar', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockPayrollRepository();

      await tester.pumpWidget(createDetailScreen(repo: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unduh Slip Gaji (PDF)'));
      await tester.pumpAndSettle();

      expect(mockRepo.downloadCalled, true);
      expect(mockRepo.downloadedSlipId, 42);
      expect(find.text('Slip gaji berhasil diunduh.'), findsOneWidget);
    });

    testWidgets('shows error snackbar when download fails', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockRepo = MockPayrollRepository();
      mockRepo.shouldThrow = true;
      mockRepo.errorMessage = 'Server tidak dapat memproses berkas';

      await tester.pumpWidget(createDetailScreen(repo: mockRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Unduh Slip Gaji (PDF)'));
      await tester.pumpAndSettle();

      expect(mockRepo.downloadCalled, true);
      expect(find.textContaining('Server tidak dapat memproses berkas'), findsOneWidget);
    });
  });
}
