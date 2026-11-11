import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../attendance/data/attendance_models.dart';
import '../data/overtime_models.dart';

class OvertimeDayScheduleSheet extends StatefulWidget {
  final String employeeName;
  final String? employeePosition;
  final OvertimeDaySchedule daySchedule;
  final String? shiftName;
  final String? shiftRange;
  final AttendanceRecord? actualAttendance;
  final bool allowMultipleSlots;
  final bool allowReset;

  const OvertimeDayScheduleSheet({
    super.key,
    required this.employeeName,
    this.employeePosition,
    required this.daySchedule,
    this.shiftName,
    this.shiftRange,
    this.actualAttendance,
    this.allowMultipleSlots = true,
    this.allowReset = true,
  });

  @override
  State<OvertimeDayScheduleSheet> createState() =>
      _OvertimeDayScheduleSheetState();
}

class _OvertimeDayScheduleSheetState extends State<OvertimeDayScheduleSheet> {
  static const int _maxSlotsPerDay = 5;

  late List<OvertimeSlotEntry> _slots;
  String? _validationError;

  final DateFormat _dateTitleFormat = DateFormat('d MMM yyyy', 'id_ID');
  final DateFormat _fieldDateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  final DateFormat _shortDayFormat = DateFormat('d MMM', 'id_ID');

  @override
  void initState() {
    super.initState();
    _slots = widget.daySchedule.slots.map((s) => s.copy()).toList();
    if (_slots.isEmpty) {
      _slots = [OvertimeSlotEntry.empty(widget.daySchedule.date)];
    }
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

  TimeOfDay _defaultStartSuggestion() {
    final range = widget.shiftRange;
    if (range != null && range.contains('-')) {
      final cleaned = range.replaceAll('[', '').replaceAll(']', '');
      final parts = cleaned.split('-');
      if (parts.length == 2) {
        final parsed = OvertimeSlotEntry.parseTime(parts[1].trim());
        if (parsed != null) return parsed;
      }
    }
    return const TimeOfDay(hour: 17, minute: 0);
  }

  Future<void> _pickStartTime(int index) async {
    final slot = _slots[index];
    final initial = slot.startTime ?? _defaultStartSuggestion();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'PILIH JAM MULAI LEMBUR',
      cancelText: 'Batal',
      confirmText: 'OK',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        slot.startTime = picked;
        _validationError = null;
      });
    }
  }

  Future<void> _pickEndTime(int index) async {
    final slot = _slots[index];
    final TimeOfDay initial;
    if (slot.endTime != null) {
      initial = slot.endTime!;
    } else if (slot.startTime != null) {
      final totalMins = (slot.startTime!.hour * 60 + slot.startTime!.minute) + 120;
      initial = TimeOfDay(
        hour: (totalMins ~/ 60) % 24,
        minute: totalMins % 60,
      );
    } else {
      final startSug = _defaultStartSuggestion();
      initial = TimeOfDay(
        hour: (startSug.hour + 2) % 24,
        minute: startSug.minute,
      );
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: 'PILIH JAM BERAKHIR LEMBUR',
      cancelText: 'Batal',
      confirmText: 'OK',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        slot.endTime = picked;
        _validationError = null;
      });
    }
  }

  Future<void> _pickEndDate(int index) async {
    final slot = _slots[index];
    final baseDay = DateTime(
      slot.startDate.year,
      slot.startDate.month,
      slot.startDate.day,
    );
    final maxDay = baseDay.add(const Duration(days: 1));
    final initial = slot.endDate.isBefore(baseDay)
        ? baseDay
        : (slot.endDate.isAfter(maxDay) ? maxDay : slot.endDate);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: baseDay,
      lastDate: maxDay,
      helpText: 'PILIH TANGGAL BERAKHIR LEMBUR',
    );
    if (picked != null && mounted) {
      setState(() {
        slot.endDate = DateTime(picked.year, picked.month, picked.day);
        _validationError = null;
      });
    }
  }

  void _addSlot() {
    if (_slots.length >= _maxSlotsPerDay) {
      setState(() {
        _validationError =
            'Maksimal $_maxSlotsPerDay sesi lembur dalam satu hari.';
      });
      return;
    }
    setState(() {
      _slots.add(OvertimeSlotEntry.empty(widget.daySchedule.date));
      _validationError = null;
    });
  }

  void _removeSlot(int index) {
    if (_slots.length <= 1) return;
    setState(() {
      _slots.removeAt(index);
      _validationError = null;
    });
  }

  String _formatHoursLabel(double hours) {
    final rounded = (hours * 10).roundToDouble() / 10;
    if ((rounded - hours).abs() < 0.01) {
      return '${rounded.toStringAsFixed(1)} jam';
    }
    return '${hours.toStringAsFixed(2)} jam';
  }

  void _resetSingleSlot() {
    setState(() {
      _slots = [OvertimeSlotEntry.empty(widget.daySchedule.date)];
      _validationError = null;
    });
  }

  void _handleSave() {
    if (widget.daySchedule.isConfigured &&
        _slots.length == 1 &&
        _slots[0].startTime == null &&
        _slots[0].endTime == null) {
      Navigator.of(context).pop([OvertimeSlotEntry.empty(widget.daySchedule.date)]);
      return;
    }

    for (int i = 0; i < _slots.length; i++) {
      final slot = _slots[i];
      if (!slot.isComplete) {
        setState(() {
          _validationError =
              'Lengkapi jam mulai dan jam berakhir pada Overtime ${i + 1}.';
        });
        return;
      }

      final sDt = slot.startDateTime!;
      final eDt = slot.endDateTime!;
      final mins = eDt.difference(sDt).inMinutes;
      if (mins <= 0) {
        setState(() {
          _validationError =
              'Lembur berakhir harus lebih akhir dari mulai lembur pada Overtime ${i + 1}.';
        });
        return;
      }
      if (mins > 1440) {
        setState(() {
          _validationError =
              'Durasi satu sesi Overtime ${i + 1} tidak boleh melebihi 24 jam.';
        });
        return;
      }
    }

    for (int i = 0; i < _slots.length; i++) {
      final aStart = _slots[i].startDateTime!;
      final aEnd = _slots[i].endDateTime!;
      for (int j = i + 1; j < _slots.length; j++) {
        final bStart = _slots[j].startDateTime!;
        final bEnd = _slots[j].endDateTime!;
        if (aStart.isBefore(bEnd) && aEnd.isAfter(bStart)) {
          setState(() {
            _validationError =
                'Overtime ${i + 1} dan Overtime ${j + 1} memiliki jam yang tumpang tindih.';
          });
          return;
        }
      }
    }

    Navigator.of(context).pop(_slots.map((s) => s.copy()).toList());
  }

  @override
  Widget build(BuildContext context) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth < 310 ? 12.0 : 20.0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.92;
    final shortDate = _shortDayFormat.format(widget.daySchedule.date);

    final actualInText =
        widget.actualAttendance != null && widget.actualAttendance!.hasClockedIn
            ? '${widget.actualAttendance!.clockIn} | $shortDate'
            : '--:--';
    final actualOutText = widget.actualAttendance != null &&
            widget.actualAttendance!.hasClockedOut
        ? '${widget.actualAttendance!.clockOut} | $shortDate'
        : '--:--';

    final shiftDisplayName = (widget.shiftName != null &&
            widget.shiftName!.trim().isNotEmpty)
        ? widget.shiftName!.trim()
        : '-';

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 640, maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(bottom: bottomInset),
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
                  padding: const EdgeInsets.fromLTRB(48, 8, 8, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Lembur',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tutup',
                        onPressed: () => Navigator.of(context).pop(),
                        constraints: const BoxConstraints(
                          minWidth: AppDimensions.minTouchTarget,
                          minHeight: AppDimensions.minTouchTarget,
                        ),
                        icon: const Icon(
                          LucideIcons.x,
                          size: 20,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.hairline,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 16),
                    child: LayoutBuilder(
                      builder: (context, bodyConstraints) {
                        final effWidth = bodyConstraints.maxWidth / textScale;
                        final stackPairs = effWidth < 260;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Permintaan Oleh',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.inkMuted,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          widget.employeePosition!
                                              .trim()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.employeePosition!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _buildTwoColumnPair(
                              stack: stackPairs,
                              left: _MetaColumn(
                                label: 'Tanggal',
                                value: _dateTitleFormat
                                    .format(widget.daySchedule.date),
                              ),
                              right: _MetaColumn(
                                label: 'Shift',
                                value: widget.shiftRange != null
                                    ? '$shiftDisplayName\n${widget.shiftRange}'
                                    : shiftDisplayName,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const _SectionHeaderDivider(
                              label: 'KEHADIRAN AKTUAL',
                            ),
                            const SizedBox(height: 12),
                            _buildTwoColumnPair(
                              stack: stackPairs,
                              left: _MetaColumn(
                                label: 'Jam Masuk',
                                value: actualInText,
                                mutedValue: widget.actualAttendance == null ||
                                    !widget.actualAttendance!.hasClockedIn,
                              ),
                              right: _MetaColumn(
                                label: 'Jam Keluar',
                                value: actualOutText,
                                mutedValue: widget.actualAttendance == null ||
                                    !widget.actualAttendance!.hasClockedOut,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const _SectionHeaderDivider(label: 'MINTA LEMBUR'),
                            const SizedBox(height: 12),
                            if (_validationError != null) ...[
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
                                        _validationError!,
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
                            for (int i = 0; i < _slots.length; i++) ...[
                              if (i > 0) const SizedBox(height: 12),
                              _buildSlotBox(
                                index: i,
                                slot: _slots[i],
                                stackFields: stackPairs,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.hairline,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 16),
                  child: LayoutBuilder(
                    builder: (context, footerConstraints) {
                      final effWidth = footerConstraints.maxWidth / textScale;
                      final addMoreBtn = OutlinedButton(
                        key: const Key('overtime_add_slot_btn'),
                        onPressed: _addSlot,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.actionAccent,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.borderStrong),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: const Text('Tambah Lagi'),
                      );

                      final updateBtn = ElevatedButton(
                        key: const Key('overtime_update_day_btn'),
                        onPressed: _handleSave,
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
                        child: const Text('Perbarui'),
                      );

                      if (!widget.allowMultipleSlots) {
                        return SizedBox(
                          width: double.infinity,
                          child: updateBtn,
                        );
                      }

                      if (effWidth < 250) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            addMoreBtn,
                            const SizedBox(height: 10),
                            updateBtn,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: addMoreBtn),
                          const SizedBox(width: 12),
                          Expanded(child: updateBtn),
                        ],
                      );
                    },
                  ),
                ),
              ],
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

  Widget _buildSlotBox({
    required int index,
    required OvertimeSlotEntry slot,
    required bool stackFields,
  }) {
    final startDateLabel = _fieldDateFormat.format(slot.startDate);
    final endDateLabel = _fieldDateFormat.format(slot.endDate);
    final startTimeText = slot.startTime != null
        ? OvertimeSlotEntry.formatTime(slot.startTime)
        : 'HH:mm';
    final endTimeText = slot.endTime != null
        ? OvertimeSlotEntry.formatTime(slot.endTime)
        : 'HH:mm';

    final startDateField = _LabeledPickerDecorator(
      label: 'Tanggal Mulai',
      valueText: startDateLabel,
      isPlaceholder: false,
      isReadOnly: true,
      icon: LucideIcons.calendar,
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tanggal mulai mengikuti kartu hari yang dipilih.',
            ),
            backgroundColor: AppColors.inkPrimary,
          ),
        );
      },
    );

    final startTimeField = _LabeledPickerDecorator(
      key: Key('overtime_slot_${index}_start_time'),
      label: 'Mulai Lembur',
      valueText: startTimeText,
      isPlaceholder: slot.startTime == null,
      icon: LucideIcons.clock,
      onTap: () => _pickStartTime(index),
    );

    final endDateField = _LabeledPickerDecorator(
      key: Key('overtime_slot_${index}_end_date'),
      label: 'Tanggal Berakhir',
      valueText: endDateLabel,
      isPlaceholder: false,
      icon: LucideIcons.calendar,
      onTap: () => _pickEndDate(index),
    );

    final endTimeField = _LabeledPickerDecorator(
      key: Key('overtime_slot_${index}_end_time'),
      label: 'Lembur Berakhir',
      valueText: endTimeText,
      isPlaceholder: slot.endTime == null,
      icon: LucideIcons.clock,
      onTap: () => _pickEndTime(index),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Overtime ${index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                  ),
                ),
              ),
              if (slot.isValid) ...[
                Text(
                  _formatHoursLabel(slot.durationHours),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.actionAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              if (_slots.length > 1) ...[
                const SizedBox(width: 4),
                IconButton(
                  key: Key('overtime_slot_remove_$index'),
                  tooltip: 'Hapus Overtime ${index + 1}',
                  onPressed: () => _removeSlot(index),
                  constraints: const BoxConstraints(
                    minWidth: AppDimensions.minTouchTarget,
                    minHeight: AppDimensions.minTouchTarget,
                  ),
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: AppColors.dangerText,
                  ),
                ),
              ] else if (widget.allowReset &&
                  widget.daySchedule.isConfigured &&
                  (slot.startTime != null || slot.endTime != null)) ...[
                const SizedBox(width: 4),
                IconButton(
                  key: const Key('overtime_slot_reset_btn'),
                  tooltip: 'Kosongkan jam hari ini',
                  onPressed: _resetSingleSlot,
                  constraints: const BoxConstraints(
                    minWidth: AppDimensions.minTouchTarget,
                    minHeight: AppDimensions.minTouchTarget,
                  ),
                  icon: const Icon(
                    LucideIcons.rotateCcw,
                    size: 16,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          _buildTwoColumnPair(
            stack: stackFields,
            left: startDateField,
            right: startTimeField,
          ),
          const SizedBox(height: 12),
          _buildTwoColumnPair(
            stack: stackFields,
            left: endDateField,
            right: endTimeField,
          ),
        ],
      ),
    );
  }
}

class _MetaColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool mutedValue;

  const _MetaColumn({
    required this.label,
    required this.value,
    this.mutedValue = false,
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
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: mutedValue ? FontWeight.w500 : FontWeight.w600,
            color: mutedValue
                ? const Color(0xFF475569)
                : AppColors.inkPrimary,
            height: 1.35,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderDivider extends StatelessWidget {
  final String label;

  const _SectionHeaderDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
              letterSpacing: 0.7,
            ),
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
      ],
    );
  }
}

class _LabeledPickerDecorator extends StatelessWidget {
  final String label;
  final String valueText;
  final bool isPlaceholder;
  final bool isReadOnly;
  final IconData icon;
  final VoidCallback onTap;

  const _LabeledPickerDecorator({
    super.key,
    required this.label,
    required this.valueText,
    required this.isPlaceholder,
    this.isReadOnly = false,
    required this.icon,
    required this.onTap,
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
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: InputDecorator(
              decoration: InputDecoration(
                filled: true,
                fillColor:
                    isReadOnly ? AppColors.surfaceCanvas : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderStrong),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderStrong),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      valueText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isPlaceholder
                            ? const Color(0xFF475569)
                            : AppColors.inkPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    icon,
                    size: 16,
                    color: const Color(0xFF475569),
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
