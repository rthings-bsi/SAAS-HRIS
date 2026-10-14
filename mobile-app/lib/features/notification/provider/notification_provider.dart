import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/network_provider.dart';
import '../data/notification_model.dart';
import '../data/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationRepository(client);
});

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount();
});

class NotificationListState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? errorMessage;

  const NotificationListState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationListState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? errorMessage,
  }) {
    return NotificationListState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
    );
  }
}

class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final NotificationRepository _repository;

  NotificationListNotifier(this._repository) : super(const NotificationListState());

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getNotifications();
      final unread = list.where((n) => !n.isRead).length;
      state = state.copyWith(
        isLoading: false,
        notifications: list,
        unreadCount: unread,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat notifikasi. Silakan periksa koneksi Anda.',
      );
    }
  }

  Future<void> markAsRead(int id) async {
    final updated = state.notifications.map((n) {
      if (n.idNotifications == id) {
        return n.copyWith(isRead: true, readAt: DateTime.now().toIso8601String());
      }
      return n;
    }).toList();

    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => !n.isRead).length,
    );

    try {
      await _repository.markAsRead(id);
    } catch (_) {
      // Non-blocking
    }
  }

  Future<void> markAllAsRead() async {
    final updated = state.notifications.map((n) {
      return n.copyWith(isRead: true, readAt: DateTime.now().toIso8601String());
    }).toList();

    state = state.copyWith(
      notifications: updated,
      unreadCount: 0,
    );

    try {
      await _repository.markAllAsRead();
    } catch (_) {
      // Non-blocking
    }
  }

  Future<void> deleteNotification(int id) async {
    final updated = state.notifications.where((n) => n.idNotifications != id).toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount: updated.where((n) => !n.isRead).length,
    );

    try {
      await _repository.deleteNotification(id);
    } catch (_) {
      // Non-blocking
    }
  }
}

final notificationListProvider =
    StateNotifierProvider.autoDispose<NotificationListNotifier, NotificationListState>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationListNotifier(repo);
});
