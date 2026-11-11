import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_app/core/constants/app_dimensions.dart';
import 'package:mobile_app/core/network/api_client.dart';
import 'package:mobile_app/core/network/api_exception.dart';
import 'package:mobile_app/core/network/network_provider.dart';
import 'package:mobile_app/features/attendance/data/attendance_models.dart';
import 'package:mobile_app/features/attendance/provider/attendance_provider.dart';
import 'package:mobile_app/features/auth/data/auth_repository.dart';
import 'package:mobile_app/features/auth/provider/auth_provider.dart';
import 'package:mobile_app/features/home/presentation/home_dashboard_view.dart';
import 'package:mobile_app/features/notification/data/notification_model.dart';
import 'package:mobile_app/features/notification/data/notification_repository.dart';
import 'package:mobile_app/features/notification/presentation/notification_sheet.dart';
import 'package:mobile_app/features/notification/provider/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubHttpAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _StubHttpAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      handler(options);

  @override
  void close({bool force = false}) {}
}

class _DummyApiClient extends Fake implements ApiClient {}

class _FakeAuthRepo extends AuthRepository {
  _FakeAuthRepo() : super(_DummyApiClient());

  @override
  Future<void> logout() async {}

  @override
  Future<Map<String, dynamic>> getProfile() async => {};
}

class _StatefulNotificationRepo extends NotificationRepository {
  List<NotificationModel> items;
  int countCalls = 0;
  int markReadCalls = 0;
  int markAllCalls = 0;
  int deleteCalls = 0;
  bool failNextDelete = false;
  Object? failNextMarkAllError;
  int Function()? customUnreadCount;

  _StatefulNotificationRepo(
    this.items, {
    this.customUnreadCount,
  }) : super(_DummyApiClient());

  @override
  int? get lastUnreadCount => items.where((n) => !n.isRead).length;

  @override
  Future<int> getUnreadCount() async {
    countCalls++;
    if (customUnreadCount != null) return customUnreadCount!();
    return items.where((n) => !n.isRead).length;
  }

  @override
  Future<List<NotificationModel>> getNotifications({int perPage = 30}) async {
    return List<NotificationModel>.from(items);
  }

  @override
  Future<void> markAsRead(int id) async {
    markReadCalls++;
    items = items
        .map((n) => n.idNotifications == id ? n.copyWith(isRead: true) : n)
        .toList();
  }

  @override
  Future<void> markAllAsRead() async {
    markAllCalls++;
    final err = failNextMarkAllError;
    if (err != null) {
      failNextMarkAllError = null;
      throw err;
    }
    items = items.map((n) => n.copyWith(isRead: true)).toList();
  }

  @override
  Future<void> deleteNotification(int id) async {
    deleteCalls++;
    if (failNextDelete) {
      failNextDelete = false;
      throw Exception('Network error');
    }
    items = items.where((n) => n.idNotifications != id).toList();
  }
}

ResponseBody _jsonResponse(Map<String, dynamic> body, [int statusCode = 200]) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
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

  group('NotificationModel parsing', () {
    test('handles PHP empty array data [], missing ids, numeric strings, and time_ago', () {
      final model = NotificationModel.fromJson({
        'id_notifications': '103',
        'type': 'overtime',
        'title': 'Pengajuan Lembur Disetujui',
        'message': 'Lembur disetujui.',
        'data': <dynamic>[],
        'is_read': 1,
        'time_ago': '5 menit yang lalu',
      });

      expect(model.idNotifications, 103);
      expect(model.idCompanies, 0);
      expect(model.idUsers, 0);
      expect(model.data, isNull);
      expect(model.isRead, isTrue);
      expect(model.typeLabel, 'LEMBUR');
      expect(model.displayTime, '5 menit yang lalu');
    });
  });

  group('NotificationRepository with real ApiClient unwrapping', () {
    test('reads getUnreadCount and getNotifications from unwrapped Laravel response', () async {
      final calls = <String>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
      dio.httpClientAdapter = _StubHttpAdapter((options) async {
        calls.add('${options.method} ${options.path}');
        if (options.path.endsWith('/notifications/unread-count')) {
          return _jsonResponse({
            'success': true,
            'message': 'OK',
            'data': {'unread_count': 10},
            'errors': null,
          });
        }
        if (options.path.endsWith('/notifications')) {
          return _jsonResponse({
            'success': true,
            'message': 'OK',
            'data': {
              'unread_count': 10,
              'notifications': [
                {
                  'id_notifications': 103,
                  'id_companies': 1,
                  'id_users': 4,
                  'type': 'overtime',
                  'title': 'Pengajuan Lembur Disetujui',
                  'message': 'Lembur Anda disetujui.',
                  'data': {'url': '/overtime', 'status': 'approved'},
                  'is_read': false,
                  'read_at': null,
                  'created_at': '2026-11-11T10:00:00Z',
                  'time_ago': '6 menit yang lalu',
                },
              ],
              'pagination': {'current_page': 1, 'per_page': 30, 'total': 10, 'last_page': 1},
            },
            'errors': null,
          });
        }
        return _jsonResponse({
          'success': true,
          'message': 'OK',
          'data': {'unread_count': 9},
          'errors': null,
        });
      });

      final client = ApiClient(dio: dio);
      final repo = NotificationRepository(client);

      final count = await repo.getUnreadCount();
      expect(count, 10);

      final list = await repo.getNotifications();
      expect(list.length, 1);
      expect(list.first.idNotifications, 103);
      expect(list.first.type, 'overtime');
      expect(list.first.data?['url'], '/overtime');
      expect(list.first.timeAgo, '6 menit yang lalu');
      expect(repo.lastUnreadCount, 10);

      await repo.markAsRead(103);
      await repo.markAllAsRead();
      await repo.deleteNotification(103);
      expect(
        calls,
        containsAllInOrder([
          'GET /notifications/unread-count',
          'GET /notifications',
          'PUT /notifications/103/read',
          'PUT /notifications/read-all',
          'DELETE /notifications/103',
        ]),
      );
    });
  });

  group('Auth-scoped unread count provider', () {
    test('returns 0 when unauthenticated and isolates counts per user switch', () async {
      final authRepo = _FakeAuthRepo();
      late AuthNotifier authNotifier;
      int currentUserId = 0;

      final repo = _StatefulNotificationRepo(
        [],
        customUnreadCount: () => currentUserId == 4 ? 10 : (currentUserId == 3 ? 30 : 0),
      );

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(_DummyApiClient()),
          authRepositoryProvider.overrideWithValue(authRepo),
          notificationRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith((ref) {
            authNotifier = AuthNotifier(authRepo, ref);
            return authNotifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      // 1. Unauthenticated -> 0 without hitting repo
      expect(await container.read(unreadNotificationCountProvider.future), 0);
      expect(repo.countCalls, 0);

      // 2. Logged in as Budi (user 4) -> 10
      currentUserId = 4;
      authNotifier.state = const AuthState(
        status: AuthStatus.authenticated,
        user: {'id_users': 4, 'name': 'Budi', 'role': 'employee'},
      );
      expect(await container.read(unreadNotificationCountProvider.future), 10);
      expect(repo.countCalls, 1);

      // 3. Switch account to Norman (user 3) -> 30
      currentUserId = 3;
      authNotifier.state = const AuthState(
        status: AuthStatus.authenticated,
        user: {'id_users': 3, 'name': 'Norman', 'role': 'manager'},
      );
      expect(await container.read(unreadNotificationCountProvider.future), 30);
      expect(repo.countCalls, 2);

      // 4. Logout -> back to 0 without hitting repo
      currentUserId = 0;
      authNotifier.state = const AuthState(status: AuthStatus.unauthenticated);
      expect(await container.read(unreadNotificationCountProvider.future), 0);
      expect(repo.countCalls, 2);
    });
  });

  group('NotificationListNotifier resilience', () {
    test('markAllAsRead without Ref does not roll back committed server update and surfaces ApiException on failure', () async {
      final repo = _StatefulNotificationRepo([
        NotificationModel(
          idNotifications: 201,
          idCompanies: 1,
          idUsers: 3,
          type: 'overtime',
          title: 'Pengajuan Lembur Baru',
          message: 'Menunggu persetujuan.',
          isRead: false,
        ),
      ]);

      final notifier = NotificationListNotifier(repo);
      await notifier.fetchNotifications();
      expect(notifier.state.unreadCount, 1);

      repo.failNextMarkAllError = const NetworkException();
      await notifier.markAllAsRead();
      expect(notifier.state.unreadCount, 1);
      expect(
        notifier.state.actionErrorMessage,
        'Koneksi jaringan terputus. Periksa sambungan internet.',
      );

      await notifier.markAllAsRead();
      expect(notifier.state.unreadCount, 0);
      expect(notifier.state.actionErrorMessage, isNull);
      expect(notifier.state.notifications.every((n) => n.isRead), isTrue);
    });
  });

  group('NotificationSheet and HomeDashboardView integration', () {
    List<NotificationModel> sampleItems() => [
          NotificationModel(
            idNotifications: 101,
            idCompanies: 1,
            idUsers: 4,
            type: 'overtime',
            title: 'Pengajuan Lembur Disetujui',
            message: 'Lembur tanggal 16 Nov telah disetujui.',
            data: const {'url': '/overtime'},
            isRead: false,
            timeAgo: '5 menit lalu',
          ),
          NotificationModel(
            idNotifications: 102,
            idCompanies: 1,
            idUsers: 4,
            type: 'leave',
            title: 'Pengajuan Cuti Disetujui',
            message: 'Cuti tahunan telah disetujui.',
            data: const {'url': '/leaves'},
            isRead: false,
            timeAgo: '10 menit lalu',
          ),
          NotificationModel(
            idNotifications: 103,
            idCompanies: 1,
            idUsers: 4,
            type: 'payroll',
            title: 'Slip Gaji Tersedia',
            message: 'Slip gaji November sudah terbit.',
            data: const {'url': '/payroll'},
            isRead: true,
            timeAgo: '1 jam lalu',
          ),
        ];

    testWidgets('filters, routes tabs correctly, deletes with rollback on error, and updates badge',
        (tester) async {
      final authRepo = _FakeAuthRepo();
      final repo = _StatefulNotificationRepo(sampleItems());
      final navigatedTabs = <int>[];

      Future<void> pumpBellAndSheet(Size size, {double textScale = 1.0}) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(authRepo),
              authStateProvider.overrideWith((ref) {
                final n = AuthNotifier(authRepo, ref);
                n.state = const AuthState(
                  status: AuthStatus.authenticated,
                  user: {
                    'id_users': 4,
                    'name': 'Budi',
                    'role': 'employee',
                    'company': {'id_companies': 1, 'name': 'PT SPINDO'},
                  },
                );
                return n;
              }),
              notificationRepositoryProvider.overrideWithValue(repo),
              todayAttendanceProvider.overrideWith(
                (ref) async => const TodayAttendanceData(
                  date: '2026-11-11',
                  shiftName: 'Shift Reguler',
                  startTime: '08:00',
                  endTime: '17:00',
                  lateToleranceMinutes: 15,
                  status: 'Belum Hadir',
                ),
              ),
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
                  onNavigateToTab: navigatedTabs.add,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      // 1. Home bell badge shows '2' unread
      await pumpBellAndSheet(const Size(375, 900));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('home_notification_bell_btn')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // 2. Open NotificationSheet by tapping bell
      await tester.tap(find.byKey(const Key('home_notification_bell_btn')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('2 Baru'), findsOneWidget);
      expect(find.text('LEMBUR · 5 menit lalu'), findsOneWidget);
      expect(find.text('CUTI · 10 menit lalu'), findsOneWidget);
      expect(find.text('PENGGAJIAN · 1 jam lalu'), findsOneWidget);

      // 3. Touch targets >= 48px on filter tabs and delete icon
      expect(
        tester.getSize(find.byKey(const Key('notif_tab_all'))).height,
        greaterThanOrEqualTo(AppDimensions.minTouchTarget),
      );
      expect(
        tester.getSize(find.byKey(const Key('notif_tab_unread'))).height,
        greaterThanOrEqualTo(AppDimensions.minTouchTarget),
      );
      expect(
        tester.getSize(find.byKey(const Key('notif_delete_101'))).height,
        greaterThanOrEqualTo(AppDimensions.minTouchTarget),
      );

      // 4. Filter to Belum Dibaca hides read payroll item
      await tester.tap(find.byKey(const Key('notif_tab_unread')));
      await tester.pumpAndSettle();
      expect(find.text('Slip Gaji Tersedia'), findsNothing);
      expect(find.text('Pengajuan Lembur Disetujui'), findsOneWidget);

      // 5. Failed delete rolls back item and displays error message
      repo.failNextDelete = true;
      await tester.tap(find.byKey(const Key('notif_delete_102')));
      await tester.pumpAndSettle();
      expect(find.text('Pengajuan Cuti Disetujui'), findsOneWidget);
      expect(find.text('Gagal menghapus notifikasi. Silakan coba lagi.'), findsOneWidget);

      // 6. Successful delete removes item & updates unread count to 1
      await tester.tap(find.byKey(const Key('notif_delete_102')));
      await tester.pumpAndSettle();
      expect(find.text('Pengajuan Cuti Disetujui'), findsNothing);
      expect(find.text('1 Baru'), findsOneWidget);

      // 7. Tap overtime item -> marks read, closes sheet, navigates to tab 1, badge gone!
      await tester.tap(find.byKey(const Key('notif_item_101')));
      await tester.pumpAndSettle();
      expect(repo.markReadCalls, 1);
      expect(navigatedTabs.last, 1);
      expect(find.text('2 Baru'), findsNothing);
      expect(find.byType(NotificationSheet), findsNothing);
      // Unread count is now 0 -> no '1' or '2' badge pill on bell
      expect(
        find.descendant(
          of: find.byKey(const Key('home_notification_bell_btn')),
          matching: find.text('1'),
        ),
        findsNothing,
      );

      // 8. Check narrow 300px @ 1.3x scale with leave & payroll navigation + mark all read
      repo.items = sampleItems();
      await pumpBellAndSheet(const Size(300, 900), textScale: 1.3);
      await tester.tap(find.byKey(const Key('home_notification_bell_btn')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('notif_mark_all_btn')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('notif_mark_all_btn'))).height,
        greaterThanOrEqualTo(AppDimensions.minTouchTarget),
      );

      await tester.tap(find.byKey(const Key('notif_item_102')));
      await tester.pumpAndSettle();
      expect(navigatedTabs.last, 2); // Cuti tab = 2

      await tester.tap(find.byKey(const Key('home_notification_bell_btn')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('notif_item_103')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notif_item_103')));
      await tester.pumpAndSettle();
      expect(navigatedTabs.last, 3); // Gaji tab = 3

      // 9. Mark all as read while on Unread filter -> clears badge & shows empty state
      await tester.tap(find.byKey(const Key('home_notification_bell_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notif_tab_unread')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('notif_mark_all_btn')));
      await tester.pumpAndSettle();
      expect(repo.markAllCalls, 1);
      expect(find.text('Tidak Ada Notifikasi Baru'), findsOneWidget);
      await tester.tap(find.byKey(const Key('notif_close_btn')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('home_notification_bell_btn')),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
    });
  });
}
