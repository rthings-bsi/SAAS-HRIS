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
    Color dotColor;
    switch (status) {
      case LeaveStatus.approved:
        dotColor = AppColors.statusSuccess;
        break;
      case LeaveStatus.rejected:
        dotColor = AppColors.statusDanger;
        break;
      case LeaveStatus.pending:
      default:
        dotColor = AppColors.statusWarning;
        break;
    }

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.textColor,
            ),
          ),
        ],
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
        backgroundColor: AppColors.surfaceCanvas,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceCard,
          elevation: 0,
          title: const Row(
            children: [
              HrHubLogo(size: 24),
              SizedBox(width: 10),
              Text(
                'Cuti & Izin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
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

    final balanceAsync = ref.watch(leaveBalanceProvider);
    final currentFilter = ref.watch(leaveStatusFilterProvider);
    final requestsAsync = ref.watch(leaveMyRequestsProvider(currentFilter));
    final allRequestsAsync = ref.watch(leaveMyRequestsProvider(null));

    // Request counts for filter badges
    int countAll = 0;
    int countPending = 0;
    int countApproved = 0;
    int countRejected = 0;
    allRequestsAsync.whenData((list) {
      countAll = list.length;
      countPending = list.where((r) => r.status == LeaveStatus.pending).length;
      countApproved = list.where((r) => r.status == LeaveStatus.approved).length;
      countRejected = list.where((r) => r.status == LeaveStatus.rejected).length;
    });

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.borderSubtle,
            height: 1.0,
          ),
        ),
        title: const Row(
          children: [
            HrHubLogo(size: 24),
            SizedBox(width: 10),
            Text(
              'Cuti & Izin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppDimensions.space16),
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              auth.user?['name'] != null && (auth.user!['name'] as String).isNotEmpty
                  ? (auth.user!['name'] as String)
                      .trim()
                      .split(' ')
                      .map((e) => e.isNotEmpty ? e[0] : '')
                      .take(2)
                      .join()
                      .toUpperCase()
                  : 'HR',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ajukan Cuti / Izin',
        backgroundColor: AppColors.primaryContainer,
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
        color: AppColors.primary,
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
            // Section 1: Annual Leave Quota Progress Card (Design: manajemen_cuti_izin_karyawan)
            balanceAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(bottom: AppDimensions.space16),
                child: AppSkeleton(height: 140),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.space16),
                child: AppErrorState(
                  isCard: true,
                  title: 'Gagal Memuat Saldo Cuti',
                  message: error is ApiException
                      ? error.userFriendlyMessage
                      : error.toString(),
                  onRetry: () => ref.invalidate(leaveBalanceProvider),
                ),
              ),
              data: (balances) {
                if (balances.isEmpty) return const SizedBox.shrink();
                final annual = balances.firstWhere(
                  (b) => b.name.toLowerCase().contains('tahunan'),
                  orElse: () => balances.first,
                );

                final remaining = annual.remaining_days;
                final total = annual.total_quota;
                final used = annual.used_days;
                final double progress = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.space16),
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Pill Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 5,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                annual.name.isNotEmpty ? annual.name : 'Saldo Cuti Tahunan',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'KUOTA TAHUNAN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Metric Counter Visual
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$remaining',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -1.0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Hari',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tersisa dari $total hari/tahun',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space12),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 10,
                          width: double.infinity,
                          color: AppColors.surfaceMuted,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space8),

                      // Legend indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Tersisa: $remaining Hari',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.borderStrong,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Terpakai: $used Hari',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // Section 2: Header Riwayat Pengajuan & Filter Segmented Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(
                  title: 'Riwayat Pengajuan',
                  icon: Icons.history_rounded,
                ),
                Text(
                  'Periode ${DateTime.now().year}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space12),

            // Filter Tabs with Badge Counters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterTab(
                    label: 'Semua',
                    count: countAll > 0 ? countAll : null,
                    dotColor: null,
                    isSelected: currentFilter == null,
                    onTap: () {
                      ref.read(leaveStatusFilterProvider.notifier).state = null;
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    label: 'Menunggu',
                    count: countPending > 0 ? countPending : null,
                    dotColor: AppColors.statusWarning,
                    isSelected: currentFilter == 'pending',
                    onTap: () {
                      ref.read(leaveStatusFilterProvider.notifier).state = 'pending';
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    label: 'Disetujui',
                    count: countApproved > 0 ? countApproved : null,
                    dotColor: AppColors.statusSuccess,
                    isSelected: currentFilter == 'approved',
                    onTap: () {
                      ref.read(leaveStatusFilterProvider.notifier).state = 'approved';
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildFilterTab(
                    label: 'Ditolak',
                    count: countRejected > 0 ? countRejected : null,
                    dotColor: AppColors.statusDanger,
                    isSelected: currentFilter == 'rejected',
                    onTap: () {
                      ref.read(leaveStatusFilterProvider.notifier).state = 'rejected';
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Section 4: Requests List
            requestsAsync.when(
              loading: () => Column(
                children: List.generate(
                  3,
                  (_) => const Padding(
                    padding: EdgeInsets.only(bottom: AppDimensions.space12),
                    child: AppSkeleton(height: 110),
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
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.borderSubtle,
                        width: 1.0,
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
                      const SizedBox(height: AppDimensions.space12),
                  itemBuilder: (context, index) {
                    final item = requests[index];
                    final dateRangeText = _formatDateRange(
                      item.start_date,
                      item.end_date,
                    );

                    IconData itemIcon;
                    Color iconBg;
                    Color iconColor;
                    if (item.status == LeaveStatus.approved) {
                      itemIcon = Icons.flight_takeoff_rounded;
                      iconBg = AppColors.statusSuccessBg;
                      iconColor = AppColors.statusSuccess;
                    } else if (item.status == LeaveStatus.rejected) {
                      itemIcon = Icons.cancel_outlined;
                      iconBg = AppColors.statusDangerBg;
                      iconColor = AppColors.statusDanger;
                    } else {
                      itemIcon = Icons.medication_rounded;
                      iconBg = AppColors.statusWarningBg;
                      iconColor = AppColors.statusWarning;
                    }

                    return Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.borderSubtle,
                          width: 1.0,
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
                          // Top Row: Squircle icon + Title & reason + Status badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  itemIcon,
                                  size: 20,
                                  color: iconColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.leave_type_name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.reason.isNotEmpty
                                          ? item.reason
                                          : 'Pengajuan cuti',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              LeaveStatusBadge(status: item.status),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.space12),

                          // Schedule & Duration Box (Design: manajemen_cuti_izin_karyawan)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.date_range_rounded,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      dateRangeText,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textBody,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceCard,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.borderSubtle,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    '${item.total_days} Hari',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Rejection Note Alert (if rejected)
                          if (item.status == LeaveStatus.rejected &&
                              item.rejection_note != null &&
                              item.rejection_note!.isNotEmpty) ...[
                            const SizedBox(height: AppDimensions.space12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppDimensions.space12),
                              decoration: BoxDecoration(
                                color: AppColors.statusDangerBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.statusDangerBorder,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: AppColors.statusDanger,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Catatan Penolakan:',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.statusDanger,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.rejection_note!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.statusDanger,
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

                          // Bottom Row: Attachment indicator & Reviewer note
                          const SizedBox(height: AppDimensions.space8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (item.attachment_url != null &&
                                  item.attachment_url!.isNotEmpty)
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.attach_file_rounded,
                                      size: 14,
                                      color: AppColors.statusInfo,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Berkas Bukti Dilampirkan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.statusInfo,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const SizedBox.shrink(),
                              const Text(
                                'Reviewer: HR / Supervisor',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
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
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab({
    required String label,
    int? count,
    Color? dotColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
      child: Material(
        color: isSelected ? AppColors.primaryContainer : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: isSelected ? AppColors.primaryContainer : AppColors.borderSubtle,
            width: 1.0,
          ),
        ),
        elevation: isSelected ? 1 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null && !isSelected) ...[
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textBody,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
