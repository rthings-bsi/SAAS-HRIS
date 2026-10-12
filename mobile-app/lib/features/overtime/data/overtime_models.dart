// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum OvertimeStatus {
  pending,
  approved,
  rejected;

  static OvertimeStatus fromString(String? status) {
    switch (status?.toLowerCase().trim()) {
      case 'approved':
      case 'disetujui':
        return OvertimeStatus.approved;
      case 'rejected':
      case 'ditolak':
        return OvertimeStatus.rejected;
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
    }
  }

  Color get textColor {
    switch (this) {
      case OvertimeStatus.pending:
        return AppColors.warningText;
      case OvertimeStatus.approved:
        return AppColors.successText;
      case OvertimeStatus.rejected:
        return AppColors.dangerText;
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
    }
  }
}

class OvertimeRequestModel {
  final int id_overtime_requests;
  final int? id_employees;
  final String date;
  final String start_time;
  final String end_time;
  final double duration_hours;
  final String reason;
  final OvertimeStatus status;
  final String? rejected_reason;
  final String? approver_name;
  final String? created_at;

  const OvertimeRequestModel({
    required this.id_overtime_requests,
    this.id_employees,
    required this.date,
    required this.start_time,
    required this.end_time,
    required this.duration_hours,
    required this.reason,
    required this.status,
    this.rejected_reason,
    this.approver_name,
    this.created_at,
  });

  String get formattedDuration {
    if (duration_hours % 1 == 0) {
      return '${duration_hours.toInt()} jam';
    }
    return '${duration_hours.toStringAsFixed(1)} jam';
  }

  factory OvertimeRequestModel.fromMap(Map<String, dynamic> map) {
    final rawId = map['id_overtime_requests'] ?? map['id'] ?? 0;
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    final rawEmpId = map['id_employees'];
    final int? empId = rawEmpId != null
        ? (rawEmpId is int ? rawEmpId : int.tryParse(rawEmpId.toString()))
        : null;

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

    return OvertimeRequestModel(
      id_overtime_requests: id,
      id_employees: empId,
      date: map['date']?.toString() ?? '',
      start_time: map['start_time']?.toString() ?? '',
      end_time: map['end_time']?.toString() ?? '',
      duration_hours: duration,
      reason: map['reason']?.toString() ?? '',
      status: status,
      rejected_reason: map['rejected_reason']?.toString(),
      approver_name: approverName,
      created_at: map['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_overtime_requests': id_overtime_requests,
      'id_employees': id_employees,
      'date': date,
      'start_time': start_time,
      'end_time': end_time,
      'duration_hours': duration_hours,
      'reason': reason,
      'status': status.name,
      'rejected_reason': rejected_reason,
      'created_at': created_at,
    };
  }
}
