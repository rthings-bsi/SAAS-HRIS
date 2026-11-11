import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../auth/provider/auth_provider.dart';
import '../data/leave_models.dart';
import '../provider/leave_provider.dart';
import 'apply_leave_screen.dart';
import 'leave_action_dialogs.dart';

typedef LeaveDetailResult = ({String outcome, String? message});

class LeaveDetailScreen extends ConsumerWidget {
  final LeaveRequestModel item;
  final bool isApprovalView;

  const LeaveDetailScreen({
    super.key,
    required this.item,
    this.isApprovalView = false,
  });

  String _isoDateOnly(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length >= 10) {
      return trimmed.substring(0, 10);
    }
    return trimmed;
  }

  DateTime? _parseDate(String raw) {
    final isoOnly = _isoDateOnly(raw);
    if (isoOnly.isEmpty) return null;
    return DateTime.tryParse(isoOnly) ?? DateTime.tryParse(raw.trim());
  }

  String _formatFullDate(String raw, {bool isTimestamp = false}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    if (isTimestamp) {
      final parsed = DateTime.tryParse(trimmed);
      if (parsed == null) return trimmed;
      return DateFormat('d MMM yyyy', 'id_ID').format(parsed.toLocal());
    }
    final parsed = _parseDate(trimmed);
    if (parsed == null) return trimmed;
    return DateFormat('d MMM yyyy', 'id_ID').format(parsed);
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'KR';
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  String _extractAttachmentName(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last.trim();
      if (last.isNotEmpty) return last;
    }
    return 'Lampiran Cuti';
  }

  bool _isImageAttachment(String url) {
    final clean = url.split('?').first.toLowerCase();
    return clean.endsWith('.jpg') ||
        clean.endsWith('.jpeg') ||
        clean.endsWith('.png') ||
        clean.endsWith('.gif') ||
        clean.endsWith('.webp');
  }

  void _completeWithOutcome(
    BuildContext context, {
    required String outcome,
    required String message,
    required Color snackColor,
  }) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop<LeaveDetailResult>((outcome: outcome, message: message));
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: snackColor,
        ),
      );
  }

  Future<void> _handleApproval(
    BuildContext context,
    WidgetRef ref, {
    required bool isApprove,
  }) async {
    final notesResult = await showDialog<String>(
      context: context,
      builder: (_) => LeaveApprovalDialog(
        item: item,
        isApprove: isApprove,
      ),
    );
    if (notesResult == null || !context.mounted) return;

    final success =
        await ref.read(leaveActionProvider.notifier).processApproval(
              id: item.id_leave_requests,
              action: isApprove ? 'approved' : 'rejected',
              notes: notesResult.isNotEmpty ? notesResult : null,
            );
    if (!context.mounted) return;

    final actionState = ref.read(leaveActionProvider);
    if (success) {
      final fallbackMsg = isApprove
          ? 'Pengajuan cuti berhasil disetujui.'
          : 'Pengajuan cuti telah ditolak.';
      _completeWithOutcome(
        context,
        outcome: isApprove ? 'approved' : 'rejected',
        message: actionState.successMessage ?? fallbackMsg,
        snackColor: isApprove ? const Color(0xFF047857) : const Color(0xFFB91C1C),
      );
    } else if (actionState.errorMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(actionState.errorMessage!),
            backgroundColor: const Color(0xFFB91C1C),
          ),
        );
    }
  }

  Future<void> _openAttachmentModal(BuildContext context, String url) async {
    final filename = _extractAttachmentName(url);
    final isImg = _isImageAttachment(url);

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              LucideIcons.paperclip,
              size: 18,
              color: AppColors.actionAccent,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Lampiran Pengajuan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Tutup',
              onPressed: () => Navigator.of(dialogCtx).pop(),
              constraints: const BoxConstraints(
                minWidth: AppDimensions.minTouchTarget,
                minHeight: AppDimensions.minTouchTarget,
              ),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isImg) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const SizedBox(
                          height: 140,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              LucideIcons.imageOff,
                              size: 18,
                              color: Color(0xFF475569),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pratinjau gambar tidak tersedia saat ini.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              const Text(
                'Nama Berkas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                filename,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tautan Berkas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                url,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton.icon(
            key: const Key('leave_attachment_copy_btn'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!dialogCtx.mounted) return;
              Navigator.of(dialogCtx).pop();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Tautan lampiran disalin.'),
                    backgroundColor: AppColors.inkPrimary,
                  ),
                );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.actionAccent,
              side: const BorderSide(color: AppColors.borderNeutral),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(LucideIcons.copy, size: 15),
            label: const Text(
              'Salin Tautan',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.actionAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final auth = ref.watch(authStateProvider);
    final actionState = ref.watch(leaveActionProvider);

    final rawItemName = item.employee_name?.trim();
    final empName = (rawItemName != null && rawItemName.isNotEmpty)
        ? rawItemName
        : (!isApprovalView && auth.userName.isNotEmpty
            ? auth.userName
            : 'Karyawan');

    final rawItemPos = item.employee_position?.trim();
    final rawItemDept = item.employee_department?.trim();
    final String? empPos;
    if (rawItemPos != null && rawItemPos.isNotEmpty) {
      empPos = rawItemPos;
    } else if (rawItemDept != null && rawItemDept.isNotEmpty) {
      empPos = rawItemDept;
    } else if (!isApprovalView) {
      empPos = auth.jobPositionName ?? auth.departmentName;
    } else if (item.employee_nik != null && item.employee_nik!.trim().isNotEmpty) {
      empPos = item.employee_nik!.trim();
    } else {
      empPos = null;
    }

    final startDateLabel = _formatFullDate(item.start_date);
    final rawEndDate =
        item.end_date.trim().isNotEmpty ? item.end_date : item.start_date;
    final endDateLabel = _formatFullDate(rawEndDate);
    final requestDateLabel =
        (item.created_at != null && item.created_at!.trim().isNotEmpty)
            ? _formatFullDate(item.created_at!, isTimestamp: true)
            : startDateLabel;

    final parsedStart = _parseDate(item.start_date);
    final parsedEnd = _parseDate(rawEndDate) ?? parsedStart;
    final int? workingDays = (parsedStart != null && parsedEnd != null)
        ? calculateWorkingDays(parsedStart, parsedEnd)
        : null;
    final periodSummary = startDateLabel == endDateLabel
        ? startDateLabel
        : '$startDateLabel - $endDateLabel';

    final resolvedAttachmentUrl = item.resolvedAttachmentUrl;
    final hasAttachment = resolvedAttachmentUrl != null;

    final hasStatusBanner = (item.status == LeaveStatus.approved &&
            item.approver_name != null &&
            item.approver_name!.trim().isNotEmpty) ||
        (item.status == LeaveStatus.rejected &&
            item.rejection_note != null &&
            item.rejection_note!.trim().isNotEmpty) ||
        (item.status == LeaveStatus.cancelled &&
            item.rejection_note != null &&
            item.rejection_note!.trim().isNotEmpty);

    final showManagerActions =
        isApprovalView && item.status == LeaveStatus.pending;

    return Scaffold(
      backgroundColor: AppColors.surfaceCard,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.borderSubtle,
            height: 1.0,
          ),
        ),
        title: Row(
          children: [
            TextButton.icon(
              key: const Key('leave_detail_back_btn'),
              onPressed: () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.inkPrimary,
                minimumSize: const Size(44, AppDimensions.minTouchTarget),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(LucideIcons.chevronLeft, size: 20),
              label: const Text(
                'Kembali',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Semantics(
                header: true,
                child: const Text(
                  'Rincian Pengajuan Cuti',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            SizedBox(width: screenWidth >= 380 ? 16 : 8),
          ],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: LayoutBuilder(
            builder: (context, viewportConstraints) {
              final hPad = viewportConstraints.maxWidth < 310 ? 12.0 : 20.0;
              final effWidth =
                  (viewportConstraints.maxWidth - (hPad * 2)) / textScale;
              final stackPairs = effWidth < 260;

              return ListView(
                padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 28),
                children: [
                  if (stackPairs) ...[
                    _DetailMetaColumn(
                      label: 'Nomor Pengajuan',
                      value: item.displayRequestNumber,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: LeaveStatusBadge(status: item.status),
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _DetailMetaColumn(
                            label: 'Nomor Pengajuan',
                            value: item.displayRequestNumber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: LeaveStatusBadge(status: item.status),
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),
                  _DetailMetaColumn(
                    label: 'Tanggal Pengajuan',
                    value: requestDateLabel,
                  ),
                  const SizedBox(height: 16),
                  _buildTwoColumnPair(
                    stack: stackPairs,
                    left: _PersonIdentityBlock(
                      label: 'Permintaan Untuk',
                      name: empName,
                      position: empPos,
                      initials: _initialsFromName(empName),
                    ),
                    right: _PersonIdentityBlock(
                      label: 'Diajukan Oleh',
                      name: empName,
                      position: empPos,
                      initials: _initialsFromName(empName),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTwoColumnPair(
                    stack: stackPairs,
                    left: _CalendarMetaColumn(
                      label: 'Tanggal Mulai',
                      value: startDateLabel,
                    ),
                    right: _CalendarMetaColumn(
                      label: 'Tanggal Berakhir',
                      value: endDateLabel,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildTwoColumnPair(
                    stack: stackPairs,
                    left: _DetailMetaColumn(
                      label: 'Jenis Cuti',
                      value: item.leave_type_name,
                    ),
                    right: _DetailMetaColumn(
                      label: 'Kategori Upah',
                      value: item.categoryLabel,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailMetaColumn(
                    label: 'Keterangan',
                    value: item.reason.isNotEmpty ? item.reason : '-',
                  ),
                  if (hasAttachment) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Lampiran',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Material(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        key: const Key('leave_detail_attachment_btn'),
                        onTap: () =>
                            _openAttachmentModal(context, resolvedAttachmentUrl),
                        borderRadius: BorderRadius.circular(10),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppDimensions.minTouchTarget,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.paperclip,
                                  size: 16,
                                  color: AppColors.actionAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _extractAttachmentName(resolvedAttachmentUrl),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.inkPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Lihat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.actionAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (hasStatusBanner) ...[
                    const SizedBox(height: 14),
                    _buildStatusBanner(item),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    key: const Key('leave_detail_summary_box'),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (context, headerConstraints) {
                            final maxTitleWidth =
                                (headerConstraints.maxWidth - 28)
                                    .clamp(80.0, headerConstraints.maxWidth);
                            return Row(
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: maxTitleWidth,
                                  ),
                                  child: const Text(
                                    'DETAIL PENGAJUAN CUTI',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                      letterSpacing: 0.45,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppColors.borderSubtle,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Text(
                          periodSummary,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.leave_type_name} (${item.categoryLabel})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildTwoColumnPair(
                          stack: stackPairs,
                          left: _DetailMetaColumn(
                            label: 'Durasi Kalender',
                            value: '${item.total_days} hari',
                          ),
                          right: _DetailMetaColumn(
                            label: 'Hari Kerja Efektif',
                            value: workingDays != null
                                ? '$workingDays hari kerja'
                                : '-',
                          ),
                        ),
                        if (item.approver_name != null &&
                            item.approver_name!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _DetailMetaColumn(
                            label: 'Ditinjau Oleh',
                            value: item.approver_name!.trim(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: showManagerActions
          ? _buildApprovalBottomBar(
              context: context,
              ref: ref,
              textScale: textScale,
              isLoading: actionState.isLoading,
            )
          : null,
    );
  }

  Widget _buildStatusBanner(LeaveRequestModel req) {
    if (req.status == LeaveStatus.approved && req.approver_name != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.circleCheck,
              size: 16,
              color: Color(0xFF047857),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Disetujui oleh: ${req.approver_name}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF047857),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (req.status == LeaveStatus.rejected &&
        req.rejection_note != null &&
        req.rejection_note!.trim().isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                LucideIcons.info,
                size: 16,
                color: Color(0xFFB91C1C),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Alasan penolakan: ${req.rejection_note!}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFB91C1C),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (req.status == LeaveStatus.cancelled &&
        req.rejection_note != null &&
        req.rejection_note!.trim().isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                LucideIcons.circleX,
                size: 16,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Alasan pembatalan: ${req.rejection_note!}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildApprovalBottomBar({
    required BuildContext context,
    required WidgetRef ref,
    required double textScale,
    required bool isLoading,
  }) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Align(
          heightFactor: 1.0,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: LayoutBuilder(
              builder: (context, footerConstraints) {
                final effWidth = footerConstraints.maxWidth / textScale;
                final stackActions = effWidth < 260;

                final rejectBtn = OutlinedButton.icon(
                  key: const Key('leave_detail_reject_btn'),
                  onPressed: isLoading
                      ? null
                      : () => _handleApproval(context, ref, isApprove: false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                    backgroundColor: AppColors.dangerBg,
                    side: const BorderSide(color: AppColors.dangerBorder),
                    minimumSize: const Size(0, AppDimensions.minTouchTarget),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: const Text('Tolak'),
                );

                final approveBtn = ElevatedButton.icon(
                  key: const Key('leave_detail_approve_btn'),
                  onPressed: isLoading
                      ? null
                      : () => _handleApproval(context, ref, isApprove: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, AppDimensions.minTouchTarget),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.check, size: 16),
                  label: const Text('Setujui'),
                );

                if (stackActions) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      approveBtn,
                      const SizedBox(height: 10),
                      rejectBtn,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: rejectBtn),
                    const SizedBox(width: 12),
                    Expanded(child: approveBtn),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTwoColumnPair({
    required bool stack,
    required Widget left,
    required Widget right,
  }) {
    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          const SizedBox(height: 10),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }
}

class _PersonIdentityBlock extends StatelessWidget {
  final String label;
  final String name;
  final String? position;
  final String initials;

  const _PersonIdentityBlock({
    required this.label,
    required this.name,
    required this.position,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkPrimary,
                      height: 1.25,
                    ),
                  ),
                  if (position != null && position!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      position!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CalendarMetaColumn extends StatelessWidget {
  final String label;
  final String value;

  const _CalendarMetaColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              LucideIcons.calendar,
              size: 15,
              color: Color(0xFF475569),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailMetaColumn extends StatelessWidget {
  final String label;
  final String value;

  const _DetailMetaColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.inkPrimary,
            height: 1.35,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
