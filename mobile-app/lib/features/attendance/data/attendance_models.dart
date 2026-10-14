import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

enum AttendanceBadgeStatus {
  belumHadir,
  tepatWaktu,
  terlambat,
  sudahClockOut,
}

extension AttendanceBadgeStatusX on AttendanceBadgeStatus {
  String get label {
    switch (this) {
      case AttendanceBadgeStatus.belumHadir:
        return 'Belum Hadir';
      case AttendanceBadgeStatus.tepatWaktu:
        return 'Hadir Tepat Waktu';
      case AttendanceBadgeStatus.terlambat:
        return 'Terlambat';
      case AttendanceBadgeStatus.sudahClockOut:
        return 'Sudah Clock Out';
    }
  }

  Color get textColor {
    switch (this) {
      case AttendanceBadgeStatus.belumHadir:
        return AppColors.inkMuted;
      case AttendanceBadgeStatus.tepatWaktu:
        return AppColors.successText;
      case AttendanceBadgeStatus.terlambat:
        return AppColors.warningText;
      case AttendanceBadgeStatus.sudahClockOut:
        return AppColors.clockOutText;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case AttendanceBadgeStatus.belumHadir:
        return AppColors.surfaceMuted;
      case AttendanceBadgeStatus.tepatWaktu:
        return AppColors.successBg;
      case AttendanceBadgeStatus.terlambat:
        return AppColors.warningBg;
      case AttendanceBadgeStatus.sudahClockOut:
        return AppColors.clockOutBg;
    }
  }

  Color get borderColor {
    switch (this) {
      case AttendanceBadgeStatus.belumHadir:
        return AppColors.borderNeutral;
      case AttendanceBadgeStatus.tepatWaktu:
        return AppColors.successBorder;
      case AttendanceBadgeStatus.terlambat:
        return AppColors.warningBorder;
      case AttendanceBadgeStatus.sudahClockOut:
        return AppColors.clockOutBorder;
    }
  }
}

class TodayAttendanceData {
  final String date;
  final String shiftName;
  final String startTime;
  final String endTime;
  final int lateToleranceMinutes;
  final String? clockInTime;
  final String? clockOutTime;
  final String? status;
  final int lateDurationMinutes;

  const TodayAttendanceData({
    required this.date,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.lateToleranceMinutes,
    this.clockInTime,
    this.clockOutTime,
    this.status,
    this.lateDurationMinutes = 0,
  });

  bool get hasClockedIn => clockInTime != null && clockInTime!.isNotEmpty;
  bool get hasClockedOut => clockOutTime != null && clockOutTime!.isNotEmpty;
  bool get isLate => status == 'late' || lateDurationMinutes > 0;
  int get lateMinutes => lateDurationMinutes;

  AttendanceBadgeStatus get badgeStatus {
    if (hasClockedOut) {
      return AttendanceBadgeStatus.sudahClockOut;
    }
    if (!hasClockedIn) {
      return AttendanceBadgeStatus.belumHadir;
    }
    if (status == 'late' || lateDurationMinutes > 0) {
      return AttendanceBadgeStatus.terlambat;
    }
    return AttendanceBadgeStatus.tepatWaktu;
  }

  factory TodayAttendanceData.fromMap(Map<String, dynamic> map) {
    final actual = map['data'] is Map<String, dynamic>
        ? map['data'] as Map<String, dynamic>
        : map;
    final shift = actual['shift'] as Map<String, dynamic>?;
    final attendance = actual['attendance'] as Map<String, dynamic>?;

    final shiftName = shift?['name'] as String? ??
        actual['shift_name'] as String? ??
        'Shift Reguler Pagi';

    final startTime = shift?['start_time'] as String? ??
        actual['start_time'] as String? ??
        actual['shift_start'] as String? ??
        '08:00';

    final endTime = shift?['end_time'] as String? ??
        actual['end_time'] as String? ??
        actual['shift_end'] as String? ??
        '17:00';

    final rawTolerance = shift?['late_tolerance_minutes'] ??
        actual['late_tolerance_minutes'] ??
        15;
    final lateTolerance = rawTolerance is int
        ? rawTolerance
        : int.tryParse(rawTolerance.toString()) ?? 15;

    final clockIn = attendance?['clock_in_time'] as String? ??
        attendance?['clock_in'] as String? ??
        actual['clock_in_time'] as String? ??
        actual['clock_in'] as String?;

    final clockOut = attendance?['clock_out_time'] as String? ??
        attendance?['clock_out'] as String? ??
        actual['clock_out_time'] as String? ??
        actual['clock_out'] as String?;

    final status = attendance?['status'] as String? ??
        actual['status'] as String?;

    final rawLateMinutes = attendance?['late_duration_minutes'] ??
        actual['late_duration_minutes'] ??
        0;
    final lateMinutes = rawLateMinutes is int
        ? rawLateMinutes
        : int.tryParse(rawLateMinutes.toString()) ?? 0;

    final date = actual['date'] as String? ??
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return TodayAttendanceData(
      date: date,
      shiftName: shiftName,
      startTime: _formatTime(startTime),
      endTime: _formatTime(endTime),
      lateToleranceMinutes: lateTolerance,
      clockInTime: clockIn != null ? _formatTime(clockIn) : null,
      clockOutTime: clockOut != null ? _formatTime(clockOut) : null,
      status: status,
      lateDurationMinutes: lateMinutes,
    );
  }

  static String _formatTime(String time) {
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
  }
}

class AttendanceRecord {
  final String date;
  final String? clockIn;
  final String? clockOut;
  final String? status;
  final int lateDurationMinutes;

  const AttendanceRecord({
    required this.date,
    this.clockIn,
    this.clockOut,
    this.status,
    this.lateDurationMinutes = 0,
  });

  bool get hasClockedIn => clockIn != null && clockIn!.isNotEmpty;
  bool get hasClockedOut => clockOut != null && clockOut!.isNotEmpty;

  AttendanceBadgeStatus get badgeStatus {
    if (hasClockedOut) {
      return AttendanceBadgeStatus.sudahClockOut;
    }
    if (!hasClockedIn || status == 'absent') {
      return AttendanceBadgeStatus.belumHadir;
    }
    if (status == 'late' || lateDurationMinutes > 0) {
      return AttendanceBadgeStatus.terlambat;
    }
    return AttendanceBadgeStatus.tepatWaktu;
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    final date = map['date'] as String? ?? '';
    final inTime = map['clock_in_time'] as String? ??
        map['clock_in'] as String?;
    final outTime = map['clock_out_time'] as String? ??
        map['clock_out'] as String?;
    final status = map['status'] as String?;
    final rawLate = map['late_duration_minutes'] ?? 0;
    final lateMinutes = rawLate is int
        ? rawLate
        : int.tryParse(rawLate.toString()) ?? 0;

    return AttendanceRecord(
      date: date,
      clockIn: inTime != null ? _formatTime(inTime) : null,
      clockOut: outTime != null ? _formatTime(outTime) : null,
      status: status,
      lateDurationMinutes: lateMinutes,
    );
  }

  static String _formatTime(String time) {
    if (time.length >= 5) {
      return time.substring(0, 5);
    }
    return time;
  }
}
