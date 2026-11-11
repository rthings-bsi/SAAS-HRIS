import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../data/attendance_models.dart';
import '../provider/attendance_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  String _formatDisplayDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(attendanceHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: const Text(
          'Riwayat Kehadiran',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.inkPrimary,
            letterSpacing: -0.3,
          ),
        ),
        elevation: 0,
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: LayoutBuilder(
            builder: (context, viewportConstraints) {
              final double hPad = viewportConstraints.maxWidth < 310
                  ? 12
                  : (viewportConstraints.maxWidth < 470
                      ? AppDimensions.space16
                      : 20);

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(attendanceHistoryProvider);
                },
                child: historyAsync.when(
                  loading: () => ListView.separated(
                    padding: EdgeInsets.all(hPad),
                    itemCount: 6,
                    separatorBuilder: (_, index) =>
                        const SizedBox(height: AppDimensions.space8),
                    itemBuilder: (_, index) => const AppSkeleton(height: 72),
                  ),
                  error: (error, _) => Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.all(hPad),
                        child: AppErrorState(
                          isCard: true,
                          title: 'Gagal Memuat Riwayat',
                          message: 'Gagal memuat riwayat kehadiran.',
                          retryText: 'Coba Lagi',
                          onRetry: () =>
                              ref.invalidate(attendanceHistoryProvider),
                        ),
                      ),
                    ),
                  ),
                  data: (records) {
                    if (records.isEmpty) {
                      return Center(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.all(hPad),
                            child: const AppEmptyState(
                              icon: LucideIcons.history,
                              title: 'Belum Ada Riwayat',
                              description:
                                  'Belum ada riwayat kehadiran tercatat.',
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(hPad),
                      itemCount: records.length,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: AppDimensions.space8),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final badge = record.badgeStatus;
                        final dateLabel = _formatDisplayDate(record.date);
                        final clockInLabel = record.clockIn ?? '--:--';
                        final clockOutLabel = record.clockOut ?? '--:--';

                        return Container(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.borderSubtle,
                              width: 1.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x04000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldTint,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  LucideIcons.calendar,
                                  size: 18,
                                  color: AppColors.actionAccent,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          dateLabel,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.inkPrimary,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: AppDimensions.space4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badge.backgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            badge.label,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: badge.textColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 2,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Masuk ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.inkMuted,
                                              ),
                                            ),
                                            Text(
                                              clockInLabel,
                                              style: AppTextStyle.time(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text(
                                              'Pulang ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.inkMuted,
                                              ),
                                            ),
                                            Text(
                                              clockOutLabel,
                                              style: AppTextStyle.time(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
