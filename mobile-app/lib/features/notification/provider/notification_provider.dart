import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../data/notification_model.dart';
import '../data/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return NotificationRepository(client);
});

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final authStatus = ref.watch(authStateProvider.select((s) => s.status));
  // Re-evaluate badge count whenever authenticated user changes across login/switch.
  final userKey = ref.watch(
    authStateProvider.select(
      (s) => s.user?['id_users'] ?? s.user?['id'] ?? s.user?['email'],
    ),
  );

  if (authStatus != AuthStatus.authenticated || userKey == null) {
    return 0;
  }

  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount();
});

class NotificationListState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? errorMessage;
  final String? actionErrorMessage;

  const NotificationListState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
    this.actionErrorMessage,
  });

  NotificationListState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? errorMessage,
    bool clearError = false,
    String? actionErrorMessage,
    bool clearActionError = false,
  }) {
    return NotificationListState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actionErrorMessage: clearActionError
          ? null
          : (actionErrorMessage ?? this.actionErrorMessage),
    );
  }
}

class NotificationListNotifier extends StateNotifier<NotificationListState> {
  final NotificationRepository _repository;
  final Ref? _ref;

  NotificationListNotifier(this._repository, [this._ref])
      : super(const NotificationListState());

  void _invalidateUnreadBadge() {
    if (!mounted) return;
    final ref = _ref;
    if (ref == null) return;
    try {
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {
      // Badge count is also refreshed when NotificationSheet closes.
    }
  }

  String _formatActionError(Object error, String fallback) {
    if (error is ApiException) {
      final msg = error.userFriendlyMessage.trim();
      if (msg.isNotEmpty) return msg;
    }
    return fallback;
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearActionError: true,
    );
    try {
      final list = await _repository.getNotifications();
      if (!mounted) return;
      final serverUnread = _repository.lastUnreadCount;
      final unread = serverUnread ?? list.where((n) => !n.isRead).length;
      state = state.copyWith(
        isLoading: false,
        notifications: list,
        unreadCount: unread,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: _formatActionError(
          e,
          'Gagal memuat notifikasi. Silakan periksa koneksi Anda.',
        ),
      );
      return;
    }
    _invalidateUnreadBadge();
  }

  void clearActionError() {
    if (!mounted || state.actionErrorMessage == null) return;
    state = state.copyWith(clearActionError: true);
  }

  Future<void> markAsRead(int id) async {
    final targetIndex =
        state.notifications.indexWhere((n) => n.idNotifications == id);
    if (targetIndex == -1 || state.notifications[targetIndex].isRead) return;

    final previous = state;
    final updated = state.notifications.map((n) {
      if (n.idNotifications == id) {
        return n.copyWith(isRead: true, readAt: DateTime.now().toIso8601String());
      }
      return n;
    }).toList();

    state = state.copyWith(
      notifications: updated,
      unreadCount: (state.unreadCount - 1).clamp(0, 999999),
      clearActionError: true,
    );

    try {
      await _repository.markAsRead(id);
    } catch (e) {
      if (!mounted) return;
      state = previous.copyWith(
        actionErrorMessage: _formatActionError(
          e,
          'Gagal memperbarui status notifikasi. Silakan coba lagi.',
        ),
      );
      return;
    }
    _invalidateUnreadBadge();
  }

  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0 && state.notifications.every((n) => n.isRead)) {
      return;
    }

    final previous = state;
    final updated = state.notifications.map((n) {
      if (n.isRead) return n;
      return n.copyWith(isRead: true, readAt: DateTime.now().toIso8601String());
    }).toList();

    state = state.copyWith(
      notifications: updated,
      unreadCount: 0,
      clearActionError: true,
    );

    try {
      await _repository.markAllAsRead();
    } catch (e) {
      if (!mounted) return;
      state = previous.copyWith(
        actionErrorMessage: _formatActionError(
          e,
          'Gagal menandai seluruh notifikasi sebagai dibaca.',
        ),
      );
      return;
    }
    _invalidateUnreadBadge();
  }

  Future<void> deleteNotification(int id) async {
    final targetIndex =
        state.notifications.indexWhere((n) => n.idNotifications == id);
    if (targetIndex == -1) return;

    final previous = state;
    final wasUnread = !state.notifications[targetIndex].isRead;
    final updated =
        state.notifications.where((n) => n.idNotifications != id).toList();

    state = state.copyWith(
      notifications: updated,
      unreadCount:
          wasUnread ? (state.unreadCount - 1).clamp(0, 999999) : state.unreadCount,
      clearActionError: true,
    );

    try {
      await _repository.deleteNotification(id);
    } catch (e) {
      if (!mounted) return;
      state = previous.copyWith(
        actionErrorMessage: _formatActionError(
          e,
          'Gagal menghapus notifikasi. Silakan coba lagi.',
        ),
      );
      return;
    }
    _invalidateUnreadBadge();
  }
}

final notificationListProvider =
    StateNotifierProvider.autoDispose<NotificationListNotifier, NotificationListState>((ref) {
  // Tie notification feed lifecycle to authenticated session so account switching never leaks old state.
  ref.watch(
    authStateProvider.select(
      (s) => '${s.status.name}:${s.user?['id_users'] ?? s.user?['id'] ?? ''}',
    ),
  );
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationListNotifier(repo, ref);
});
