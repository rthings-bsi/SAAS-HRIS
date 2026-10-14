import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../data/notification_model.dart';
import '../provider/notification_provider.dart';

class NotificationSheet extends ConsumerStatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const NotificationSheet({
    super.key,
    this.onNavigateToTab,
  });

  static void show(BuildContext context, {void Function(int tabIndex)? onNavigateToTab}) {
    showModalBottomSheet(
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
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationListProvider.notifier).fetchNotifications();
    });
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'leave':
        return Icons.calendar_today_rounded;
      case 'overtime':
        return Icons.access_time_rounded;
      case 'payroll':
        return Icons.account_balance_wallet_rounded;
      case 'attendance':
        return Icons.how_to_reg_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'leave':
        return AppColors.menuGreenIcon;
      case 'overtime':
        return const Color(0xFFD97706);
      case 'payroll':
        return AppColors.actionAccent;
      case 'attendance':
        return const Color(0xFF7C3AED);
      default:
        return AppColors.inkMuted;
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
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  void _handleItemTap(NotificationModel notif) {
    if (!notif.isRead) {
      ref.read(notificationListProvider.notifier).markAsRead(notif.idNotifications);
    }

    Navigator.pop(context);

    // Deep link or tab navigation
    final type = notif.type.toLowerCase();
    if (type == 'payroll' && widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(2);
    } else if (type == 'leave' && widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationListProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                    if (state.unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          '${state.unreadCount} Baru',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    if (state.unreadCount > 0)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(
                          Icons.done_all_rounded,
                          size: 16,
                          color: AppColors.actionAccent,
                        ),
                        label: const Text(
                          'Tandai Dibaca',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.actionAccent,
                          ),
                        ),
                        onPressed: () {
                          ref.read(notificationListProvider.notifier).markAllAsRead();
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

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

                if (state.errorMessage != null && state.notifications.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: AppColors.dangerText,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.actionAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Coba Lagi'),
                            onPressed: () {
                              ref.read(notificationListProvider.notifier).fetchNotifications();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state.notifications.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(
                              Icons.notifications_off_outlined,
                              size: 26,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum Ada Notifikasi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pemberitahuan terkait status cuti, lembur, dan slip gaji akan ditampilkan di sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: state.notifications.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final notif = state.notifications[index];
                    final icon = _getTypeIcon(notif.type);
                    final iconColor = _getTypeColor(notif.type);
                    final iconBg = _getTypeBgColor(notif.type);

                    return InkWell(
                      onTap: () => _handleItemTap(notif),
                      child: Container(
                        color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: iconBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: iconColor, size: 19),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                notif.isRead ? FontWeight.w600 : FontWeight.w700,
                                            color: AppColors.inkPrimary,
                                          ),
                                        ),
                                      ),
                                      if (!notif.isRead) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: AppColors.actionAccent,
                                            shape: BoxShape.circle,
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
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.type.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF94A3B8),
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
