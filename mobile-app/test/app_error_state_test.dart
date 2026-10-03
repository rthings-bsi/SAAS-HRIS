import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/widgets/app_error_state.dart';

void main() {
  group('AppErrorState Message Formatting & Sanitation', () {
    test('strips ApiException wrapper and extracts inner message', () {
      const raw = 'ApiException(statusCode: 404, message: Server unavailable, errors: null)';
      final cleaned = AppErrorState.cleanErrorMessage(raw);
      expect(cleaned, 'Server unavailable');
    });

    test('strips DioException wrapper', () {
      const raw = 'DioException [bad response]: Koneksi gagal';
      final cleaned = AppErrorState.cleanErrorMessage(raw);
      expect(cleaned, 'Koneksi gagal');
    });

    test('strips Exception: prefix', () {
      const raw = 'Exception: Gagal terhubung ke server';
      final cleaned = AppErrorState.cleanErrorMessage(raw);
      expect(cleaned, 'Gagal terhubung ke server');
    });

    test('formats "Profil karyawan tidak ditemukan." into helpful friendly message', () {
      const raw = 'ApiException(statusCode: 404, message: Profil karyawan tidak ditemukan., errors: null)';
      final cleaned = AppErrorState.cleanErrorMessage(raw);
      expect(
        cleaned,
        'Profil karyawan Anda belum terhubung atau belum didaftarkan di sistem. Hubungi bagian HR/Admin perusahaan Anda.',
      );
    });

    test('formats raw "Profil karyawan tidak ditemukan." directly', () {
      const raw = 'Profil karyawan tidak ditemukan.';
      final cleaned = AppErrorState.cleanErrorMessage(raw);
      expect(
        cleaned,
        'Profil karyawan Anda belum terhubung atau belum didaftarkan di sistem. Hubungi bagian HR/Admin perusahaan Anda.',
      );
    });
  });

  group('AppErrorState UI & Touch Target', () {
    testWidgets('renders clean error card when isCard is true with >= 48px touch target retry button', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorState(
              isCard: true,
              title: 'Gagal Memuat Status Presensi',
              message: 'ApiException(statusCode: 404, message: Profil karyawan tidak ditemukan., errors: null)',
              retryText: 'Coba Lagi',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Gagal Memuat Status Presensi'), findsOneWidget);
      expect(
        find.text('Profil karyawan Anda belum terhubung atau belum didaftarkan di sistem. Hubungi bagian HR/Admin perusahaan Anda.'),
        findsOneWidget,
      );

      final retryBtnFinder = find.text('Coba Lagi');
      expect(retryBtnFinder, findsOneWidget);

      final btnSize = tester.getSize(find.ancestor(of: retryBtnFinder, matching: find.byType(InkWell)));
      expect(btnSize.height, greaterThanOrEqualTo(48.0));

      await tester.tap(retryBtnFinder);
      expect(retried, isTrue);
    });
  });
}
