import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_phosphor_icons.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/hr_hub_logo.dart';
import '../../auth/provider/auth_provider.dart';
import '../data/leave_models.dart';
import '../provider/leave_provider.dart';
import 'apply_leave_screen.dart';
import 'leave_action_dialogs.dart';
import 'leave_detail_screen.dart';

export 'leave_action_dialogs.dart' show LeaveStatusBadge;

class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  Future<void> _openApplyLeave(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const ApplyLeaveScreen(),
      ),
    );
    if (created == true) {
      ref.invalidate(leaveBalanceProvider);
      ref.invalidate(leaveMyRequestsProvider);
      ref.invalidate(leaveApprovalsProvider);
    }
  }

  void _openDetail(
    BuildContext context,
    WidgetRef ref,
    LeaveRequestModel item, {
    required bool isApprovalView,
  }) {
    Navigator.of(context)
        .push<LeaveDetailResult>(
      MaterialPageRoute(
        builder: (_) => LeaveDetailScreen(
          item: item,
          isApprovalView: isApprovalView,
        ),
      ),
    )
        .then((result) {
      if (!context.mounted || result == null) return;
      ref.invalidate(leaveApprovalsProvider);
      ref.invalidate(leaveMyRequestsProvider);
      ref.invalidate(leaveBalanceProvider);
      final msg = result.message;
      if (msg == null || msg.isEmpty) return;
      final bg = result.outcome == 'rejected'
          ? const Color(0xFFB91C1C)
          : const Color(0xFF047857);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: bg,
          ),
        );
    });
  }

  bool _matchesLeaveDate(LeaveRequestModel item, String dateFilter) {
    final start = item.start_date.length >= 10
        ? item.start_date.substring(0, 10)
        : item.start_date;
    final end = item.end_date.length >= 10
        ? item.end_date.substring(0, 10)
        : item.end_date;
    if (start.isEmpty) return false;
    final effectiveEnd = end.isNotEmpty ? end : start;
    return start.compareTo(dateFilter) <= 0 &&
        effectiveEnd.compareTo(dateFilter) >= 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final canApprove = auth.canApproveRequests;
    final hasEmployeeProfile = auth.user == null || auth.hasEmployeeProfile;

    if (auth.user != null && !canApprove && !hasEmployeeProfile) {
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
              Flexible(
                child: Text(
                  'Pengajuan Cuti',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: AppEmptyState(
              icon: PhosphorIconsRegular.calendarCheck,
              title: 'Profil Karyawan Belum Terhubung',
              description:
                  'Akun Anda (${auth.roleLabel}) belum terhubung dengan data karyawan.',
              actionText: 'Keluar & Ganti Akun',
              onAction: () => ref.read(authStateProvider.notifier).logout(),
            ),
          ),
        ),
      );
    }

    final rawTab = ref.watch(leaveViewTabProvider);
    final activeTab = canApprove ? (rawTab ?? 'approvals') : 'my-requests';
    final isApprovalView = canApprove && activeTab == 'approvals';

    if (isApprovalView) {
      final approvalFilter = ref.watch(leaveApprovalFilterProvider);
      final approvalDateFilter = ref.watch(leaveApprovalDateFilterProvider);
      final approvalsAsync = ref.watch(leaveApprovalsProvider(approvalFilter));
      final allApprovalsAsync = ref.watch(leaveApprovalsProvider(null));

      int countAll = 0;
      int countPending = 0;
      int countApproved = 0;
      int countRejected = 0;
      int countCancelled = 0;
      allApprovalsAsync.whenData((list) {
        countAll = list.length;
        countPending = list.where((r) => r.status == LeaveStatus.pending).length;
        countApproved =
            list.where((r) => r.status == LeaveStatus.approved).length;
        countRejected =
            list.where((r) => r.status == LeaveStatus.rejected).length;
        countCancelled =
            list.where((r) => r.status == LeaveStatus.cancelled).length;
      });

      final showModeSwitcher = canApprove && hasEmployeeProfile;

      return Scaffold(
        backgroundColor: AppColors.surfaceCanvas,
        appBar: _buildAppBar(auth: auth),
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
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(leaveApprovalsProvider);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 96),
                    children: [
                      if (showModeSwitcher) ...[
                        _buildModeSwitcher(
                          activeTab: activeTab,
                          pendingApprovalCount: countPending,
                          ref: ref,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'Daftar Permohonan Staf',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusFilterPopupButton(
                            currentFilter: approvalFilter,
                            currentDate: approvalDateFilter,
                            options: [
                              _FilterOption(
                                value: 'all',
                                label: 'Semua',
                                count: countAll > 0 ? countAll : null,
                              ),
                              _FilterOption(
                                value: 'pending',
                                label: 'Menunggu',
                                count: countPending > 0 ? countPending : null,
                                dotColor: AppColors.statusWarning,
                              ),
                              _FilterOption(
                                value: 'approved',
                                label: 'Disetujui',
                                count: countApproved > 0 ? countApproved : null,
                                dotColor: AppColors.statusSuccess,
                              ),
                              _FilterOption(
                                value: 'rejected',
                                label: 'Ditolak',
                                count: countRejected > 0 ? countRejected : null,
                                dotColor: AppColors.statusDanger,
                              ),
                              _FilterOption(
                                value: 'cancelled',
                                label: 'Dibatalkan',
                                count:
                                    countCancelled > 0 ? countCancelled : null,
                                dotColor: AppColors.textMuted,
                              ),
                            ],
                            onApply: (status, date) {
                              ref
                                  .read(leaveApprovalFilterProvider.notifier)
                                  .state = (status == null || status == 'all')
                                      ? null
                                      : status;
                              ref
                                  .read(
                                      leaveApprovalDateFilterProvider.notifier)
                                  .state = date;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      approvalsAsync.when(
                        loading: () => const Column(
                          children: [
                            AppSkeleton(height: 180),
                            SizedBox(height: 12),
                            AppSkeleton(height: 180),
                            SizedBox(height: 12),
                            AppSkeleton(height: 180),
                          ],
                        ),
                        error: (error, _) => AppErrorState(
                          isCard: true,
                          title: 'Gagal Memuat Daftar Persetujuan Cuti',
                          message: error is ApiException
                              ? error.userFriendlyMessage
                              : error.toString().replaceFirst('Exception: ', ''),
                          retryText: 'Coba Lagi',
                          onRetry: () => ref
                              .invalidate(leaveApprovalsProvider(approvalFilter)),
                        ),
                        data: (rawRequests) {
                          final requests = approvalDateFilter == null
                              ? rawRequests
                              : rawRequests
                                  .where((r) =>
                                      _matchesLeaveDate(r, approvalDateFilter))
                                  .toList();

                          if (requests.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 32,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.borderSubtle,
                                ),
                              ),
                              child: AppEmptyState(
                                icon: PhosphorIconsRegular.clipboardText,
                                title: 'Belum Ada Pengajuan Cuti Staf',
                                description: (approvalFilter == null &&
                                        approvalDateFilter == null)
                                    ? 'Seluruh permohonan cuti dan izin yang diajukan karyawan akan muncul di sini untuk Anda tinjau.'
                                    : 'Tidak ada permohonan cuti karyawan dengan filter ini.',
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: requests.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = requests[index];
                              return _LeaveListCard(
                                item: item,
                                fallbackEmployeeName: 'Karyawan',
                                onTap: () => _openDetail(
                                  context,
                                  ref,
                                  item,
                                  isApprovalView: true,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    final currentFilter = ref.watch(leaveStatusFilterProvider);
    final currentDateFilter = ref.watch(leaveDateFilterProvider);
    final requestsAsync = ref.watch(leaveMyRequestsProvider(currentFilter));
    final allRequestsAsync = ref.watch(leaveMyRequestsProvider(null));
    final pendingApprovalsCount = canApprove
        ? (ref
                .watch(leaveApprovalsProvider(null))
                .valueOrNull
                ?.where((r) => r.status == LeaveStatus.pending)
                .length ??
            0)
        : 0;
    final showModeSwitcher = canApprove && hasEmployeeProfile;
    final fallbackOwnName =
        auth.userName.trim().isNotEmpty ? auth.userName.trim() : 'Karyawan';

    int countAll = 0;
    int countPending = 0;
    int countApproved = 0;
    int countRejected = 0;
    int countCancelled = 0;
    allRequestsAsync.whenData((list) {
      countAll = list.length;
      countPending = list.where((r) => r.status == LeaveStatus.pending).length;
      countApproved = list.where((r) => r.status == LeaveStatus.approved).length;
      countRejected = list.where((r) => r.status == LeaveStatus.rejected).length;
      countCancelled =
          list.where((r) => r.status == LeaveStatus.cancelled).length;
    });

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      appBar: _buildAppBar(auth: auth),
      floatingActionButton: FloatingActionButton(
        heroTag: 'leave_add_fab',
        onPressed: () => _openApplyLeave(context, ref),
        backgroundColor: AppColors.actionAccent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        tooltip: 'Ajukan Cuti / Izin',
        child: const Icon(LucideIcons.plus, size: 24),
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
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(leaveBalanceProvider);
                  ref.invalidate(leaveMyRequestsProvider);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 96),
                  children: [
                    if (showModeSwitcher) ...[
                      _buildModeSwitcher(
                        activeTab: activeTab,
                        pendingApprovalCount: pendingApprovalsCount,
                        ref: ref,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Riwayat Pengajuan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusFilterPopupButton(
                          currentFilter: currentFilter,
                          currentDate: currentDateFilter,
                          options: [
                            _FilterOption(
                              value: 'all',
                              label: 'Semua',
                              count: countAll > 0 ? countAll : null,
                            ),
                            _FilterOption(
                              value: 'pending',
                              label: 'Menunggu',
                              count: countPending > 0 ? countPending : null,
                              dotColor: AppColors.statusWarning,
                            ),
                            _FilterOption(
                              value: 'approved',
                              label: 'Disetujui',
                              count: countApproved > 0 ? countApproved : null,
                              dotColor: AppColors.statusSuccess,
                            ),
                            _FilterOption(
                              value: 'rejected',
                              label: 'Ditolak',
                              count: countRejected > 0 ? countRejected : null,
                              dotColor: AppColors.statusDanger,
                            ),
                            _FilterOption(
                              value: 'cancelled',
                              label: 'Dibatalkan',
                              count:
                                  countCancelled > 0 ? countCancelled : null,
                              dotColor: AppColors.textMuted,
                            ),
                          ],
                          onApply: (status, date) {
                            ref.read(leaveStatusFilterProvider.notifier).state =
                                (status == null || status == 'all')
                                    ? null
                                    : status;
                            ref.read(leaveDateFilterProvider.notifier).state =
                                date;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    requestsAsync.when(
                      loading: () => const Column(
                        children: [
                          AppSkeleton(height: 180),
                          SizedBox(height: 12),
                          AppSkeleton(height: 180),
                          SizedBox(height: 12),
                          AppSkeleton(height: 180),
                        ],
                      ),
                      error: (error, _) => AppErrorState(
                        isCard: true,
                        title: 'Gagal Memuat Riwayat Cuti',
                        message: error is ApiException
                            ? error.userFriendlyMessage
                            : error.toString().replaceFirst('Exception: ', ''),
                        retryText: 'Coba Lagi',
                        onRetry: () => ref.invalidate(
                            leaveMyRequestsProvider(currentFilter)),
                      ),
                      data: (rawRequests) {
                        final requests = currentDateFilter == null
                            ? rawRequests
                            : rawRequests
                                .where((r) =>
                                    _matchesLeaveDate(r, currentDateFilter))
                                .toList();

                        if (requests.isEmpty) {
                          final isUnfiltered = currentFilter == null &&
                              currentDateFilter == null;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 32,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: AppEmptyState(
                              icon: PhosphorIconsRegular.calendarBlank,
                              title: 'Belum Ada Pengajuan',
                              description: isUnfiltered
                                  ? 'Anda belum pernah mengajukan cuti atau izin. Tekan tombol + untuk membuat pengajuan baru.'
                                  : 'Tidak ada pengajuan cuti dengan filter ini.',
                              actionText: isUnfiltered ? 'Ajukan Cuti' : null,
                              onAction: isUnfiltered
                                  ? () => _openApplyLeave(context, ref)
                                  : null,
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: requests.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = requests[index];
                            return _LeaveListCard(
                              item: item,
                              fallbackEmployeeName: fallbackOwnName,
                              onTap: () => _openDetail(
                                context,
                                ref,
                                item,
                                isApprovalView: false,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar({required AuthState auth}) {
    return AppBar(
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
          Flexible(
            child: Text(
              'Pengajuan Cuti',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
                letterSpacing: -0.3,
              ),
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
            auth.user?['name'] != null &&
                    (auth.user!['name'] as String).isNotEmpty
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
    );
  }

  Widget _buildModeSwitcher({
    required String activeTab,
    required int pendingApprovalCount,
    required WidgetRef ref,
  }) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LeaveModeTabButton(
              label: 'Persetujuan Staf',
              badgeCount:
                  pendingApprovalCount > 0 ? pendingApprovalCount : null,
              isSelected: activeTab == 'approvals',
              onTap: () {
                ref.read(leaveViewTabProvider.notifier).state = 'approvals';
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _LeaveModeTabButton(
              label: 'Pengajuan Saya',
              badgeCount: null,
              isSelected: activeTab == 'my-requests',
              onTap: () {
                ref.read(leaveViewTabProvider.notifier).state = 'my-requests';
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveListCard extends StatelessWidget {
  final LeaveRequestModel item;
  final String fallbackEmployeeName;
  final VoidCallback onTap;

  const _LeaveListCard({
    required this.item,
    required this.fallbackEmployeeName,
    required this.onTap,
  });

  String _formatDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    final isoOnly = trimmed.length >= 10 ? trimmed.substring(0, 10) : trimmed;
    final parsed = DateTime.tryParse(isoOnly) ?? DateTime.tryParse(trimmed);
    if (parsed == null) return trimmed;
    return DateFormat('d MMM yyyy', 'id_ID').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    final rawEmpName = item.employee_name?.trim();
    final displayName = (rawEmpName != null && rawEmpName.isNotEmpty)
        ? rawEmpName
        : fallbackEmployeeName;
    final startDateText = _formatDate(item.start_date);
    final rawEndDate =
        item.end_date.trim().isNotEmpty ? item.end_date : item.start_date;
    final endDateText = _formatDate(rawEndDate);

    return Container(
      key: Key('leave_card_${item.id_leave_requests}'),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Semantics(
        button: true,
        label:
            'Buka rincian pengajuan ${item.displayRequestNumber}, status ${item.status.label}',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.displayRequestNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkPrimary,
                            letterSpacing: -0.2,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 17,
                        color: Color(0xFF475569),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ListCardField(
                        label: 'Permintaan Untuk',
                        value: displayName,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, dateConstraints) {
                          final effWidth =
                              dateConstraints.maxWidth / textScale;
                          final stackPairs = effWidth < 230;
                          if (stackPairs) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ListCardField(
                                  label: 'Tanggal Mulai',
                                  value: startDateText,
                                  tabular: true,
                                ),
                                const SizedBox(height: 10),
                                _ListCardField(
                                  label: 'Tanggal Berakhir',
                                  value: endDateText,
                                  tabular: true,
                                ),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _ListCardField(
                                  label: 'Tanggal Mulai',
                                  value: startDateText,
                                  tabular: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ListCardField(
                                  label: 'Tanggal Berakhir',
                                  value: endDateText,
                                  tabular: true,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, metaConstraints) {
                          final effWidth =
                              metaConstraints.maxWidth / textScale;
                          final stackPairs = effWidth < 230;
                          if (stackPairs) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _ListCardField(
                                  label: 'Jenis Cuti',
                                  value: item.leave_type_name,
                                  maxLines: 1,
                                ),
                                const SizedBox(height: 10),
                                _ListCardField(
                                  label: 'Durasi',
                                  value: '${item.total_days} hari',
                                  tabular: true,
                                ),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _ListCardField(
                                  label: 'Jenis Cuti',
                                  value: item.leave_type_name,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ListCardField(
                                  label: 'Durasi',
                                  value: '${item.total_days} hari',
                                  tabular: true,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ListCardField(
                        label: 'Keterangan',
                        value: item.reason.isNotEmpty ? item.reason : '-',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      LeaveStatusBadge(status: item.status),
                    ],
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

class _ListCardField extends StatelessWidget {
  final String label;
  final String value;
  final int? maxLines;
  final bool tabular;

  const _ListCardField({
    required this.label,
    required this.value,
    this.maxLines,
    this.tabular = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.inkPrimary,
            height: 1.35,
            fontFeatures:
                tabular ? const [FontFeature.tabularFigures()] : null,
          ),
        ),
      ],
    );
  }
}

class _FilterOption {
  final String value;
  final String label;
  final int? count;
  final Color? dotColor;

  const _FilterOption({
    required this.value,
    required this.label,
    this.count,
    this.dotColor,
  });
}

class _StatusFilterPopupButton extends StatelessWidget {
  final String? currentFilter;
  final String? currentDate;
  final List<_FilterOption> options;
  final void Function(String? status, String? date) onApply;

  const _StatusFilterPopupButton({
    required this.currentFilter,
    required this.currentDate,
    required this.options,
    required this.onApply,
  });

  Future<void> _openFilterDialog(BuildContext context) async {
    final result = await showDialog<({String? status, String? date})>(
      context: context,
      builder: (_) => _LeaveFilterDialog(
        initialStatus: currentFilter,
        initialDate: currentDate,
        options: options,
      ),
    );
    if (result != null) {
      onApply(result.status, result.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedCurrent =
        (currentFilter == null || currentFilter == 'all') ? 'all' : currentFilter!;
    final isFiltered = normalizedCurrent != 'all' ||
        (currentDate != null && currentDate!.isNotEmpty);

    return Semantics(
      button: true,
      label: 'Filter',
      child: Tooltip(
        message: 'Filter Tanggal & Status',
        child: InkWell(
          onTap: () => _openFilterDialog(context),
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppDimensions.minTouchTarget,
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isFiltered
                          ? AppColors.corporateChipBg
                          : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isFiltered
                            ? AppColors.primaryContainer
                            : AppColors.borderSubtle,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.filter,
                      size: 17,
                      color: isFiltered
                          ? AppColors.primaryContainer
                          : AppColors.textBody,
                    ),
                  ),
                  if (isFiltered)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaveFilterDialog extends StatefulWidget {
  final String? initialStatus;
  final String? initialDate;
  final List<_FilterOption> options;

  const _LeaveFilterDialog({
    required this.initialStatus,
    required this.initialDate,
    required this.options,
  });

  @override
  State<_LeaveFilterDialog> createState() => _LeaveFilterDialogState();
}

class _LeaveFilterDialogState extends State<_LeaveFilterDialog> {
  late String _selectedStatus;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedStatus =
        (widget.initialStatus == null || widget.initialStatus == 'all')
            ? 'all'
            : widget.initialStatus!;
    _selectedDate = widget.initialDate;
  }

  String _formatDateLabel(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Semua Tanggal';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    DateTime initial = now;
    if (_selectedDate != null && _selectedDate!.isNotEmpty) {
      try {
        initial = DateTime.parse(_selectedDate!);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      helpText: 'Pilih Tanggal Cuti / Izin',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Filter Pengajuan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tutup',
            constraints: const BoxConstraints(
              minWidth: AppDimensions.minTouchTarget,
              minHeight: AppDimensions.minTouchTarget,
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              LucideIcons.x,
              size: 18,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tanggal',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppDimensions.minTouchTarget,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCanvas,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedDate != null
                          ? AppColors.primaryContainer
                          : AppColors.borderSubtle,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: _selectedDate != null
                            ? AppColors.primaryContainer
                            : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formatDateLabel(_selectedDate),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _selectedDate != null
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: _selectedDate != null
                                ? AppColors.inkPrimary
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      if (_selectedDate != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = null;
                            });
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(
                              LucideIcons.x,
                              size: 16,
                              color: Color(0xFF475569),
                            ),
                          ),
                        )
                      else
                        const Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.options.map((opt) {
                final isSelected = opt.value == _selectedStatus;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedStatus = opt.value;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 40),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryContainer
                            : AppColors.surfaceCanvas,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryContainer
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (opt.dotColor != null && !isSelected) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: opt.dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            opt.count != null
                                ? '${opt.label} (${opt.count})'
                                : opt.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: () {
            Navigator.of(context).pop((status: 'all', date: null));
          },
          child: const Text(
            'Reset',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size(96, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            Navigator.of(context).pop(
              (status: _selectedStatus, date: _selectedDate),
            );
          },
          child: const Text(
            'Terapkan',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _LeaveModeTabButton extends StatelessWidget {
  final String label;
  final int? badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _LeaveModeTabButton({
    required this.label,
    required this.badgeCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryContainer : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryContainer
                      : const Color(0xFF475569),
                ),
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
