import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../attendance/presentation/history_screen.dart';
import '../data/notification_model.dart';
import '../provider/notification_provider.dart';

enum _NotificationFilter { all, unread }

class NotificationSheet extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const NotificationSheet({
    super.key,
    this.onNavigateToTab,
  });

  static Future<void> show(
    BuildContext context, {
    void Function(int tabIndex)? onNavigateToTab,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NotificationSheet(onNavigateToTab: onNavigateToTab),
    );
  }

  @override
  ConsumerState<NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends ConsumerState<NotificationSheet> {
  _NotificationFilter _activeFilter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(notificationListProvider.notifier).fetchNotifications();
      }
    });
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'leave':
        return LucideIcons.calendar;
      case 'overtime':
        return LucideIcons.clock;
      case 'payroll':
        return LucideIcons.wallet;
      case 'attendance':
        return LucideIcons.userCheck;
      case 'performance':
        return LucideIcons.award;
      default:
        return LucideIcons.bell;
    }
  }

  // Contrast-verified (>= 4.5:1) foreground colors paired with _getTypeBgColor.
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'leave':
        return const Color(0xFF047857);
      case 'overtime':
        return const Color(0xFF92400E);
      case 'payroll':
        return AppColors.actionAccent;
      case 'attendance':
        return const Color(0xFF6D28D9);
      case 'performance':
        return const Color(0xFF4338CA);
      default:
        return const Color(0xFF475569);
    }
  }

  Color _getTypeBgColor(String type) {
    switch (type.toLowerCase()) {
      case 'leave':
        return AppColors.menuGreenBg;
      case 'overtime':
        return const Color(0xFFFEF3C7);
      case 'payroll':
        return const Color(0xFFEFF6FF);
      case 'attendance':
        return const Color(0xFFF3E8FF);
      case 'performance':
        return const Color(0xFFEEF2FF);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Future<void> _handleItemTap(NotificationModel notif) async {
    final type = notif.type.toLowerCase();
    final url = (notif.data?['url']?.toString() ?? '').toLowerCase();

    if (!notif.isRead) {
      await ref
          .read(notificationListProvider.notifier)
          .markAsRead(notif.idNotifications);
    }

    if (!mounted) return;
    final navigator = Navigator.of(context);
    final navigateToTab = widget.onNavigateToTab;
    navigator.pop();

    // HomeScreen tabs: 0=Beranda, 1=Lembur, 2=Cuti, 3=Gaji, 4=Profil
    if (type == 'overtime' || url.startsWith('/overtime')) {
      navigateToTab?.call(1);
    } else if (type == 'leave' || url.startsWith('/leave')) {
      navigateToTab?.call(2);
    } else if (type == 'payroll' || url.startsWith('/payroll')) {
      navigateToTab?.call(3);
    } else if (type == 'attendance' || url.startsWith('/attendance')) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => const HistoryScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);
    final displayed = _activeFilter == _NotificationFilter.unread
        ? state.notifications.where((n) => !n.isRead).toList()
        : state.notifications;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 12, 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Notifikasi',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkPrimary,
                              ),
                            ),
                            if (state.unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${state.unreadCount} Baru',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('notif_close_btn'),
                        icon: const Icon(
                          LucideIcons.x,
                          size: 20,
                          color: Color(0xFF475569),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: AppDimensions.minTouchTarget,
                          minHeight: AppDimensions.minTouchTarget,
                        ),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Tutup',
                      ),
                    ],
                  ),
                ),

                // Filter & action bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _FilterTabButton(
                            key: const Key('notif_tab_all'),
                            label: state.isLoading && state.notifications.isEmpty
                                ? 'Semua'
                                : 'Semua (${state.notifications.length})',
                            selected: _activeFilter == _NotificationFilter.all,
                            onTap: () => setState(() {
                              _activeFilter = _NotificationFilter.all;
                            }),
                          ),
                          _FilterTabButton(
                            key: const Key('notif_tab_unread'),
                            label: 'Belum Dibaca (${state.unreadCount})',
                            selected:
                                _activeFilter == _NotificationFilter.unread,
                            onTap: () => setState(() {
                              _activeFilter = _NotificationFilter.unread;
                            }),
                          ),
                        ],
                      ),
                      if (state.unreadCount > 0)
                        TextButton(
                          key: const Key('notif_mark_all_btn'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            minimumSize: const Size(
                              0,
                              AppDimensions.minTouchTarget,
                            ),
                          ),
                          onPressed: () async {
                            await ref
                                .read(notificationListProvider.notifier)
                                .markAllAsRead();
                            if (context.mounted) {
                              ref.invalidate(unreadNotificationCountProvider);
                            }
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.checkCheck,
                                size: 16,
                                color: AppColors.actionAccent,
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Tandai Dibaca',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.actionAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),

                // Non-blocking error feedback for failed read/delete mutations
                if (state.actionErrorMessage != null)
                  Container(
                    color: const Color(0xFFFEF2F2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.circleAlert,
                          size: 16,
                          color: Color(0xFFB91C1C),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.actionErrorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            size: 16,
                            color: Color(0xFFB91C1C),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: AppDimensions.minTouchTarget,
                            minHeight: AppDimensions.minTouchTarget,
                          ),
                          tooltip: 'Tutup pesan galat',
                          onPressed: () {
                            ref
                                .read(notificationListProvider.notifier)
                                .clearActionError();
                          },
                        ),
                      ],
                    ),
                  ),

                // Body
                Flexible(
                  child: Builder(
                    builder: (context) {
                      if (state.isLoading && state.notifications.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.actionAccent,
                            ),
                          ),
                        );
                      }

                      if (state.errorMessage != null &&
                          state.notifications.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(28),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.circleAlert,
                                  size: 40,
                                  color: Color(0xFFB91C1C),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  state.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.actionAccent,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(
                                      0,
                                      AppDimensions.minTouchTarget,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                                  label: const Text('Coba Lagi'),
                                  onPressed: () {
                                    ref
                                        .read(notificationListProvider.notifier)
                                        .fetchNotifications();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      if (displayed.isEmpty) {
                        final isUnreadFilter =
                            _activeFilter == _NotificationFilter.unread;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 44,
                            horizontal: 24,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    isUnreadFilter
                                        ? LucideIcons.checkCheck
                                        : LucideIcons.bellOff,
                                    size: 26,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  isUnreadFilter
                                      ? 'Tidak Ada Notifikasi Baru'
                                      : 'Belum Ada Notifikasi',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isUnreadFilter
                                      ? 'Seluruh pemberitahuan operasional telah Anda baca.'
                                      : 'Pemberitahuan terkait status cuti, lembur, dan slip gaji akan ditampilkan di sini.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF475569),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: AppColors.actionAccent,
                        onRefresh: () => ref
                            .read(notificationListProvider.notifier)
                            .fetchNotifications(),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: displayed.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            indent: 64,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (context, index) {
                            final notif = displayed[index];
                            final icon = _getTypeIcon(notif.type);
                            final iconColor = _getTypeColor(notif.type);
                            final iconBg = _getTypeBgColor(notif.type);
                            final timeLabel = notif.displayTime;

                            return Container(
                              color: notif.isRead
                                  ? Colors.white
                                  : const Color(0xFFF0FDF4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      key: Key('notif_item_${notif.idNotifications}'),
                                      onTap: () => _handleItemTap(notif),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: AppDimensions.minTouchTarget,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            12,
                                            8,
                                            12,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  color: iconBg,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  icon,
                                                  color: iconColor,
                                                  size: 19,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      timeLabel.isNotEmpty
                                                          ? '${notif.typeLabel} · $timeLabel'
                                                          : notif.typeLabel,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Color(0xFF475569),
                                                        letterSpacing: 0.3,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            notif.title,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  notif.isRead
                                                                      ? FontWeight
                                                                          .w600
                                                                      : FontWeight
                                                                          .w700,
                                                              color: AppColors
                                                                  .inkPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                        if (!notif.isRead) ...[
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Container(
                                                            width: 8,
                                                            height: 8,
                                                            decoration:
                                                                const BoxDecoration(
                                                              color: AppColors
                                                                  .actionAccent,
                                                              shape:
                                                                  BoxShape.circle,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      notif.message,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Color(0xFF475569),
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 6,
                                      right: 4,
                                    ),
                                    child: IconButton(
                                      key: Key('notif_delete_${notif.idNotifications}'),
                                      icon: const Icon(
                                        LucideIcons.trash2,
                                        size: 17,
                                        color: Color(0xFF475569),
                                      ),
                                      tooltip: 'Hapus notifikasi',
                                      constraints: const BoxConstraints(
                                        minWidth: AppDimensions.minTouchTarget,
                                        minHeight: AppDimensions.minTouchTarget,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(notificationListProvider
                                                .notifier)
                                            .deleteNotification(
                                              notif.idNotifications,
                                            );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF0B2545) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppDimensions.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Center(
              widthFactor: 1.0,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
