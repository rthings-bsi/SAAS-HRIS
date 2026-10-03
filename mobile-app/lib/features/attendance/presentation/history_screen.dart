import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        title: const Text('Riwayat Kehadiran'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(attendanceHistoryProvider);
        },
        child: historyAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.space16),
            itemCount: 6,
            separatorBuilder: (_, index) => const SizedBox(height: AppDimensions.space8),
            itemBuilder: (_, index) => const AppSkeleton(height: 72),
          ),
          error: (error, _) => Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: AppErrorState(
                  isCard: true,
                  title: 'Gagal Memuat Riwayat',
                  message: 'Gagal memuat riwayat kehadiran.',
                  retryText: 'Coba Lagi',
                  onRetry: () => ref.invalidate(attendanceHistoryProvider),
                ),
              ),
            ),
          ),
          data: (records) {
            if (records.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: const AppEmptyState(
                    icon: Icons.history_rounded,
                    title: 'Belum Ada Riwayat',
                    description: 'Belum ada riwayat kehadiran tercatat.',
                  ),
                ),
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.space16),
              itemCount: records.length,
              separatorBuilder: (_, index) => const SizedBox(height: AppDimensions.space8),
              itemBuilder: (context, index) {
                final record = records[index];
                final badge = record.badgeStatus;
                final dateLabel = _formatDisplayDate(record.date);
                final clockInLabel = record.clockIn ?? '--:--';
                final clockOutLabel = record.clockOut ?? '--:--';

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                    vertical: AppDimensions.space12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: AppDimensions.cardBorderRadius,
                    border: Border.all(
                      color: AppColors.borderNeutral,
                      width: AppDimensions.borderWidth,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inkPrimary,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space4),
                            Row(
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
                                const Text(
                                  '  /  Pulang ',
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
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: AppDimensions.space4,
                        ),
                        decoration: BoxDecoration(
                          color: badge.backgroundColor,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: badge.borderColor,
                            width: AppDimensions.borderWidth,
                          ),
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
