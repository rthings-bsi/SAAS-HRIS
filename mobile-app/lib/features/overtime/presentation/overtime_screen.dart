import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/hr_hub_logo.dart';
import '../../auth/provider/auth_provider.dart';
import '../data/overtime_models.dart';
import '../provider/overtime_provider.dart';
import 'apply_overtime_sheet.dart';

class OvertimeStatusBadge extends StatelessWidget {
  final OvertimeStatus status;

  const OvertimeStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: status.borderColor,
          width: 1.0,
        ),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: status.textColor,
        ),
      ),
    );
  }
}

class OvertimeScreen extends ConsumerWidget {
  const OvertimeScreen({super.key});

  void _openApplyOvertime(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ApplyOvertimeSheet(),
    ).then((submitted) {
      if (submitted == true && context.mounted) {
        ref.invalidate(myOvertimeListProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan lembur berhasil dikirim ke atasan.'),
            backgroundColor: AppColors.successText,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isNonEmployee =
        auth.user != null && (auth.isAdministrator || !auth.hasEmployeeProfile);

    if (isNonEmployee) {
      return Scaffold(
        backgroundColor: AppColors.surfaceMuted,
        appBar: AppBar(
          title: const Row(
            children: [
              HrHubLogo(size: 24),
              SizedBox(width: 10),
              Text(
                'Pengajuan Lembur',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: AppEmptyState(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Lembur Khusus Karyawan',
              description:
                  'Akun Anda terdaftar sebagai akun pengelola. Fitur pengajuan lembur pada aplikasi mobile diperuntukkan bagi karyawan operasional. Silakan akses Web Admin untuk memverifikasi persetujuan lembur staf.',
              actionText: 'Kembali',
              onAction: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final activeFilter = ref.watch(overtimeStatusFilterProvider);
    final overtimeAsync = ref.watch(myOvertimeListProvider(activeFilter));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            HrHubLogo(size: 24),
            SizedBox(width: 10),
            Text(
              'Pengajuan Lembur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipItem(
                    label: 'Semua',
                    isSelected: activeFilter == null || activeFilter == 'all',
                    onTap: () => ref
                        .read(overtimeStatusFilterProvider.notifier)
                        .state = null,
                  ),
                  const SizedBox(width: 8),
                  _FilterChipItem(
                    label: 'Menunggu',
                    isSelected: activeFilter == 'pending',
                    onTap: () => ref
                        .read(overtimeStatusFilterProvider.notifier)
                        .state = 'pending',
                  ),
                  const SizedBox(width: 8),
                  _FilterChipItem(
                    label: 'Disetujui',
                    isSelected: activeFilter == 'approved',
                    onTap: () => ref
                        .read(overtimeStatusFilterProvider.notifier)
                        .state = 'approved',
                  ),
                  const SizedBox(width: 8),
                  _FilterChipItem(
                    label: 'Ditolak',
                    isSelected: activeFilter == 'rejected',
                    onTap: () => ref
                        .read(overtimeStatusFilterProvider.notifier)
                        .state = 'rejected',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.actionAccent,
        onRefresh: () async {
          ref.invalidate(myOvertimeListProvider);
        },
        child: overtimeAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              AppSkeleton(height: 110),
              SizedBox(height: 12),
              AppSkeleton(height: 110),
              SizedBox(height: 12),
              AppSkeleton(height: 110),
            ],
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AppErrorState(
                title: 'Gagal Memuat Riwayat Lembur',
                message: err is ApiException
                    ? err.userFriendlyMessage
                    : err.toString().replaceFirst('Exception: ', ''),
                retryText: 'Coba Lagi',
                onRetry: () => ref.invalidate(myOvertimeListProvider),
              ),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppEmptyState(
                    icon: Icons.more_time_rounded,
                    title: 'Belum Ada Pengajuan Lembur',
                    description: activeFilter == null
                        ? 'Anda belum pernah mengajukan jam lembur kerja. Tekan tombol + untuk membuat pengajuan baru.'
                        : 'Tidak ada data pengajuan lembur dengan status ini.',
                    actionText: 'Ajukan Lembur',
                    onAction: () => _openApplyOvertime(context, ref),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final item = items[idx];
                return _OvertimeCard(item: item);
              },
            );
          },
        ),
      ),
      // Floating Action Button (FAB) + Mobile
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openApplyOvertime(context, ref),
        backgroundColor: AppColors.actionAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        tooltip: 'Ajukan Lembur Baru',
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orangeTint : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.orangeBorder : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.actionAccent : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _OvertimeCard extends StatelessWidget {
  final OvertimeRequestModel item;

  const _OvertimeCard({required this.item});

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Tanggal & Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _formatDate(item.date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OvertimeStatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 10),

          // Time Range & Duration
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.start_time} - ${item.end_time}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orangeTint,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.orangeBorder, width: 0.8),
                ),
                child: Text(
                  item.formattedDuration,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.actionAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Reason text
          Text(
            item.reason,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),

          // Rejection note if any
          if (item.status == OvertimeStatus.rejected &&
              item.rejected_reason != null &&
              item.rejected_reason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.dangerBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.dangerText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alasan penolakan: ${item.rejected_reason!}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.dangerText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Approver info
          if (item.status == OvertimeStatus.approved &&
              item.approver_name != null) ...[
            const SizedBox(height: 8),
            Text(
              'Disetujui oleh: ${item.approver_name}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.successText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
