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
}
