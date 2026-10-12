import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/widgets/app_empty_state.dart';
import 'package:mobile_app/features/home/presentation/features_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({void Function(int)? onNavigateToTab}) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: FeaturesScreen(
            onNavigateToTab: onNavigateToTab,
          ),
        ),
      ),
    );
  }

  testWidgets('FeaturesScreen renders header, banners, and grid items correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Check Header and Search Bar
    expect(find.text('Features'), findsWidgets);
    expect(find.text('Search Features'), findsOneWidget);

    // Check Section Banners
    expect(find.text('Core'), findsOneWidget);
    expect(find.text('Time Attendance'), findsOneWidget);

    // Check Categories
    expect(find.text('Company'), findsOneWidget);
    expect(find.text('Employee'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Leave'), findsOneWidget);

    // Check Items in Company
    expect(find.text('Company Profile'), findsOneWidget);
    expect(find.text('Policy'), findsOneWidget);
    expect(find.text('Announcement'), findsOneWidget);
    expect(find.text('Organization Structure'), findsOneWidget);

    // Check Items in Employee
    expect(find.text('Personal Data'), findsOneWidget);
    expect(find.text('Employee Request'), findsOneWidget);

    // Check Attendance items
    expect(find.text('Attendance List'), findsOneWidget);
    expect(find.text('Attendance Report'), findsOneWidget);

    // Check Leave items
    expect(find.text('Leave Request'), findsOneWidget);
    expect(find.text('Leave Balance'), findsOneWidget);
  });

  testWidgets('FeaturesScreen search filters items and shows empty state when none match', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Enter search query that matches 'Policy'
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Policy');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InkWell, 'Policy'), findsOneWidget);
    expect(find.text('Announcement'), findsNothing);

    // Clear search
    final clearButton = find.byIcon(Icons.close);
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    expect(find.text('Announcement'), findsOneWidget);

    // Enter search query that matches nothing
    await tester.enterText(searchField, 'xyzunknownfeature');
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('Fitur Tidak Ditemukan'), findsOneWidget);
  });

  testWidgets('FeaturesScreen toggle between grid and list views', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Switch to list view (find icon format_list_bulleted_rounded)
    final listToggle = find.byIcon(Icons.format_list_bulleted_rounded);
    expect(listToggle, findsOneWidget);
    await tester.tap(listToggle);
    await tester.pumpAndSettle();

    // Items still visible in list mode
    expect(find.text('Company Profile'), findsOneWidget);
    expect(find.text('Personal Data'), findsOneWidget);

    // Switch back to grid view
    final gridToggle = find.byIcon(Icons.grid_view_rounded);
    expect(gridToggle, findsOneWidget);
    await tester.tap(gridToggle);
    await tester.pumpAndSettle();

    expect(find.text('Company Profile'), findsOneWidget);
  });

  testWidgets('FeaturesScreen tapping Company Profile opens bottom sheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    final companyProfileItem = find.text('Company Profile');
    expect(companyProfileItem, findsOneWidget);
    await tester.tap(companyProfileItem);
    await tester.pumpAndSettle();

    // Bottom sheet should be visible with Profil Perusahaan
    expect(find.text('Profil Resmi Perusahaan'), findsOneWidget);
  });
}
