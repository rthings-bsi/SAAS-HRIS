import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../auth/provider/auth_provider.dart';
import '../data/overtime_models.dart';
import '../provider/overtime_provider.dart';
import 'overtime_detail_review_screen.dart';

class PickedOvertimeAttachment {
  final String name;
  final String? path;
  final Uint8List? bytes;
  final int size;
  final String? extension;

  const PickedOvertimeAttachment({
    required this.name,
    this.path,
    this.bytes,
    required this.size,
    this.extension,
  });
}

class ApplyOvertimeFormScreen extends ConsumerStatefulWidget {
  final OvertimeDraftModel? initialDraft;
  final OvertimeRequestModel? existingRequest;
  final Future<PickedOvertimeAttachment?> Function()? onPickAttachment;

  const ApplyOvertimeFormScreen({
    super.key,
    this.initialDraft,
    this.existingRequest,
    this.onPickAttachment,
  });

  @override
  ConsumerState<ApplyOvertimeFormScreen> createState() =>
      _ApplyOvertimeFormScreenState();
}

class _ApplyOvertimeFormScreenState
    extends ConsumerState<ApplyOvertimeFormScreen> {
  static const List<String> _overtimeTypes = [
    'Jam Lembur',
    'Lembur Hari Libur',
    'Lembur Sebelum Shift',
    'Lembur Setelah Shift',
  ];

  static const List<String> _reasonCategories = [
    'Lembur',
    'Penyelesaian Target / Proyek',
    'Dukungan Operasional',
    'Perbaikan / Maintenance',
    'Inventaris / Audit',
  ];

  static const List<String> _allowedExtensions = [
    'txt',
    'doc',
    'docx',
    'jpg',
    'png',
    'gif',
    'xls',
    'xlsx',
    'pdf',
    'jpeg',
  ];

  static const int _maxAttachmentBytes = 5 * 1024 * 1024;
  static const int _maxSpanDays = 31;

  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  late DateTime _startDate;
  late DateTime _endDate;
  late String _overtimeType;
  late String _reasonCategory;

  String? _draftId;
  String? _draftPreviousAttachmentName;
  String? _existingRemoteAttachmentName;
  bool _removeExistingAttachment = false;
  String? _attachmentPath;
  Uint8List? _attachmentBytes;
  String? _attachmentName;
  int? _attachmentSizeBytes;
  bool _isPickingFile = false;
  bool _hasTriedSubmit = false;

  final Map<String, OvertimeDaySchedule> _cachedSchedulesByIso = {};

  bool get _isRevision => widget.existingRequest != null;
  bool get _isMultiEntryRevision =>
      widget.existingRequest != null &&
      (widget.existingRequest!.items?.length ?? 0) > 1;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingRequest;
    final draft = widget.initialDraft;
    if (existing != null) {
      _applyExistingRequestValues(existing);
    } else if (draft != null) {
      _applyDraftValues(draft, notifyUi: false);
    } else {
      final today = _normalizeDate(DateTime.now());
      _startDate = today;
      _endDate = today;
      _overtimeType = _overtimeTypes.first;
      _reasonCategory = _reasonCategories.first;
    }
  }

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  String? _extractAttachmentName(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final uri = Uri.tryParse(url.trim());
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last.trim();
      if (last.isNotEmpty) return last;
    }
    return 'Lampiran tersimpan';
  }

  void _applyExistingRequestValues(OvertimeRequestModel existing) {
    final typeRaw = existing.overtime_type?.trim();
    final catRaw = existing.reason_category?.trim();

    _overtimeType =
        (typeRaw != null && typeRaw.isNotEmpty) ? typeRaw : _overtimeTypes.first;
    _reasonCategory =
        (catRaw != null && catRaw.isNotEmpty) ? catRaw : _reasonCategories.first;
    _reasonController.text = existing.reason;
    _existingRemoteAttachmentName = _extractAttachmentName(existing.attachment_url);
    _removeExistingAttachment = false;

    _cachedSchedulesByIso.clear();

    final existingItems = existing.items ?? const [];
    if (existingItems.length > 1) {
      final groupedSlots = <String, List<OvertimeSlotEntry>>{};
      DateTime? minDay;
      DateTime? maxDay;

      for (final item in existingItems) {
        final sDateRaw =
            DateTime.tryParse(item.date) ?? _normalizeDate(DateTime.now());
        final sDay = _normalizeDate(sDateRaw);
        var eDay = DateTime.tryParse(item.effectiveEndDate) ?? sDay;
        eDay = _normalizeDate(eDay);
        if (eDay.isBefore(sDay)) {
          eDay = sDay;
        }

        if (minDay == null || sDay.isBefore(minDay)) minDay = sDay;
        if (maxDay == null || sDay.isAfter(maxDay)) maxDay = sDay;

        final iso = OvertimeSlotEntry.formatIsoDate(sDay);
        groupedSlots.putIfAbsent(iso, () => []).add(
              OvertimeSlotEntry(
                startDate: sDay,
                endDate: eDay,
                startTime: OvertimeSlotEntry.parseTime(item.start_time) ??
                    const TimeOfDay(hour: 17, minute: 0),
                endTime: OvertimeSlotEntry.parseTime(item.end_time) ??
                    const TimeOfDay(hour: 20, minute: 0),
              ),
            );
      }

      final resolvedStart = minDay ?? _normalizeDate(DateTime.now());
      var resolvedEnd = maxDay ?? resolvedStart;
      if (resolvedEnd.difference(resolvedStart).inDays + 1 > _maxSpanDays) {
        resolvedEnd = resolvedStart.add(const Duration(days: _maxSpanDays - 1));
      }

      _startDate = resolvedStart;
      _endDate = resolvedEnd;

      groupedSlots.forEach((iso, slots) {
        final dayDate = slots.first.startDate;
        _cachedSchedulesByIso[iso] = OvertimeDaySchedule(
          date: dayDate,
          slots: slots,
        );
      });
      return;
    }

    final parsedStart =
        DateTime.tryParse(existing.date) ?? _normalizeDate(DateTime.now());
    final normStart = _normalizeDate(parsedStart);
    var slotEnd = DateTime.tryParse(existing.end_date ?? '') ?? normStart;
    slotEnd = _normalizeDate(slotEnd);
    if (slotEnd.isBefore(normStart)) {
      slotEnd = normStart;
    }

    _startDate = normStart;
    _endDate = normStart;

    final startTime = OvertimeSlotEntry.parseTime(existing.start_time) ??
        const TimeOfDay(hour: 17, minute: 0);
    final endTime = OvertimeSlotEntry.parseTime(existing.end_time) ??
        const TimeOfDay(hour: 20, minute: 0);

    _cachedSchedulesByIso[OvertimeSlotEntry.formatIsoDate(normStart)] =
        OvertimeDaySchedule(
      date: normStart,
      slots: [
        OvertimeSlotEntry(
          startDate: normStart,
          endDate: slotEnd,
          startTime: startTime,
          endTime: endTime,
        ),
      ],
    );
  }

  void _applyDraftValues(OvertimeDraftModel draft, {bool notifyUi = true}) {
    final normStart = _normalizeDate(draft.startDate);
    var normEnd = _normalizeDate(draft.endDate);
    if (normEnd.isBefore(normStart)) {
      normEnd = normStart;
    }
    if (normEnd.difference(normStart).inDays + 1 > _maxSpanDays) {
      normEnd = normStart.add(const Duration(days: _maxSpanDays - 1));
    }

    final typeVal = _overtimeTypes.contains(draft.overtimeType)
        ? draft.overtimeType
        : _overtimeTypes.first;
    final catVal = _reasonCategories.contains(draft.reasonCategory)
        ? draft.reasonCategory
        : _reasonCategories.first;

    void assign() {
      _draftId = draft.id;
      _startDate = normStart;
      _endDate = normEnd;
      _overtimeType = typeVal;
      _reasonCategory = catVal;
      _reasonController.text = draft.reason;
      _draftPreviousAttachmentName = draft.attachmentName;
      _attachmentPath = null;
      _attachmentBytes = null;
      _attachmentName = null;
      _attachmentSizeBytes = null;
      _cachedSchedulesByIso.clear();
      for (final day in draft.daySchedules) {
        _cachedSchedulesByIso[OvertimeSlotEntry.formatIsoDate(day.date)] =
            day.copy();
      }
    }

    if (notifyUi) {
      setState(assign);
    } else {
      assign();
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _selectedDaySpan => _endDate.difference(_startDate).inDays + 1;

  Future<void> _pickStartDate() async {
    final now = _normalizeDate(DateTime.now());
    final firstAllowed = now.subtract(const Duration(days: 30));
    final lastAllowed = now.add(const Duration(days: 60));

    final effectiveFirst =
        _startDate.isBefore(firstAllowed) ? _startDate : firstAllowed;
    final effectiveLast =
        _startDate.isAfter(lastAllowed) ? _startDate : lastAllowed;

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: effectiveFirst,
      lastDate: effectiveLast,
      helpText: _isRevision
          ? 'PILIH TANGGAL REVISI LEMBUR'
          : 'PILIH TANGGAL MULAI LEMBUR',
    );
    if (picked == null || !mounted) return;

    final normPicked = _normalizeDate(picked);
    bool clamped = false;

    setState(() {
      if (_isRevision && !_isMultiEntryRevision) {
        final prevIso = OvertimeSlotEntry.formatIsoDate(_startDate);
        final prevSchedule = _cachedSchedulesByIso[prevIso];
        _startDate = normPicked;
        _endDate = normPicked;
        if (prevSchedule != null && prevSchedule.slots.isNotEmpty) {
          final prevSlot = prevSchedule.slots.first;
          final spanDays = _normalizeDate(prevSlot.endDate)
              .difference(_normalizeDate(prevSlot.startDate))
              .inDays
              .clamp(0, 1);
          final shiftedEnd = normPicked.add(Duration(days: spanDays));
          _cachedSchedulesByIso.clear();
          _cachedSchedulesByIso[OvertimeSlotEntry.formatIsoDate(normPicked)] =
              OvertimeDaySchedule(
            date: normPicked,
            slots: [
              OvertimeSlotEntry(
                startDate: normPicked,
                endDate: shiftedEnd,
                startTime: prevSlot.startTime,
                endTime: prevSlot.endTime,
              ),
            ],
          );
        }
        return;
      }

      _startDate = normPicked;
      if (_endDate.isBefore(normPicked)) {
        _endDate = normPicked;
      } else if (_endDate.difference(normPicked).inDays + 1 > _maxSpanDays) {
        _endDate = normPicked.add(const Duration(days: _maxSpanDays - 1));
        clamped = true;
      }
    });

    if (clamped) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Rentang tanggal dibatasi maksimal 31 hari per pengajuan.',
            ),
            backgroundColor: AppColors.inkPrimary,
          ),
        );
    }
  }

  Future<void> _pickEndDate() async {
    final now = _normalizeDate(DateTime.now());
    final defaultLast = now.add(const Duration(days: 60));
    final maxBySpan = _startDate.add(const Duration(days: _maxSpanDays - 1));
    final lastAllowed =
        maxBySpan.isBefore(defaultLast) ? maxBySpan : defaultLast;
    final effectiveLast =
        lastAllowed.isBefore(_startDate) ? _startDate : lastAllowed;
    final initial =
        _endDate.isAfter(effectiveLast) ? effectiveLast : _endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDate,
      lastDate: effectiveLast,
      helpText: 'PILIH TANGGAL BERAKHIR LEMBUR',
    );
    if (picked == null || !mounted) return;

    setState(() {
      _endDate = _normalizeDate(picked);
    });
  }

  Future<PickedOvertimeAttachment?> _defaultPickAttachment() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
    );
    if (file == null) return null;

    final knownSize = file.lengthSync() ?? await file.length();
    if (knownSize != null && knownSize > _maxAttachmentBytes) {
      return PickedOvertimeAttachment(
        name: file.name,
        size: knownSize,
        extension: file.extension,
      );
    }

    final bytes = await file.readAsBytes();
    final actualSize = knownSize ?? bytes.length;
    return PickedOvertimeAttachment(
      name: file.name,
      path: kIsWeb ? null : file.path,
      bytes: bytes,
      size: actualSize,
      extension: file.extension,
    );
  }

  Future<void> _pickAttachment() async {
    if (_isPickingFile) return;
    setState(() {
      _isPickingFile = true;
    });

    try {
      final picker = widget.onPickAttachment ?? _defaultPickAttachment;
      final file = await picker();
      if (file == null || !mounted) return;

      final dotIdx = file.name.lastIndexOf('.');
      final extFromName = (dotIdx >= 0 && dotIdx < file.name.length - 1)
          ? file.name.substring(dotIdx + 1)
          : '';
      final ext = (file.extension ?? extFromName).toLowerCase();
      if (ext.isEmpty || !_allowedExtensions.contains(ext)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Format berkas tidak didukung. Gunakan txt, doc, docx, xls, xlsx, pdf, jpg, png, gif, atau jpeg.',
              ),
              backgroundColor: Color(0xFFB91C1C),
            ),
          );
        return;
      }

      if (file.size > _maxAttachmentBytes) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Ukuran berkas melebihi batas maksimal 5 MB.'),
              backgroundColor: Color(0xFFB91C1C),
            ),
          );
        return;
      }

      setState(() {
        _attachmentName = file.name;
        _attachmentBytes = file.bytes;
        _attachmentPath = kIsWeb ? null : file.path;
        _attachmentSizeBytes = file.size;
        _draftPreviousAttachmentName = null;
        _removeExistingAttachment = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Gagal memilih berkas lampiran. Coba lagi.'),
            backgroundColor: Color(0xFFB91C1C),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingFile = false;
        });
      }
    }
  }

  void _removeAttachment() {
    setState(() {
      _attachmentPath = null;
      _attachmentBytes = null;
      _attachmentName = null;
      _attachmentSizeBytes = null;
      if (_isRevision && _existingRemoteAttachmentName != null) {
        _removeExistingAttachment = true;
      }
    });
  }

  void _restoreExistingAttachment() {
    setState(() {
      _attachmentPath = null;
      _attachmentBytes = null;
      _attachmentName = null;
      _attachmentSizeBytes = null;
      _removeExistingAttachment = false;
    });
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openDraftPickerSheet(List<OvertimeDraftModel> drafts) async {
    final auth = ref.read(authStateProvider);
    final rawUserId = auth.user?['id_users'] ?? auth.user?['id'] ?? 0;
    final userId = rawUserId is int
        ? rawUserId
        : int.tryParse(rawUserId.toString()) ?? 0;

    final selected = await showModalBottomSheet<OvertimeDraftModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.72,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 8, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Pilih Draf Lembur Tersimpan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Tutup',
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          constraints: const BoxConstraints(
                            minWidth: AppDimensions.minTouchTarget,
                            minHeight: AppDimensions.minTouchTarget,
                          ),
                          icon: const Icon(
                            LucideIcons.x,
                            size: 20,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.borderSubtle),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: drafts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final draft = drafts[idx];
                        final dateRangeText =
                            '${_dateFormat.format(draft.startDate)} - ${_dateFormat.format(draft.endDate)}';
                        return Material(
                          color: AppColors.surfaceCanvas,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => Navigator.of(sheetCtx).pop(draft),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.borderSubtle,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateRangeText,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.inkPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${draft.overtimeType} • ${draft.configuredDayCount} hari diatur',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF475569),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (draft.reason.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            draft.reason,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (userId > 0) ...[
                                    const SizedBox(width: 4),
                                    IconButton(
                                      tooltip: 'Hapus draf ini',
                                      onPressed: () async {
                                        await ref
                                            .read(overtimeDraftServiceProvider)
                                            .deleteDraft(userId, draft.id);
                                        ref.invalidate(
                                          localOvertimeDraftsProvider,
                                        );
                                        if (sheetCtx.mounted) {
                                          Navigator.of(sheetCtx).pop();
                                        }
                                      },
                                      constraints: const BoxConstraints(
                                        minWidth: AppDimensions.minTouchTarget,
                                        minHeight:
                                            AppDimensions.minTouchTarget,
                                      ),
                                      icon: const Icon(
                                        LucideIcons.trash2,
                                        size: 16,
                                        color: AppColors.dangerText,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      _applyDraftValues(selected);
    }
  }

  List<OvertimeDaySchedule> _buildSchedulesForRange() {
    final result = <OvertimeDaySchedule>[];
    var cursor = _startDate;
    while (!cursor.isAfter(_endDate)) {
      final iso = OvertimeSlotEntry.formatIsoDate(cursor);
      final cached = _cachedSchedulesByIso[iso];
      if (cached != null) {
        result.add(cached.copy());
      } else {
        result.add(OvertimeDaySchedule(date: cursor));
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  Future<void> _goToDetailReview() async {
    if (!_hasTriedSubmit) {
      setState(() {
        _hasTriedSubmit = true;
      });
    }
    if (!_formKey.currentState!.validate()) return;

    final auth = ref.read(authStateProvider);
    final existingName = widget.existingRequest?.employee_name?.trim();
    final existingPos = widget.existingRequest?.employee_position?.trim();
    final empName =
        (existingName != null && existingName.isNotEmpty) ? existingName : auth.userName;
    final empPosition = (existingPos != null && existingPos.isNotEmpty)
        ? existingPos
        : (auth.jobPositionName ?? auth.departmentName);
    final initialSchedules = _buildSchedulesForRange();
    final hasNewAttachment = (_attachmentBytes != null && _attachmentBytes!.isNotEmpty) ||
        (_attachmentPath != null && _attachmentPath!.isNotEmpty);
    final activeExistingRemote =
        _isRevision && !hasNewAttachment && !_removeExistingAttachment && _existingRemoteAttachmentName != null;

    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => OvertimeDetailReviewScreen(
          employeeName: empName,
          employeePosition: empPosition,
          startDate: _startDate,
          endDate: _endDate,
          overtimeType: _overtimeType,
          reasonCategory: _reasonCategory,
          reason: _reasonController.text.trim(),
          attachmentPath: _attachmentPath,
          attachmentBytes: _attachmentBytes,
          attachmentName: _attachmentName ??
              (activeExistingRemote
                  ? _existingRemoteAttachmentName
                  : (_isRevision ? null : _draftPreviousAttachmentName)),
          draftId: _draftId,
          revisingRequestId: widget.existingRequest?.id_overtime_requests,
          allowMultiEntryRevision: _isMultiEntryRevision,
          removeAttachment: _isRevision && _removeExistingAttachment && !hasNewAttachment,
          hasExistingRemoteAttachment: activeExistingRemote,
          initialSchedules: initialSchedules,
          onSchedulesChanged: (updated) {
            for (final d in updated) {
              _cachedSchedulesByIso[OvertimeSlotEntry.formatIsoDate(d.date)] =
                  d.copy();
            }
          },
        ),
      ),
    );

    if (!mounted) return;
    if (result == true || result == 'draft_saved') {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final draftsAsync = ref.watch(localOvertimeDraftsProvider);
    final drafts = draftsAsync.valueOrNull ?? [];
    final showDraftBanner = !_isRevision &&
        widget.initialDraft == null &&
        _draftId == null &&
        drafts.isNotEmpty;
    final existingName = widget.existingRequest?.employee_name?.trim();
    final displayEmployeeName =
        (existingName != null && existingName.isNotEmpty) ? existingName : auth.userName;
    final overtimeTypeOptions = _overtimeTypes.contains(_overtimeType)
        ? _overtimeTypes
        : [..._overtimeTypes, _overtimeType];
    final reasonCategoryOptions = _reasonCategories.contains(_reasonCategory)
        ? _reasonCategories
        : [..._reasonCategories, _reasonCategory];
    final activeAttachmentName = _attachmentName ??
        (!_removeExistingAttachment ? _existingRemoteAttachmentName : null);
    final isShowingExistingRemote = _attachmentName == null &&
        !_removeExistingAttachment &&
        _existingRemoteAttachmentName != null;
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    final screenWidth = MediaQuery.sizeOf(context).width;

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
              key: const Key('overtime_form_back_btn'),
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
                _isRevision ? 'Revisi Lembur' : 'Form Lembur',
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
              final stackDates = effWidth < 280;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 28),
                child: KeyedSubtree(
                  key: ValueKey(
                    _draftId ??
                        (widget.existingRequest != null
                            ? 'revise_${widget.existingRequest!.id_overtime_requests}'
                            : 'new_form'),
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _hasTriedSubmit
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showDraftBanner) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.corporateChipBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.corporateChipBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.fileText,
                                size: 18,
                                color: AppColors.actionAccent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Ada ${drafts.length} draf lembur tersimpan',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                              ),
                              TextButton(
                                key: const Key('overtime_open_drafts_btn'),
                                onPressed: () => _openDraftPickerSheet(drafts),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.actionAccent,
                                  minimumSize: const Size(0, 44),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                                child: const Text(
                                  'Buka Draf',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const _FieldLabel(text: 'Permintaan Untuk'),
                      const SizedBox(height: 6),
                      InputDecorator(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surfaceCanvas,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.borderNeutral,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.borderNeutral,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayEmployeeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              LucideIcons.user,
                              size: 18,
                              color: Color(0xFF475569),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isRevision && !_isMultiEntryRevision) ...[
                        _DatePickerBox(
                          fieldKey: const Key('overtime_start_date_btn'),
                          label: 'Tanggal Lembur',
                          valueText: _dateFormat.format(_startDate),
                          onTap: _pickStartDate,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Revisi berlaku untuk 1 jadwal (jam lintas hari diatur di rincian).',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ] else ...[
                        _buildDatePair(stack: stackDates),
                        const SizedBox(height: 6),
                        Text(
                          'Rentang dipilih: $_selectedDaySpan hari (maks. $_maxSpanDays hari)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const _FieldLabel(text: 'Tipe Lembur'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        key: const Key('overtime_type_dropdown'),
                        initialValue: _overtimeType,
                        isExpanded: true,
                        icon: const Icon(
                          LucideIcons.chevronDown,
                          size: 18,
                          color: Color(0xFF475569),
                        ),
                        decoration: _dropdownDecoration(),
                        items: overtimeTypeOptions
                            .map(
                              (opt) => DropdownMenuItem<String>(
                                value: opt,
                                child: Text(
                                  opt,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _overtimeType = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel(text: 'Alasan Lembur'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        key: const Key('overtime_reason_category_dropdown'),
                        initialValue: _reasonCategory,
                        isExpanded: true,
                        icon: const Icon(
                          LucideIcons.chevronDown,
                          size: 18,
                          color: Color(0xFF475569),
                        ),
                        decoration: _dropdownDecoration(),
                        items: reasonCategoryOptions
                            .map(
                              (opt) => DropdownMenuItem<String>(
                                value: opt,
                                child: Text(
                                  opt,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _reasonCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel(text: 'Keterangan'),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const Key('overtime_reason_input'),
                        controller: _reasonController,
                        maxLines: 3,
                        maxLength: 1000,
                        decoration: InputDecoration(
                          hintText: 'Tuliskan rincian pekerjaan lembur...',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF475569),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.borderNeutral,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.borderNeutral,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.actionAccent,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Keterangan wajib diisi.';
                          }
                          if (val.trim().length < 5) {
                            return 'Keterangan minimal 5 karakter.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const _FieldLabel(text: 'Lampiran (Opsional)'),
                      const SizedBox(height: 8),
                      CustomPaint(
                        painter: _DashedRoundedRectPainter(
                          color: AppColors.borderNeutral,
                          strokeWidth: 1.2,
                          radius: 10,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          child: activeAttachmentName != null
                              ? Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.paperclip,
                                      size: 18,
                                      color: AppColors.actionAccent,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            activeAttachmentName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.inkPrimary,
                                            ),
                                          ),
                                          if (isShowingExistingRemote) ...[
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Lampiran tersimpan saat ini',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ] else if (_attachmentSizeBytes !=
                                                  null &&
                                              _attachmentSizeBytes! > 0) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatFileSize(
                                                _attachmentSizeBytes,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF475569),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      key: const Key(
                                        'overtime_remove_file_btn',
                                      ),
                                      tooltip: 'Hapus lampiran',
                                      onPressed: _removeAttachment,
                                      constraints: const BoxConstraints(
                                        minWidth: AppDimensions.minTouchTarget,
                                        minHeight:
                                            AppDimensions.minTouchTarget,
                                      ),
                                      icon: const Icon(
                                        LucideIcons.x,
                                        size: 18,
                                        color: AppColors.dangerText,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    OutlinedButton.icon(
                                      key: const Key('overtime_pick_file_btn'),
                                      onPressed: _isPickingFile
                                          ? null
                                          : _pickAttachment,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.actionAccent,
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: AppColors.borderNeutral,
                                        ),
                                        minimumSize: const Size(140, 44),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      icon: _isPickingFile
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              LucideIcons.plus,
                                              size: 16,
                                            ),
                                      label: const Text('Pilih File'),
                                    ),
                                    if (_isRevision &&
                                        _removeExistingAttachment &&
                                        _existingRemoteAttachmentName !=
                                            null) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 6,
                                        children: [
                                          const Text(
                                            'Lampiran sebelumnya akan dihapus saat revisi disimpan.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFB45309),
                                            ),
                                          ),
                                          TextButton(
                                            key: const Key(
                                              'overtime_restore_file_btn',
                                            ),
                                            onPressed:
                                                _restoreExistingAttachment,
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.actionAccent,
                                              minimumSize: const Size(44, 44),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                              ),
                                            ),
                                            child: const Text(
                                              'Batalkan',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else if (_draftPreviousAttachmentName !=
                                            null &&
                                        _draftPreviousAttachmentName!
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Lampiran draf sebelumnya: $_draftPreviousAttachmentName (pilih ulang jika diperlukan)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Berkas yang Didukung: txt, doc, docx, jpg, png, gif, xls, xlsx, pdf, jpeg (maks. 5 MB)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('overtime_next_step_btn'),
                  onPressed: _goToDetailReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.actionAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Lanjut'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderNeutral),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.borderNeutral),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.actionAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildDatePair({required bool stack}) {
    final startField = _DatePickerBox(
      fieldKey: const Key('overtime_start_date_btn'),
      label: 'Tanggal Mulai',
      valueText: _dateFormat.format(_startDate),
      onTap: _pickStartDate,
    );
    final endField = _DatePickerBox(
      fieldKey: const Key('overtime_end_date_btn'),
      label: 'Tanggal Berakhir',
      valueText: _dateFormat.format(_endDate),
      onTap: _pickEndDate,
    );

    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          startField,
          const SizedBox(height: 12),
          endField,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: startField),
        const SizedBox(width: 12),
        Expanded(child: endField),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.inkPrimary,
      ),
    );
  }
}

class _DatePickerBox extends StatelessWidget {
  final Key? fieldKey;
  final String label;
  final String valueText;
  final VoidCallback onTap;

  const _DatePickerBox({
    this.fieldKey,
    required this.label,
    required this.valueText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: label),
        const SizedBox(height: 6),
        InkWell(
          key: fieldKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: InputDecorator(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderNeutral),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderNeutral),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      valueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkPrimary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.calendar,
                    size: 16,
                    color: Color(0xFF475569),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;

  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}
