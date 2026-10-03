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
import '../data/leave_models.dart';
import '../provider/leave_provider.dart';
import 'apply_leave_screen.dart';

class LeaveStatusBadge extends StatelessWidget {
  final LeaveStatus status;

  const LeaveStatusBadge({super.key, required this.status});

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

class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  String _formatDateRange(String start, String end) {
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      final format = DateFormat('d MMM yyyy', 'id_ID');
      if (start == end) {
        return format.format(s);
      }
      return '${format.format(s)} - ${format.format(e)}';
    } catch (_) {
      return '$start s/d $end';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isNonEmployee =
        auth.user != null && (auth.isAdministrator || !auth.hasEmployeeProfile);

    if (isNonEmployee) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Row(
            children: [
              HrHubLogo(size: 24),
              SizedBox(width: 10),
              Text(
                'Cuti & Izin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: AppEmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'Pengajuan Cuti Khusus Karyawan',
              description:
                  'Akun Anda (${auth.roleLabel}) terdaftar sebagai pengelola. Pengajuan cuti pada aplikasi mobile ini diperuntukkan bagi karyawan operasional. Untuk menyetujui atau meninjau pengajuan cuti staf, silakan buka Web Admin.',
              actionText: 'Keluar & Ganti Akun',
              onAction: () => ref.read(authStateProvider.notifier).logout(),
            ),
          ),
        ),
      );
    }

    final currentFilter = ref.watch(leaveStatusFilterProvider);
    final balancesAsync = ref.watch(leaveBalanceProvider);
    final requestsAsync = ref.watch(leaveMyRequestsProvider(currentFilter));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            HrHubLogo(size: 24),
            SizedBox(width: 10),
            Text(
              'Cuti & Izin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.inkMuted),
            onPressed: () {
              ref.invalidate(leaveBalanceProvider);
              ref.invalidate(leaveMyRequestsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ajukan Cuti / Izin',
        backgroundColor: AppColors.actionAccent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => const ApplyLeaveScreen(),
            ),
          );
          if (created == true) {
            ref.invalidate(leaveBalanceProvider);
            ref.invalidate(leaveMyRequestsProvider);
          }
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(leaveBalanceProvider);
          ref.invalidate(leaveMyRequestsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space16,
          ),
          children: [
            // Section 1 Header: Sisa Kuota Cuti
            _buildSectionHeader(
              title: 'Sisa Kuota Cuti',
              icon: Icons.pie_chart_outline_rounded,
            ),
            const SizedBox(height: AppDimensions.space8),

            // Kuota Card / Loading / Empty
            balancesAsync.when(
              loading: () => const AppSkeleton(height: 110),
              error: (error, _) => AppErrorState(
                isCard: true,
                title: 'Gagal Memuat Kuota Cuti',
                message: error is ApiException
                    ? error.userFriendlyMessage
                    : error.toString(),
                onRetry: () => ref.invalidate(leaveBalanceProvider),
              ),
              data: (balances) {
                if (balances.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    decoration: BoxDecoration(
                      color: AppColors.canvasLight,
                      borderRadius: AppDimensions.cardBorderRadius,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: AppDimensions.borderWidth,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informasi Kuota Cuti',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Data kuota belum diatur oleh HR. Anda tetap dapat mengajukan izin/cuti.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkMuted,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: balances.map((balance) {
                    final total = balance.total_quota;
                    final used = balance.used_days;
                    final remaining = balance.remaining_days;
                    final progress = total > 0
                        ? (used / total).clamp(0.0, 1.0)
                        : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppDimensions.space8),
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: AppColors.canvasLight,
                        borderRadius: AppDimensions.cardBorderRadius,
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: AppDimensions.borderWidth,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x04000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                balance.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.orangeTint,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.orangeBorder,
                                    width: 1.0,
                                  ),
                                ),
                                child: const Text(
                                  'Tahun Berjalan',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.actionAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$remaining Hari',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.inkPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Tersedia',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space12),

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.actionAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppDimensions.space8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Terpakai: $used hari',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                              Text(
                                'Total Kuota: $total hari',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: AppDimensions.space20),

            // Section 2 Header: Riwayat Pengajuan Cuti
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(
                  title: 'Riwayat Pengajuan Cuti',
                  icon: Icons.history_rounded,
                ),
                if (currentFilter != null)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      ref.read(leaveStatusFilterProvider.notifier).state = null;
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Reset Filter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.actionAccent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.space8),

            // Filter Pills Bar (Full-width scrollable with WCAG AA contrast & 44px min height)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip(
                    label: 'Semua',
                    isSelected: currentFilter == null,
                    onTap: () {
                      ref.read(leaveStatusFilterProvider.notifier).state = null;
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Menunggu',
                    isSelected: currentFilter == 'pending',
                    onTap: () {
                      ref.read(leaveStatusFilterProvider.notifier).state = 'pending';
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Disetujui',
                    isSelected: currentFilter == 'approved',
                    onTap: () {
                      ref.read(leaveStatusFilterProvider.notifier).state = 'approved';
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Ditolak',
                    isSelected: currentFilter == 'rejected',
                    onTap: () {
                      ref.read(leaveStatusFilterProvider.notifier).state = 'rejected';
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space12),

            // Requests List
            requestsAsync.when(
              loading: () => Column(
                children: List.generate(
                  3,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: AppDimensions.space8),
                    child: AppSkeleton(height: 96),
                  ),
                ),
              ),
              error: (error, _) => AppErrorState(
                isCard: true,
                title: 'Gagal Memuat Riwayat Cuti',
                message: error is ApiException
                    ? error.userFriendlyMessage
                    : error.toString(),
                onRetry: () =>
                    ref.invalidate(leaveMyRequestsProvider(currentFilter)),
              ),
              data: (requests) {
                if (requests.isEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.canvasLight,
                      borderRadius: AppDimensions.cardBorderRadius,
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: AppDimensions.borderWidth,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space20,
                      vertical: AppDimensions.space32,
                    ),
                    child: AppEmptyState(
                      icon: Icons.event_note_outlined,
                      title: 'Belum Ada Pengajuan',
                      description: currentFilter != null
                          ? 'Tidak ada pengajuan cuti dengan status ini.'
                          : 'Daftar permohonan cuti dan izin yang Anda ajukan akan tercatat rapi di sini.',
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppDimensions.space8),
                  itemBuilder: (context, index) {
                    final item = requests[index];
                    final dateRangeText = _formatDateRange(
                      item.start_date,
                      item.end_date,
                    );

                    return Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: AppColors.canvasLight,
                        borderRadius: AppDimensions.cardBorderRadius,
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: AppDimensions.borderWidth,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x03000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Leave Type & Status Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.event_available_outlined,
                                        size: 16,
                                        color: AppColors.inkPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.leave_type_name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.inkPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              LeaveStatusBadge(status: item.status),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space12),

                          // Date & Duration pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: AppColors.inkMuted,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    dateRangeText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.inkPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${item.total_days} hari',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.inkPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Reason
                          if (item.reason.isNotEmpty) ...[
                            const SizedBox(height: AppDimensions.space8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.notes_rounded,
                                    size: 14,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.reason,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkMuted,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // Rejection Note Alert
                          if (item.status == LeaveStatus.rejected &&
                              item.rejection_note != null &&
                              item.rejection_note!.isNotEmpty) ...[
                            const SizedBox(height: AppDimensions.space8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppDimensions.space12),
                              decoration: BoxDecoration(
                                color: AppColors.dangerBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.dangerBorder,
                                  width: 1.0,
                                ),
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Catatan Penolakan:',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.dangerText,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.rejection_note!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.dangerText,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Attachment Indicator
                          if (item.attachment_url != null &&
                              item.attachment_url!.isNotEmpty) ...[
                            const SizedBox(height: AppDimensions.space8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.attach_file_rounded,
                                  size: 14,
                                  color: AppColors.actionAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Berkas Bukti Dilampirkan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.actionAccent.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.inkMuted),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.inkPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Material(
        color: isSelected ? AppColors.actionAccent : AppColors.canvasLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: isSelected ? AppColors.actionAccent : const Color(0xFFCBD5E1),
            width: 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.inkPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
