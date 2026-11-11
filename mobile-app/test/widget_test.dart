import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/constants/app_dimensions.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/core/widgets/ios_glass_menu_icon.dart';
import 'package:mobile_app/features/attendance/data/attendance_models.dart';
import 'package:mobile_app/features/attendance/provider/attendance_provider.dart';
import 'package:mobile_app/features/home/presentation/home_dashboard_view.dart';
import 'package:mobile_app/features/home/presentation/home_screen.dart';
import 'package:mobile_app/features/notification/provider/notification_provider.dart';
import 'package:mobile_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App launches with ProviderScope smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HrisApp(),
      ),
    );

    expect(find.byType(HrisApp), findsOneWidget);
  });

  testWidgets('HomeScreen renders floating bottom navigation dock', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Lembur'), findsOneWidget);
    expect(find.text('Cuti'), findsOneWidget);
    expect(find.text('Gaji'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });

  Widget buildDashboardHarness({double textScale = 1.0}) {
    return ProviderScope(
      overrides: [
        todayAttendanceProvider.overrideWith(
          (ref) async => const TodayAttendanceData(
            date: '2026-11-11',
            shiftName: 'Shift Reguler Operasional',
            startTime: '08:00',
            endTime: '17:00',
            lateToleranceMinutes: 15,
            status: 'Belum Hadir',
          ),
        ),
        unreadNotificationCountProvider.overrideWith((ref) async => 2),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: HomeDashboardView(
            onNavigateToTab: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('HomeDashboardView reflows card-less Favorite Menu and single-surface Shift card cleanly',
      (WidgetTester tester) async {
    Future<void> pumpAtSize(Size size, {double textScale = 1.0}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(buildDashboardHarness(textScale: textScale));
      await tester.pumpAndSettle();
    }

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // 1. Ultra-narrow phone (300px): 3 columns, stacked Clock In / Clock Out, zero overflow
    await pumpAtSize(const Size(300, 900));
    expect(tester.takeException(), isNull);
    final row1Item = tester.getTopLeft(find.text('Pengajuan\nLembur'));
    final row2Col4Item = tester.getTopLeft(find.text('Presensi\nKamera GPS'));
    expect(row2Col4Item.dy, greaterThan(row1Item.dy));
    final lemburBoxNarrow = tester.getSize(find.text('Pengajuan\nLembur'));
    expect(lemburBoxNarrow.width, greaterThan(0));

    final narrowClockInPos = tester.getTopLeft(find.text('Clock In'));
    final narrowClockOutPos = tester.getTopLeft(find.text('Clock Out'));
    expect(narrowClockOutPos.dy, greaterThan(narrowClockInPos.dy + 20));

    // 2. Standard phone (375px): 4 columns, side-by-side Clock In / Clock Out, flush header + >= 48px touch target
    await pumpAtSize(const Size(375, 900));
    expect(tester.takeException(), isNull);
    final phoneRow1A = tester.getTopLeft(find.text('Pengajuan\nLembur'));
    final phoneRow1D = tester.getTopLeft(find.text('Presensi\nKamera GPS'));
    final phoneRow2A = tester.getTopLeft(find.text('Tugas Luar\n(On Duty)'));
    expect((phoneRow1D.dy - phoneRow1A.dy).abs(), lessThan(4.0));
    expect(phoneRow2A.dy, greaterThan(phoneRow1A.dy + 40));

    final phoneClockInPos = tester.getTopLeft(find.text('Clock In'));
    final phoneClockOutPos = tester.getTopLeft(find.text('Clock Out'));
    expect((phoneClockOutPos.dy - phoneClockInPos.dy).abs(), lessThan(4.0));

    // Flush shift header InkWell has no nested bordered Container inside it
    final shiftHeaderTextFinder = find.textContaining('Shift: Shift Reguler Operasional');
    final shiftHeaderInkWell = find.ancestor(
      of: shiftHeaderTextFinder,
      matching: find.byType(InkWell),
    ).first;
    final shiftHeaderSize = tester.getSize(shiftHeaderInkWell);
    expect(shiftHeaderSize.height, greaterThanOrEqualTo(AppDimensions.minTouchTarget));
    final innerBorderedBoxes = find.descendant(
      of: shiftHeaderInkWell,
      matching: find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final dec = widget.decoration! as BoxDecoration;
          return dec.border != null;
        }
        return false;
      }),
    );
    expect(innerBorderedBoxes, findsNothing);

    final menuInkWell = tester.widgetList<InkWell>(
      find.ancestor(
        of: find.text('Pengajuan\nLembur'),
        matching: find.byType(InkWell),
      ),
    ).first;
    expect(menuInkWell.onTap, isNotNull);
    final tileSize = tester.getSize(
      find.ancestor(
        of: find.text('Pengajuan\nLembur'),
        matching: find.byType(InkWell),
      ).first,
    );
    expect(tileSize.width, greaterThanOrEqualTo(AppDimensions.minTouchTarget));
    expect(tileSize.height, greaterThanOrEqualTo(AppDimensions.minTouchTarget));

    // 3. Phone (375px) at 1.3x OS font scale stacks Clock In / Clock Out with zero overflow
    await pumpAtSize(const Size(375, 900), textScale: 1.3);
    expect(tester.takeException(), isNull);
    final scaledClockInPos = tester.getTopLeft(find.text('Clock In'));
    final scaledClockOutPos = tester.getTopLeft(find.text('Clock Out'));
    expect(scaledClockOutPos.dy, greaterThan(scaledClockInPos.dy + 20));

    // 4. Wide tablet / desktop (640px): 6 columns -> all 6 default menus sit in a single horizontal row
    await pumpAtSize(const Size(640, 900));
    expect(tester.takeException(), isNull);
    final wideFirst = tester.getTopLeft(find.text('Pengajuan\nLembur'));
    final wideLast = tester.getTopLeft(find.text('Profil &\nData Diri'));
    expect((wideLast.dy - wideFirst.dy).abs(), lessThan(4.0));

    // Verify tapping flush shift header opens Rincian Shift Kerja modal cleanly
    await tester.tap(shiftHeaderInkWell);
    await tester.pumpAndSettle();
    expect(find.text('Rincian Shift Kerja'), findsOneWidget);
  });

  testWidgets('Favorite Menu renders iOS 2026 Liquid Glass icons in grid and Edit sheet',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(375, 900),
          disableAnimations: true,
        ),
        child: buildDashboardHarness(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(IosGlassMenuIcon), findsNWidgets(6));
    expect(tester.takeException(), isNull);

    // Open Edit Favorite Menu sheet and verify lazy list items render iOS glass icons cleanly
    await tester.tap(find.byKey(const Key('favorite_menu_edit_btn')));
    await tester.pumpAndSettle();
    expect(find.text('Atur Favorite Menu'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(IosGlassMenuIcon),
      ),
      findsWidgets,
    );
    await tester.scrollUntilVisible(
      find.text('Pedoman & Regulasi'),
      180,
      scrollable: find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Pedoman & Regulasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HomeScreen animates smoothly on navbar and Favorite Menu transitions',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayAttendanceProvider.overrideWith(
            (ref) async => const TodayAttendanceData(
              date: '2026-11-11',
              shiftName: 'Shift Reguler Operasional',
              startTime: '08:00',
              endTime: '17:00',
              lateToleranceMinutes: 15,
              status: 'Belum Hadir',
            ),
          ),
          unreadNotificationCountProvider.overrideWith((ref) async => 2),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap navbar item 'Lembur' -> verify smooth mid-transition frame then clean settle
    await tester.tap(find.text('Lembur'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final midTranslations = tester
        .widgetList<FractionalTranslation>(find.byType(FractionalTranslation))
        .where((w) => w.translation != Offset.zero)
        .toList();
    expect(midTranslations, isNotEmpty);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final settledTranslations = tester
        .widgetList<FractionalTranslation>(find.byType(FractionalTranslation))
        .where((w) => w.translation != Offset.zero)
        .toList();
    expect(settledTranslations, isEmpty);

    // Jump back to Beranda, then switch via Favorite Menu shortcut ('Profil &\nData Diri')
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profil &\nData Diri'));
    await tester.pumpAndSettle();
    expect(find.text('Profil Saya'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Reduced-motion mode must switch immediately without active translation frames
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todayAttendanceProvider.overrideWith(
            (ref) async => const TodayAttendanceData(
              date: '2026-11-11',
              shiftName: 'Shift Reguler Operasional',
              startTime: '08:00',
              endTime: '17:00',
              lateToleranceMinutes: 15,
              status: 'Belum Hadir',
            ),
          ),
          unreadNotificationCountProvider.overrideWith((ref) async => 0),
        ],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(375, 900),
            disableAnimations: true,
          ),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cuti'));
    await tester.pump(const Duration(milliseconds: 80));
    final reducedTranslations = tester
        .widgetList<FractionalTranslation>(find.byType(FractionalTranslation))
        .where((w) => w.translation != Offset.zero)
        .toList();
    expect(reducedTranslations, isEmpty);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('AppTheme uses SmoothMenuPageTransitionsBuilder and honors reduced motion',
      (WidgetTester tester) async {
    Widget buildNavApp({required bool disableAnimations}) {
      return MediaQuery(
        data: MediaQueryData(
          size: const Size(375, 900),
          disableAnimations: disableAnimations,
        ),
        child: MaterialApp(
          key: ValueKey('nav_app_$disableAnimations'),
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(
                          body: Center(child: Text('Detail Menu Tujuan')),
                        ),
                      ),
                    );
                  },
                  child: const Text('Buka Menu'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    expect(
      AppTheme.lightTheme.pageTransitionsTheme.builders[TargetPlatform.android],
      isA<SmoothMenuPageTransitionsBuilder>(),
    );
    expect(
      AppTheme.lightTheme.pageTransitionsTheme.builders[TargetPlatform.iOS],
      isA<SmoothMenuPageTransitionsBuilder>(),
    );

    await tester.pumpWidget(buildNavApp(disableAnimations: false));
    await tester.tap(find.text('Buka Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(SlideTransition), findsWidgets);
    await tester.pumpAndSettle();
    expect(find.text('Detail Menu Tujuan'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(buildNavApp(disableAnimations: true));
    await tester.tap(find.text('Buka Menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(FadeTransition), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Detail Menu Tujuan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
