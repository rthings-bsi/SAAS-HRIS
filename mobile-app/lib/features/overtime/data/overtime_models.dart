// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum OvertimeStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static OvertimeStatus fromString(String? status) {
    switch (status?.toLowerCase().trim()) {
      case 'approved':
      case 'disetujui':
        return OvertimeStatus.approved;
      case 'rejected':
      case 'ditolak':
        return OvertimeStatus.rejected;
      case 'cancelled':
      case 'dibatalkan':
        return OvertimeStatus.cancelled;
      case 'pending':
      case 'menunggu':
      default:
        return OvertimeStatus.pending;
    }
  }
}

extension OvertimeStatusX on OvertimeStatus {
  String get label {
    switch (this) {
      case OvertimeStatus.pending:
        return 'Menunggu';
      case OvertimeStatus.approved:
        return 'Disetujui';
      case OvertimeStatus.rejected:
        return 'Ditolak';
      case OvertimeStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  Color get textColor {
    switch (this) {
      case OvertimeStatus.pending:
        return const Color(0xFFB45309);
      case OvertimeStatus.approved:
        return const Color(0xFF047857);
      case OvertimeStatus.rejected:
        return const Color(0xFFB91C1C);
      case OvertimeStatus.cancelled:
        return const Color(0xFF475569);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case OvertimeStatus.pending:
        return AppColors.warningBg;
      case OvertimeStatus.approved:
        return AppColors.successBg;
      case OvertimeStatus.rejected:
        return AppColors.dangerBg;
      case OvertimeStatus.cancelled:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get borderColor {
    switch (this) {
      case OvertimeStatus.pending:
        return AppColors.warningBorder;
      case OvertimeStatus.approved:
        return AppColors.successBorder;
      case OvertimeStatus.rejected:
        return AppColors.dangerBorder;
      case OvertimeStatus.cancelled:
        return const Color(0xFFCBD5E1);
    }
  }
}

class OvertimeRequestModel {
  final int id_overtime_requests;
  final String? request_number;
  final int? id_employees;
  final String? employee_name;
  final String? employee_nik;
  final String? employee_department;
  final String? employee_position;
  final String? shift_name;
  final String? shift_start_time;
  final String? shift_end_time;
  final String? actual_clock_in;
  final String? actual_clock_out;
  final String date;
  final String? end_date;
  final String start_time;
  final String end_time;
  final double duration_hours;
  final String? overtime_type;
  final String? reason_category;
  final String reason;
  final String? attachment_url;
  final OvertimeStatus status;
  final String? rejected_reason;
  final String? approver_name;
  final String? created_at;

  const OvertimeRequestModel({
    required this.id_overtime_requests,
    this.request_number,
    this.id_employees,
    this.employee_name,
    this.employee_nik,
    this.employee_department,
    this.employee_position,
    this.shift_name,
    this.shift_start_time,
    this.shift_end_time,
    this.actual_clock_in,
    this.actual_clock_out,
    required this.date,
    this.end_date,
    required this.start_time,
    required this.end_time,
    required this.duration_hours,
    this.overtime_type,
    this.reason_category,
    required this.reason,
    this.attachment_url,
    required this.status,
    this.rejected_reason,
    this.approver_name,
    this.created_at,
  });

  bool get isCrossDay =>
      end_date != null && end_date!.isNotEmpty && end_date != date;

  String get formattedDuration {
    if (duration_hours % 1 == 0) {
      return '${duration_hours.toInt()} jam';
    }
    return '${duration_hours.toStringAsFixed(1)} jam';
  }

  String get formattedRequestedDurationLong {
    final safeHours =
        duration_hours.isFinite && duration_hours > 0 ? duration_hours : 0.0;
    final totalMinutes = (safeHours * 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '$hours jam $minutes menit';
  }

  String get displayRequestNumber {
    final raw = request_number?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final parsedCreated = DateTime.tryParse(created_at?.trim() ?? '');
    final parsedDate = DateTime.tryParse(date.trim());
    final refDate = parsedCreated?.toLocal() ?? parsedDate ?? DateTime.now();
    final ym =
        '${refDate.year.toString().padLeft(4, '0')}${refDate.month.toString().padLeft(2, '0')}';
    final seq = (id_overtime_requests < 0 ? 0 : id_overtime_requests)
        .toString()
        .padLeft(6, '0');
    return 'OVR-$ym-$seq';
  }

  static String? trimHm(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (trimmed.length >= 5 && trimmed.contains(':')) {
      return trimmed.substring(0, 5);
    }
    return trimmed;
  }

  String? get formattedShiftRange {
    final start = trimHm(shift_start_time);
    final end = trimHm(shift_end_time);
    if (start == null || end == null || start.isEmpty || end.isEmpty) {
      return null;
    }
    return '[$start - $end]';
  }

  factory OvertimeRequestModel.fromMap(Map<String, dynamic> map) {
    final rawId = map['id_overtime_requests'] ?? map['id'] ?? 0;
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    final rawEmpId = map['id_employees'];
    final int? empId = rawEmpId != null
        ? (rawEmpId is int ? rawEmpId : int.tryParse(rawEmpId.toString()))
        : null;

    String? employeeName;
    String? employeeNik;
    String? employeeDept;
    String? employeePos;
    String? shiftName;
    String? shiftStartTime;
    String? shiftEndTime;
    final empMap = map['employee'];
    if (empMap is Map) {
      employeeNik = empMap['nik']?.toString();
      employeeDept = empMap['department_name']?.toString();
      employeePos = empMap['job_position_name']?.toString();
      final userMap = empMap['user'];
      if (userMap is Map) {
        employeeName = userMap['name']?.toString();
      }
      employeeName ??=
          empMap['full_name']?.toString() ?? empMap['name']?.toString();

      final shiftMap = empMap['shift'];
      if (shiftMap is Map) {
        shiftName = shiftMap['name']?.toString();
        shiftStartTime = shiftMap['start_time']?.toString();
        shiftEndTime = shiftMap['end_time']?.toString();
      }
    }
    employeeName ??= map['employee_name']?.toString();
    shiftName ??= map['shift_name']?.toString();
    shiftStartTime ??= map['shift_start_time']?.toString();
    shiftEndTime ??= map['shift_end_time']?.toString();

    final rawDuration = map['duration_hours'] ?? map['duration'] ?? 0;
    final double duration = rawDuration is num
        ? rawDuration.toDouble()
        : double.tryParse(rawDuration.toString()) ?? 0.0;

    final statusStr = map['status'] as String?;
    final status = OvertimeStatus.fromString(statusStr);

    String? approverName;
    if (map['approver'] is Map) {
      approverName = (map['approver'] as Map)['name']?.toString();
    }
    approverName ??= map['approver_name']?.toString();

    return OvertimeRequestModel(
      id_overtime_requests: id,
      request_number: map['request_number']?.toString(),
      id_employees: empId,
      employee_name: employeeName,
      employee_nik: employeeNik,
      employee_department: employeeDept,
      employee_position: employeePos,
      shift_name: shiftName,
      shift_start_time: shiftStartTime,
      shift_end_time: shiftEndTime,
      actual_clock_in: map['actual_clock_in']?.toString(),
      actual_clock_out: map['actual_clock_out']?.toString(),
      date: map['date']?.toString() ?? '',
      end_date: map['end_date']?.toString(),
      start_time: map['start_time']?.toString() ?? '',
      end_time: map['end_time']?.toString() ?? '',
      duration_hours: duration,
      overtime_type: map['overtime_type']?.toString(),
      reason_category: map['reason_category']?.toString(),
      reason: map['reason']?.toString() ?? '',
      attachment_url: map['attachment_url']?.toString(),
      status: status,
      rejected_reason: map['rejected_reason']?.toString(),
      approver_name: approverName,
      created_at: map['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_overtime_requests': id_overtime_requests,
      'request_number': request_number,
      'id_employees': id_employees,
      'employee_name': employee_name,
      'employee_nik': employee_nik,
      'employee_department': employee_department,
      'employee_position': employee_position,
      'shift_name': shift_name,
      'shift_start_time': shift_start_time,
      'shift_end_time': shift_end_time,
      'actual_clock_in': actual_clock_in,
      'actual_clock_out': actual_clock_out,
      'date': date,
      'end_date': end_date,
      'start_time': start_time,
      'end_time': end_time,
      'duration_hours': duration_hours,
      'overtime_type': overtime_type,
      'reason_category': reason_category,
      'reason': reason,
      'attachment_url': attachment_url,
      'status': status.name,
      'rejected_reason': rejected_reason,
      'created_at': created_at,
    };
  }
}

class OvertimeSlotEntry {
  DateTime startDate;
  DateTime endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  OvertimeSlotEntry({
    required this.startDate,
    required this.endDate,
    this.startTime,
    this.endTime,
  });

  factory OvertimeSlotEntry.empty(DateTime date) {
    final norm = DateTime(date.year, date.month, date.day);
    return OvertimeSlotEntry(startDate: norm, endDate: norm);
  }

  OvertimeSlotEntry copy() => OvertimeSlotEntry(
        startDate: startDate,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
      );

  bool get isComplete => startTime != null && endTime != null;

  DateTime? get startDateTime {
    if (startTime == null) return null;
    return DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      startTime!.hour,
      startTime!.minute,
    );
  }

  DateTime? get endDateTime {
    if (endTime == null) return null;
    return DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      endTime!.hour,
      endTime!.minute,
    );
  }

  double get durationHours {
    final s = startDateTime;
    final e = endDateTime;
    if (s == null || e == null) return 0.0;
    final minutes = e.difference(s).inMinutes;
    if (minutes <= 0 || minutes > 1440) return 0.0;
    return (minutes / 60.0);
  }

  bool get isValid => isComplete && durationHours > 0;

  static String formatTime(TimeOfDay? t) {
    if (t == null) return '--:--';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay? parseTime(String? value) {
    if (value == null || !value.contains(':')) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return TimeOfDay(hour: h, minute: m);
  }

  Map<String, dynamic> toDraftJson() => {
        'start_date': _isoDate(startDate),
        'end_date': _isoDate(endDate),
        'start_time': startTime != null ? formatTime(startTime) : null,
        'end_time': endTime != null ? formatTime(endTime) : null,
      };

  factory OvertimeSlotEntry.fromDraftJson(
    Map<String, dynamic> json,
    DateTime fallbackDate,
  ) {
    final sDate =
        DateTime.tryParse(json['start_date']?.toString() ?? '') ?? fallbackDate;
    final eDate = DateTime.tryParse(json['end_date']?.toString() ?? '') ?? sDate;
    return OvertimeSlotEntry(
      startDate: DateTime(sDate.year, sDate.month, sDate.day),
      endDate: DateTime(eDate.year, eDate.month, eDate.day),
      startTime: parseTime(json['start_time']?.toString()),
      endTime: parseTime(json['end_time']?.toString()),
    );
  }

  static String formatIsoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _isoDate(DateTime d) => formatIsoDate(d);
}

class OvertimeDaySchedule {
  final DateTime date;
  List<OvertimeSlotEntry> slots;

  OvertimeDaySchedule({
    required this.date,
    List<OvertimeSlotEntry>? slots,
  }) : slots = slots ?? [OvertimeSlotEntry.empty(date)];

  OvertimeDaySchedule copy() => OvertimeDaySchedule(
        date: date,
        slots: slots.map((s) => s.copy()).toList(),
      );

  List<OvertimeSlotEntry> get validSlots =>
      slots.where((s) => s.isValid).toList();

  bool get isConfigured => validSlots.isNotEmpty;

  double get totalHours =>
      validSlots.fold<double>(0.0, (sum, s) => sum + s.durationHours);

  String get summaryStartText => validSlots.isNotEmpty
      ? OvertimeSlotEntry.formatTime(validSlots.first.startTime)
      : '--:--';

  String get summaryEndText => validSlots.isNotEmpty
      ? OvertimeSlotEntry.formatTime(validSlots.last.endTime)
      : '--:--';

  Map<String, dynamic> toDraftJson() => {
        'date': OvertimeSlotEntry._isoDate(date),
        'slots': slots.map((s) => s.toDraftJson()).toList(),
      };

  factory OvertimeDaySchedule.fromDraftJson(Map<String, dynamic> json) {
    final parsedDate =
        DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now();
    final norm = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    final rawSlots = json['slots'];
    final slots = <OvertimeSlotEntry>[];
    if (rawSlots is List) {
      for (final item in rawSlots) {
        if (item is Map<String, dynamic>) {
          slots.add(OvertimeSlotEntry.fromDraftJson(item, norm));
        } else if (item is Map) {
          slots.add(OvertimeSlotEntry.fromDraftJson(
              Map<String, dynamic>.from(item), norm));
        }
      }
    }
    return OvertimeDaySchedule(
      date: norm,
      slots: slots.isEmpty ? [OvertimeSlotEntry.empty(norm)] : slots,
    );
  }
}

class OvertimeDraftModel {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String overtimeType;
  final String reasonCategory;
  final String reason;
  final List<OvertimeDaySchedule> daySchedules;
  final String? attachmentName;
  final DateTime savedAt;

  const OvertimeDraftModel({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.overtimeType,
    required this.reasonCategory,
    required this.reason,
    required this.daySchedules,
    this.attachmentName,
    required this.savedAt,
  });

  int get configuredDayCount =>
      daySchedules.where((d) => d.isConfigured).length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'start_date': OvertimeSlotEntry._isoDate(startDate),
        'end_date': OvertimeSlotEntry._isoDate(endDate),
        'overtime_type': overtimeType,
        'reason_category': reasonCategory,
        'reason': reason,
        'attachment_name': attachmentName,
        'saved_at': savedAt.toIso8601String(),
        'day_schedules': daySchedules.map((d) => d.toDraftJson()).toList(),
      };

  factory OvertimeDraftModel.fromJson(Map<String, dynamic> json) {
    final sDate =
        DateTime.tryParse(json['start_date']?.toString() ?? '') ?? DateTime.now();
    final eDate = DateTime.tryParse(json['end_date']?.toString() ?? '') ?? sDate;
    final rawDays = json['day_schedules'];
    final days = <OvertimeDaySchedule>[];
    if (rawDays is List) {
      for (final item in rawDays) {
        if (item is Map<String, dynamic>) {
          days.add(OvertimeDaySchedule.fromDraftJson(item));
        } else if (item is Map) {
          days.add(OvertimeDaySchedule.fromDraftJson(
              Map<String, dynamic>.from(item)));
        }
      }
    }
    return OvertimeDraftModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      startDate: DateTime(sDate.year, sDate.month, sDate.day),
      endDate: DateTime(eDate.year, eDate.month, eDate.day),
      overtimeType: json['overtime_type']?.toString() ?? 'Jam Lembur',
      reasonCategory: json['reason_category']?.toString() ?? 'Lembur',
      reason: json['reason']?.toString() ?? '',
      attachmentName: json['attachment_name']?.toString(),
      savedAt: DateTime.tryParse(json['saved_at']?.toString() ?? '') ?? DateTime.now(),
      daySchedules: days,
    );
  }
}
