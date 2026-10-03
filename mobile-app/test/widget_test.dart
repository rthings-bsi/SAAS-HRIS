import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/home/presentation/home_screen.dart';
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

  testWidgets('HomeScreen drawer logout closes drawer and triggers logout', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffoldState = tester.firstState<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Keluar dari Akun'), findsOneWidget);
    await tester.tap(find.text('Keluar dari Akun'));
    await tester.pumpAndSettle();

    expect(find.text('Keluar dari Akun'), findsNothing);
  });
}
