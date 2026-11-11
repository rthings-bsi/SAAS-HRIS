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
import '../data/overtime_models.dart';
import '../provider/overtime_provider.dart';
import 'apply_overtime_form_screen.dart';
import 'overtime_action_dialogs.dart';
import 'overtime_detail_screen.dart';

export 'overtime_action_dialogs.dart' show OvertimeStatusBadge;

class OvertimeScreen extends ConsumerWidget {
  const OvertimeScreen({super.key});

  void _openApplyOvertime(
    BuildContext context,
    WidgetRef ref, {
    OvertimeDraftModel? draft,
  }) {
    Navigator.of(context)
        .push<Object?>(
      MaterialPageRoute(
        builder: (_) => ApplyOvertimeFormScreen(initialDraft: draft),
      ),
    )
        .then((result) {
      if (!context.mounted) return;
      if (result == true) {
        ref.invalidate(myOvertimeListProvider);
        ref.invalidate(overtimeApprovalsProvider);
        ref.invalidate(localOvertimeDraftsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan lembur berhasil dikirim ke atasan.'),
            backgroundColor: AppColors.successText,
          ),
        );
      } else if (result == 'draft_saved') {
        ref.invalidate(localOvertimeDraftsProvider);
      }
    });
  }

  Future<void> _deleteLocalDraft(
    BuildContext context,
    WidgetRef ref,
    OvertimeDraftModel draft,
  ) async {
    final auth = ref.read(authStateProvider);
    final rawId = auth.user?['id_users'] ?? auth.user?['id'] ?? 0;
    final userId = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
    if (userId <= 0) return;

    await ref.read(overtimeDraftServiceProvider).deleteDraft(userId, draft.id);
    ref.invalidate(localOvertimeDraftsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draf lembur dihapus.'),
          backgroundColor: AppColors.inkPrimary,
        ),
      );
    }
  }

  void _openDetail(
    BuildContext context,
    WidgetRef ref,
    OvertimeRequestModel item, {
    required bool isApprovalView,
  }) {
    Navigator.of(context)
        .push<OvertimeDetailResult>(
      MaterialPageRoute(
        builder: (_) => OvertimeDetailScreen(
          item: item,
          isApprovalView: isApprovalView,
        ),
      ),
    )
        .then((result) {
      if (!context.mounted || result == null) return;
      ref.invalidate(myOvertimeListProvider);
      ref.invalidate(overtimeApprovalsProvider);
      final msg = result.message;
      if (msg == null || msg.isEmpty) return;
      final bg = result.outcome == 'rejected'
          ? AppColors.dangerText
          : AppColors.successText;
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final canApprove = auth.canApproveRequests;
    final hasEmployeeProfile = auth.user == null || auth.hasEmployeeProfile;

    if (auth.user != null && !canApprove && !hasEmployeeProfile) {
      return Scaffold(
        backgroundColor: AppColors.surfaceMuted,
        appBar: AppBar(
          title: const Row(
            children: [
              HrHubLogo(size: 24),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Pengajuan Lembur',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
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
              icon: LucideIcons.shieldAlert,
              title: 'Profil Karyawan Belum Terhubung',
              description:
                  'Akun Anda (${auth.roleLabel}) belum terhubung dengan data karyawan.',
              actionText: 'Kembali',
              onAction: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );
    }

    final rawTab = ref.watch(overtimeViewTabProvider);
    final activeTab = canApprove
        ? (rawTab ?? 'approvals')
        : 'my-requests';
    final isApprovalView = canApprove && activeTab == 'approvals';

    if (isApprovalView) {
      final approvalFilter = ref.watch(overtimeApprovalFilterProvider);
      final approvalDateFilter = ref.watch(overtimeApprovalDateFilterProvider);
      final approvalsAsync =
          ref.watch(overtimeApprovalsProvider(approvalFilter));
      final allApprovalsAsync = ref.watch(overtimeApprovalsProvider(null));

      int countAll = 0;
      int countPending = 0;
      int countApproved = 0;
      int countRejected = 0;
      allApprovalsAsync.whenData((list) {
        countAll = list.length;
        countPending =
            list.where((r) => r.status == OvertimeStatus.pending).length;
        countApproved =
            list.where((r) => r.status == OvertimeStatus.approved).length;
        countRejected =
            list.where((r) => r.status == OvertimeStatus.rejected).length;
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
                    ref.invalidate(overtimeApprovalsProvider);
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
                                color: AppColors.textPrimary,
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
                              const _FilterOption(
                                value: 'cancelled',
                                label: 'Dibatalkan',
                                dotColor: AppColors.textMuted,
                              ),
                            ],
                            onApply: (status, date) {
                              ref
                                  .read(overtimeApprovalFilterProvider.notifier)
                                  .state = (status == null || status == 'all')
                                      ? null
                                      : status;
                              ref
                                  .read(overtimeApprovalDateFilterProvider
                                      .notifier)
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
                        error: (err, _) => AppErrorState(
                          isCard: true,
                          title: 'Gagal Memuat Daftar Persetujuan Lembur',
                          message: err is ApiException
                              ? err.userFriendlyMessage
                              : err.toString().replaceFirst('Exception: ', ''),
                          retryText: 'Coba Lagi',
                          onRetry: () =>
                              ref.invalidate(overtimeApprovalsProvider),
                        ),
                        data: (rawItems) {
                          final items = approvalDateFilter == null
                              ? rawItems
                              : rawItems
                                  .where((r) =>
                                      r.date.startsWith(approvalDateFilter))
                                  .toList();

                          if (items.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 32,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: AppColors.borderSubtle),
                              ),
                              child: AppEmptyState(
                                icon: PhosphorIconsRegular.clipboardText,
                                title: 'Belum Ada Pengajuan Lembur Staf',
                                description: (approvalFilter == null &&
                                        approvalDateFilter == null)
                                    ? 'Seluruh pengajuan lembur dari karyawan akan muncul di sini untuk Anda verifikasi.'
                                    : 'Tidak ada data pengajuan lembur karyawan dengan filter ini.',
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (ctx, idx) {
                              final item = items[idx];
                              return _OvertimeListCard(
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

    final activeFilter = ref.watch(overtimeStatusFilterProvider);
    final activeDateFilter = ref.watch(overtimeDateFilterProvider);
    final overtimeAsync = ref.watch(myOvertimeListProvider(activeFilter));
    final localDrafts =
        ref.watch(localOvertimeDraftsProvider).valueOrNull ?? [];
    final pendingApprovalsCount = canApprove
        ? (ref
                .watch(overtimeApprovalsProvider(null))
                .valueOrNull
                ?.where((r) => r.status == OvertimeStatus.pending)
                .length ??
            0)
        : 0;
    final showModeSwitcher = canApprove && hasEmployeeProfile;
    final fallbackOwnName =
        auth.userName.trim().isNotEmpty ? auth.userName.trim() : 'Karyawan';

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
                  ref.invalidate(myOvertimeListProvider);
                  ref.invalidate(localOvertimeDraftsProvider);
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
                    if (localDrafts.isNotEmpty) ...[
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Draf Tersimpan di Perangkat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          Text(
                            '${localDrafts.length} draf',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (int dIdx = 0; dIdx < localDrafts.length; dIdx++) ...[
                        if (dIdx > 0) const SizedBox(height: 10),
                        _LocalOvertimeDraftCard(
                          draft: localDrafts[dIdx],
                          onResume: () => _openApplyOvertime(
                            context,
                            ref,
                            draft: localDrafts[dIdx],
                          ),
                          onDelete: () => _deleteLocalDraft(
                            context,
                            ref,
                            localDrafts[dIdx],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
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
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusFilterPopupButton(
                          currentFilter: activeFilter,
                          currentDate: activeDateFilter,
                          options: const [
                            _FilterOption(value: 'all', label: 'Semua'),
                            _FilterOption(
                              value: 'pending',
                              label: 'Menunggu',
                              dotColor: AppColors.statusWarning,
                            ),
                            _FilterOption(
                              value: 'approved',
                              label: 'Disetujui',
                              dotColor: AppColors.statusSuccess,
                            ),
                            _FilterOption(
                              value: 'rejected',
                              label: 'Ditolak',
                              dotColor: AppColors.statusDanger,
                            ),
                            _FilterOption(
                              value: 'cancelled',
                              label: 'Dibatalkan',
                              dotColor: AppColors.textMuted,
                            ),
                          ],
                          onApply: (status, date) {
                            ref
                                .read(overtimeStatusFilterProvider.notifier)
                                .state = (status == null || status == 'all')
                                    ? null
                                    : status;
                            ref.read(overtimeDateFilterProvider.notifier).state =
                                date;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    overtimeAsync.when(
                      loading: () => const Column(
                        children: [
                          AppSkeleton(height: 180),
                          SizedBox(height: 12),
                          AppSkeleton(height: 180),
                          SizedBox(height: 12),
                          AppSkeleton(height: 180),
                        ],
                      ),
                      error: (err, _) => AppErrorState(
                        isCard: true,
                        title: 'Gagal Memuat Riwayat Lembur',
                        message: err is ApiException
                            ? err.userFriendlyMessage
                            : err.toString().replaceFirst('Exception: ', ''),
                        retryText: 'Coba Lagi',
                        onRetry: () => ref.invalidate(myOvertimeListProvider),
                      ),
                      data: (rawItems) {
                        final items = activeDateFilter == null
                            ? rawItems
                            : rawItems
                                .where((r) =>
                                    r.date.startsWith(activeDateFilter))
                                .toList();

                        if (items.isEmpty) {
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
                              icon: PhosphorIconsRegular.clockClockwise,
                              title: 'Belum Ada Pengajuan Lembur',
                              description: (activeFilter == null &&
                                      activeDateFilter == null)
                                  ? 'Anda belum pernah mengajukan jam lembur kerja. Tekan tombol + untuk membuat pengajuan baru.'
                                  : 'Tidak ada data pengajuan lembur dengan filter ini.',
                              actionText: 'Ajukan Lembur',
                              onAction: () => _openApplyOvertime(context, ref),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, idx) {
                            final item = items[idx];
                            return _OvertimeListCard(
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'overtime_add_fab',
        onPressed: () => _openApplyOvertime(context, ref),
        backgroundColor: AppColors.actionAccent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        tooltip: 'Ajukan Lembur Baru',
        child: const Icon(LucideIcons.plus, size: 24),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar({required AuthState auth}) {
    return AppBar(
      backgroundColor: AppColors.surfaceCard,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
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
              'Pengajuan Lembur',
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
            child: _OvertimeModeTabButton(
              label: 'Persetujuan Staf',
              badgeCount:
                  pendingApprovalCount > 0 ? pendingApprovalCount : null,
              isSelected: activeTab == 'approvals',
              onTap: () {
                ref.read(overtimeViewTabProvider.notifier).state = 'approvals';
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _OvertimeModeTabButton(
              label: 'Pengajuan Saya',
              badgeCount: null,
              isSelected: activeTab == 'my-requests',
              onTap: () {
                ref.read(overtimeViewTabProvider.notifier).state =
                    'my-requests';
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OvertimeListCard extends StatelessWidget {
  final OvertimeRequestModel item;
  final String fallbackEmployeeName;
  final VoidCallback onTap;

  const _OvertimeListCard({
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
    final startDateText = _formatDate(item.date);
    final rawEndDate =
        (item.end_date != null && item.end_date!.trim().isNotEmpty)
            ? item.end_date!
            : item.date;
    final endDateText = _formatDate(rawEndDate);

    return Container(
      key: Key('overtime_card_${item.id_overtime_requests}'),
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
                          final stackDates = effWidth < 230;
                          if (stackDates) {
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
                      _ListCardField(
                        label: 'Keterangan',
                        value: item.reason,
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
                      OvertimeStatusBadge(status: item.status),
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
      builder: (_) => _OvertimeFilterDialog(
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

class _OvertimeFilterDialog extends StatefulWidget {
  final String? initialStatus;
  final String? initialDate;
  final List<_FilterOption> options;

  const _OvertimeFilterDialog({
    required this.initialStatus,
    required this.initialDate,
    required this.options,
  });

  @override
  State<_OvertimeFilterDialog> createState() => _OvertimeFilterDialogState();
}

class _OvertimeFilterDialogState extends State<_OvertimeFilterDialog> {
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
      helpText: 'Pilih Tanggal Lembur',
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
                color: AppColors.textPrimary,
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
                                ? AppColors.textPrimary
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
            minimumSize: const Size(96, 42),
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

class _OvertimeModeTabButton extends StatelessWidget {
  final String label;
  final int? badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _OvertimeModeTabButton({
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

class _LocalOvertimeDraftCard extends StatelessWidget {
  final OvertimeDraftModel draft;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  const _LocalOvertimeDraftCard({
    required this.draft,
    required this.onResume,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    final fmt = DateFormat('d MMM yyyy', 'id_ID');
    final isSameDay = draft.startDate.year == draft.endDate.year &&
        draft.startDate.month == draft.endDate.month &&
        draft.startDate.day == draft.endDate.day;
    final rangeLabel = isSameDay
        ? fmt.format(draft.startDate)
        : '${fmt.format(draft.startDate)} - ${fmt.format(draft.endDate)}';

    final configuredCount = draft.configuredDayCount;
    final totalDays = draft.daySchedules.isNotEmpty
        ? draft.daySchedules.length
        : (draft.endDate.difference(draft.startDate).inDays + 1);

    Widget buildResumeBtn() {
      return ElevatedButton.icon(
        key: ValueKey('overtime_draft_resume_${draft.id}'),
        onPressed: onResume,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          minimumSize: const Size(0, AppDimensions.minTouchTarget),
          backgroundColor: AppColors.actionAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(LucideIcons.pencil, size: 15),
        label: const Text(
          'Lanjutkan',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      );
    }

    Widget buildDeleteBtn() {
      return OutlinedButton.icon(
        key: ValueKey('overtime_draft_delete_${draft.id}'),
        onPressed: onDelete,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          minimumSize: const Size(0, AppDimensions.minTouchTarget),
          side: const BorderSide(color: AppColors.dangerBorder),
          backgroundColor: AppColors.dangerBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: const Icon(
          LucideIcons.trash2,
          size: 15,
          color: Color(0xFFB91C1C),
        ),
        label: const Text(
          'Hapus',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB91C1C),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
        border: Border.all(color: AppColors.corporateChipBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        rangeLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.corporateChipBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Draf',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.actionAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${draft.overtimeType} • ${draft.reasonCategory} • $configuredCount/$totalDays hari diatur',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                if (draft.reason.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    draft.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                ],
                if (draft.attachmentName != null &&
                    draft.attachmentName!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.paperclip,
                        size: 13,
                        color: Color(0xFF475569),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Lampiran draf: ${draft.attachmentName!}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, actionConstraints) {
                final effectiveWidth = actionConstraints.maxWidth / textScale;
                if (effectiveWidth < 260) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildResumeBtn(),
                      const SizedBox(height: 8),
                      buildDeleteBtn(),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: buildDeleteBtn()),
                    const SizedBox(width: 8),
                    Expanded(child: buildResumeBtn()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
