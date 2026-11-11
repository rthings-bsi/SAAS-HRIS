import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../auth/provider/auth_provider.dart';
import '../data/overtime_models.dart';
import '../provider/overtime_provider.dart';
import 'overtime_day_schedule_sheet.dart';

class OvertimeDetailReviewScreen extends ConsumerStatefulWidget {
  final String employeeName;
  final String? employeePosition;
  final DateTime startDate;
  final DateTime endDate;
  final String overtimeType;
  final String reasonCategory;
  final String reason;
  final String? attachmentPath;
  final Uint8List? attachmentBytes;
  final String? attachmentName;
  final String? draftId;
  final int? revisingRequestId;
  final bool allowMultiEntryRevision;
  final bool removeAttachment;
  final bool hasExistingRemoteAttachment;
  final List<OvertimeDaySchedule> initialSchedules;
  final ValueChanged<List<OvertimeDaySchedule>>? onSchedulesChanged;

  const OvertimeDetailReviewScreen({
    super.key,
    required this.employeeName,
    this.employeePosition,
    required this.startDate,
    required this.endDate,
    required this.overtimeType,
    required this.reasonCategory,
    required this.reason,
    this.attachmentPath,
    this.attachmentBytes,
    this.attachmentName,
    this.draftId,
    this.revisingRequestId,
    this.allowMultiEntryRevision = false,
    this.removeAttachment = false,
    this.hasExistingRemoteAttachment = false,
    required this.initialSchedules,
    this.onSchedulesChanged,
  });

  bool get isRevision => revisingRequestId != null;

  @override
  ConsumerState<OvertimeDetailReviewScreen> createState() =>
      _OvertimeDetailReviewScreenState();
}

class _OvertimeDetailReviewScreenState
    extends ConsumerState<OvertimeDetailReviewScreen> {
  final ScrollController _scrollController = ScrollController();
  late List<OvertimeDaySchedule> _schedules;
  late final String _startIso;
  late final String _endIso;
  String? _submitError;
  bool _isSavingDraft = false;

  final DateFormat _metaDateFormat = DateFormat('d MMM yyyy', 'id_ID');
  final DateFormat _cardDateSameYearFormat = DateFormat('d MMM', 'id_ID');

  @override
  void initState() {
    super.initState();
    _schedules = widget.initialSchedules.map((d) => d.copy()).toList();
    _startIso = OvertimeSlotEntry.formatIsoDate(widget.startDate);
    _endIso = OvertimeSlotEntry.formatIsoDate(widget.endDate);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  String _formatHoursLabel(double hours) {
    final rounded = (hours * 10).roundToDouble() / 10;
    if ((rounded - hours).abs() < 0.01) {
      return '${rounded.toStringAsFixed(1)} jam';
    }
    return '${hours.toStringAsFixed(2)} jam';
  }

  int _resolveUserId() {
    final auth = ref.read(authStateProvider);
    final raw = auth.user?['id_users'] ?? auth.user?['id'] ?? 0;
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? 0;
  }

  Future<void> _openDaySheet(
    int index,
    OvertimeDayContext? dayContext,
  ) async {
    final day = _schedules[index];
    final isoKey = OvertimeSlotEntry.formatIsoDate(day.date);
    final actualAttendance = dayContext?.attendanceByDate[isoKey];

    final updatedSlots = await showModalBottomSheet<List<OvertimeSlotEntry>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OvertimeDayScheduleSheet(
        employeeName: widget.employeeName,
        employeePosition: widget.employeePosition,
        daySchedule: day.copy(),
        shiftName: dayContext?.shiftName,
        shiftRange: dayContext?.formattedShiftRange,
        actualAttendance: actualAttendance,
        allowMultipleSlots: !widget.isRevision || widget.allowMultiEntryRevision,
        allowReset: !widget.isRevision || widget.allowMultiEntryRevision,
      ),
    );

    if (updatedSlots != null && mounted) {
      setState(() {
        _schedules[index] = OvertimeDaySchedule(
          date: day.date,
          slots: updatedSlots.map((s) => s.copy()).toList(),
        );
        _submitError = null;
      });
      widget.onSchedulesChanged?.call(_schedules.map((d) => d.copy()).toList());
    }
  }

  Future<void> _saveDraft() async {
    if (_isSavingDraft) return;
    final userId = _resolveUserId();
    if (userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi pengguna tidak ditemukan untuk menyimpan draf.'),
          backgroundColor: AppColors.dangerText,
        ),
      );
      return;
    }

    setState(() {
      _isSavingDraft = true;
      _submitError = null;
    });

    try {
      final draft = OvertimeDraftModel(
        id: widget.draftId ??
            'draft_${DateTime.now().millisecondsSinceEpoch}',
        startDate: widget.startDate,
        endDate: widget.endDate,
        overtimeType: widget.overtimeType,
        reasonCategory: widget.reasonCategory,
        reason: widget.reason,
        daySchedules: _schedules.map((d) => d.copy()).toList(),
        attachmentName: widget.attachmentName,
        savedAt: DateTime.now(),
      );

      await ref.read(overtimeDraftServiceProvider).saveDraft(userId, draft);
      ref.invalidate(localOvertimeDraftsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draf lembur tersimpan di perangkat.'),
          backgroundColor: AppColors.inkPrimary,
        ),
      );
      Navigator.of(context).pop('draft_saved');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSavingDraft = false;
        _submitError = 'Gagal menyimpan draf lembur di perangkat.';
      });
    }
  }

  DateTime? _parseRequestBoundary(String dateStr, String timeStr) {
    try {
      final d = DateTime.parse(dateStr.trim());
      final t = OvertimeSlotEntry.parseTime(timeStr.trim());
      if (t == null) return null;
      return DateTime(d.year, d.month, d.day, t.hour, t.minute);
    } catch (_) {
      return null;
    }
  }

  String? _findOverlapConflict(
    List<OvertimeSlotEntry> slots,
    List<OvertimeRequestModel> existingRequests,
  ) {
    final activeRequests = existingRequests.where(
      (r) =>
          (widget.revisingRequestId == null ||
              r.id_overtime_requests != widget.revisingRequestId) &&
          (r.status == OvertimeStatus.pending ||
              r.status == OvertimeStatus.approved),
    );

    for (final slot in slots) {
      final slotStart = slot.startDateTime;
      final slotEnd = slot.endDateTime;
      if (slotStart == null || slotEnd == null) continue;

      for (final req in activeRequests) {
        for (final reqItem in req.effectiveItems) {
          final reqEndDate = reqItem.effectiveEndDate;
          final reqStart =
              _parseRequestBoundary(reqItem.date, reqItem.start_time);
          final reqEnd = _parseRequestBoundary(reqEndDate, reqItem.end_time);
          if (reqStart == null || reqEnd == null) continue;

          if (reqStart.isBefore(slotEnd) && reqEnd.isAfter(slotStart)) {
            final dayLabel = _metaDateFormat.format(slot.startDate);
            final timeLabel =
                '${OvertimeSlotEntry.formatTime(slot.startTime)}-${OvertimeSlotEntry.formatTime(slot.endTime)}';
            return 'Jadwal $dayLabel ($timeLabel) tumpang tindih dengan pengajuan aktif.';
          }
        }
      }
    }
    return null;
  }

  void _revealInlineError(String message) {
    setState(() {
      _submitError = message;
    });
    if (_scrollController.hasClients && _scrollController.offset > 120) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSubmit() async {
    final validSlots = _schedules.expand((d) => d.validSlots).toList();
    if (validSlots.isEmpty) {
      _revealInlineError(
        'Atur jam lembur minimal pada 1 hari sebelum mengajukan.',
      );
      return;
    }

    final existingRequests =
        ref.read(myOvertimeListProvider(null)).valueOrNull ?? [];
    final conflictMsg = _findOverlapConflict(validSlots, existingRequests);
    if (conflictMsg != null) {
      _revealInlineError(conflictMsg);
      return;
    }

    final configuredDays = _schedules.where((d) => d.isConfigured).length;
    if (configuredDays < _schedules.length) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text(
            'Konfirmasi Pengajuan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.inkPrimary,
            ),
          ),
          content: Text(
            'Hanya $configuredDays dari ${_schedules.length} hari yang sudah diisi jam lemburnya. Lanjutkan mengajukan $configuredDays hari tersebut?',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textBody,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Lengkapi',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.actionAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Ajukan $configuredDays Hari',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

      if (proceed != true || !mounted) return;
    }

    setState(() {
      _submitError = null;
    });

    final entries = validSlots
        .map(
          (slot) => {
            'date': OvertimeSlotEntry.formatIsoDate(slot.startDate),
            'end_date': OvertimeSlotEntry.formatIsoDate(slot.endDate),
            'start_time': OvertimeSlotEntry.formatTime(slot.startTime),
            'end_time': OvertimeSlotEntry.formatTime(slot.endTime),
          },
        )
        .toList();

    if (widget.isRevision) {
      final slot = validSlots.first;
      final sendEntries =
          widget.allowMultiEntryRevision || validSlots.length > 1;
      final ok = await ref.read(overtimeActionProvider.notifier).updateOvertime(
            id: widget.revisingRequestId!,
            date: OvertimeSlotEntry.formatIsoDate(slot.startDate),
            endDate: OvertimeSlotEntry.formatIsoDate(slot.endDate),
            startTime: OvertimeSlotEntry.formatTime(slot.startTime),
            endTime: OvertimeSlotEntry.formatTime(slot.endTime),
            reason: widget.reason,
            entries: sendEntries ? entries : null,
            overtimeType: widget.overtimeType,
            reasonCategory: widget.reasonCategory,
            attachmentPath: widget.attachmentPath,
            attachmentBytes: widget.attachmentBytes,
            attachmentName: widget.attachmentName,
            removeAttachment: widget.removeAttachment,
          );

      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        final errMsg = ref.read(overtimeActionProvider).errorMessage ??
            'Gagal menyimpan revisi lembur.';
        _revealInlineError(errMsg);
      }
      return;
    }

    final ok = await ref.read(overtimeActionProvider.notifier).submitOvertimeForm(
          entries: entries,
          reason: widget.reason,
          overtimeType: widget.overtimeType,
          reasonCategory: widget.reasonCategory,
          attachmentPath: widget.attachmentPath,
          attachmentBytes: widget.attachmentBytes,
          attachmentName: widget.attachmentName,
        );

    if (!mounted) return;
    if (ok) {
      final userId = _resolveUserId();
      if (widget.draftId != null && userId > 0) {
        try {
          await ref
              .read(overtimeDraftServiceProvider)
              .deleteDraft(userId, widget.draftId!);
          ref.invalidate(localOvertimeDraftsProvider);
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      final errMsg = ref.read(overtimeActionProvider).errorMessage ??
          'Gagal mengirim pengajuan lembur.';
      _revealInlineError(errMsg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dayContextAsync = ref.watch(
      overtimeDayContextProvider((startDate: _startIso, endDate: _endIso)),
    );
    // Keep active requests synced so overlap validation has fresh data
    ref.watch(myOvertimeListProvider(null));
    final actionState = ref.watch(overtimeActionProvider);
    final dayContext = dayContextAsync.valueOrNull;

    final configuredCount = _schedules.where((d) => d.isConfigured).length;
    final multiYear = widget.startDate.year != widget.endDate.year;
    final hasRealAttachment = (widget.attachmentBytes != null &&
            widget.attachmentBytes!.isNotEmpty) ||
        (widget.attachmentPath != null && widget.attachmentPath!.isNotEmpty);

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
              key: const Key('overtime_review_back_btn'),
              onPressed: () => Navigator.of(context).maybePop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.inkPrimary,
                minimumSize: const Size(44, 48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              icon: const Icon(LucideIcons.chevronLeft, size: 20),
              label: const Text(
                'Kembali',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Text(
                widget.isRevision ? 'Rincian Revisi Lembur' : 'Rincian Form Lembur',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (screenWidth >= 380) const SizedBox(width: 72),
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

              if (_schedules.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(hPad),
                  child: AppEmptyState(
                    icon: LucideIcons.calendarX,
                    title: 'Tidak Ada Tanggal Lembur',
                    description:
                        'Rentang tanggal belum dipilih. Kembali ke form untuk menentukan tanggal lembur.',
                    actionText: 'Kembali ke Form',
                    onAction: () => Navigator.of(context).maybePop(),
                  ),
                );
              }

              return ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 24),
                children: [
                  const Text(
                    'Permintaan Untuk',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _initialsFromName(widget.employeeName),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.employeeName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkPrimary,
                              ),
                            ),
                            if (widget.employeePosition != null &&
                                widget.employeePosition!.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.employeePosition!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTwoColumnPair(
                    stack: stackPairs,
                    left: _SummaryMetaColumn(
                      label: 'Tanggal Mulai',
                      value: _metaDateFormat.format(widget.startDate),
                    ),
                    right: _SummaryMetaColumn(
                      label: 'Tanggal Berakhir',
                      value: _metaDateFormat.format(
                        (widget.isRevision &&
                                !widget.allowMultiEntryRevision &&
                                _schedules.isNotEmpty &&
                                _schedules.first.validSlots.isNotEmpty)
                            ? _schedules.first.validSlots.first.endDate
                            : widget.endDate,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTwoColumnPair(
                    stack: stackPairs,
                    left: _SummaryMetaColumn(
                      label: 'Tipe Lembur',
                      value: widget.overtimeType,
                    ),
                    right: _SummaryMetaColumn(
                      label: 'Alasan Lembur',
                      value: widget.reasonCategory,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SummaryMetaColumn(
                    label: 'Keterangan',
                    value: widget.reason,
                  ),
                  if ((widget.attachmentName != null &&
                          widget.attachmentName!.trim().isNotEmpty) ||
                      widget.removeAttachment) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            LucideIcons.paperclip,
                            size: 14,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hasRealAttachment
                                ? 'Lampiran: ${widget.attachmentName!}'
                                : (widget.removeAttachment
                                    ? 'Lampiran: Akan dihapus saat revisi disimpan'
                                    : (widget.hasExistingRemoteAttachment
                                        ? 'Lampiran tersimpan: ${widget.attachmentName!}'
                                        : 'Lampiran draf: ${widget.attachmentName!} (belum diunggah ulang)')),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text(
                        'DETAIL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.borderSubtle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$configuredCount/${_schedules.length} hari',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (dayContextAsync.isLoading) ...[
                    const Row(
                      children: [
                        Expanded(child: AppSkeleton(height: 16)),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ] else if (dayContextAsync.hasError) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Gagal memuat jadwal shift & presensi aktual.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => ref.invalidate(
                              overtimeDayContextProvider(
                                (startDate: _startIso, endDate: _endIso),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.actionAccent,
                              minimumSize: const Size(44, 44),
                            ),
                            child: const Text(
                              'Muat Ulang',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_submitError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.circleAlert,
                            size: 16,
                            color: Color(0xFFB91C1C),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _submitError!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  for (int i = 0; i < _schedules.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _buildDayCard(
                      index: i,
                      day: _schedules[i],
                      dayContext: dayContext,
                      multiYear: multiYear,
                      stackBody: stackPairs,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
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
                  final draftBtn = OutlinedButton(
                    key: const Key('overtime_save_draft_btn'),
                    onPressed:
                        (actionState.isLoading || _isSavingDraft) ? null : _saveDraft,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.actionAccent,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.borderNeutral),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _isSavingDraft
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Draf'),
                  );

                  final submitBtn = ElevatedButton(
                    key: const Key('overtime_submit_btn'),
                    onPressed:
                        (actionState.isLoading || _isSavingDraft) ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.actionAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: actionState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.isRevision ? 'Simpan Revisi' : 'Ajukan'),
                  );

                  if (widget.isRevision) {
                    return SizedBox(
                      width: double.infinity,
                      child: submitBtn,
                    );
                  }

                  if (effWidth < 250) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        draftBtn,
                        const SizedBox(height: 10),
                        submitBtn,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: draftBtn),
                      const SizedBox(width: 12),
                      Expanded(child: submitBtn),
                    ],
                  );
                },
              ),
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

  Widget _buildDayCard({
    required int index,
    required OvertimeDaySchedule day,
    required OvertimeDayContext? dayContext,
    required bool multiYear,
    required bool stackBody,
  }) {
    final titleDate = multiYear
        ? _metaDateFormat.format(day.date)
        : _cardDateSameYearFormat.format(day.date);
    final validSlots = day.validSlots;
    final shiftDisplayName = (dayContext?.shiftName != null &&
            dayContext!.shiftName!.trim().isNotEmpty)
        ? dayContext.shiftName!.trim()
        : '-';
    final cardColor =
        day.isConfigured ? AppColors.surfaceMuted : AppColors.surfaceCard;
    final cardBorder =
        day.isConfigured ? AppColors.borderNeutral : AppColors.borderSubtle;

    Widget buildSlotLines() {
      if (validSlots.length <= 1) {
        final single = validSlots.isNotEmpty ? validSlots.first : null;
        final isCross = single != null &&
            OvertimeSlotEntry.formatIsoDate(single.endDate) !=
                OvertimeSlotEntry.formatIsoDate(single.startDate);
        return Text(
          'Mulai: ${day.summaryStartText} | Berakhir: ${day.summaryEndText}${isCross ? ' (+1 hr)' : ''}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: day.isConfigured ? FontWeight.w600 : FontWeight.w500,
            color:
                day.isConfigured ? AppColors.inkPrimary : const Color(0xFF475569),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int sIdx = 0; sIdx < validSlots.length; sIdx++) ...[
            if (sIdx > 0) const SizedBox(height: 3),
            Text(
              () {
                final s = validSlots[sIdx];
                final isCross = OvertimeSlotEntry.formatIsoDate(s.endDate) !=
                    OvertimeSlotEntry.formatIsoDate(s.startDate);
                return 'Sesi ${sIdx + 1}: ${OvertimeSlotEntry.formatTime(s.startTime)} - ${OvertimeSlotEntry.formatTime(s.endTime)}${isCross ? ' (+1 hr)' : ''}';
              }(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.inkPrimary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      );
    }

    Widget buildShiftActionColumn() {
      return Column(
        crossAxisAlignment:
            stackBody ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Text(
            shiftDisplayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: stackBody ? TextAlign.start : TextAlign.end,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Perbarui',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.actionAccent,
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: 'Atur jam lembur tanggal $titleDate',
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key('overtime_day_card_$index'),
          onTap: () => _openDaySheet(index, dayContext),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titleDate,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                    ),
                    if (day.isConfigured) ...[
                      Text(
                        _formatHoursLabel(day.totalHours),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.actionAccent,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(
                      LucideIcons.pencil,
                      size: 16,
                      color: AppColors.actionAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderSubtle,
                ),
                const SizedBox(height: 10),
                if (stackBody) ...[
                  buildSlotLines(),
                  const SizedBox(height: 8),
                  buildShiftActionColumn(),
                ] else
                  LayoutBuilder(
                    builder: (context, rowConstraints) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: buildSlotLines()),
                          const SizedBox(width: 12),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: rowConstraints.maxWidth * 0.42,
                            ),
                            child: buildShiftActionColumn(),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryMetaColumn extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetaColumn({
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
