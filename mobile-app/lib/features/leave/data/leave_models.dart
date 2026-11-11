// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';

enum LeaveStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static LeaveStatus fromString(String? status) {
    switch (status?.toLowerCase().trim()) {
      case 'approved':
      case 'disetujui':
        return LeaveStatus.approved;
      case 'rejected':
      case 'ditolak':
        return LeaveStatus.rejected;
      case 'cancelled':
      case 'dibatalkan':
        return LeaveStatus.cancelled;
      case 'pending':
      case 'menunggu':
      default:
        return LeaveStatus.pending;
    }
  }
}

extension LeaveStatusX on LeaveStatus {
  String get label {
    switch (this) {
      case LeaveStatus.pending:
        return 'Menunggu';
      case LeaveStatus.approved:
        return 'Disetujui';
      case LeaveStatus.rejected:
        return 'Ditolak';
      case LeaveStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  Color get textColor {
    switch (this) {
      case LeaveStatus.pending:
        return const Color(0xFFB45309);
      case LeaveStatus.approved:
        return const Color(0xFF047857);
      case LeaveStatus.rejected:
        return const Color(0xFFB91C1C);
      case LeaveStatus.cancelled:
        return const Color(0xFF475569);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case LeaveStatus.pending:
        return AppColors.warningBg;
      case LeaveStatus.approved:
        return AppColors.successBg;
      case LeaveStatus.rejected:
        return AppColors.dangerBg;
      case LeaveStatus.cancelled:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get borderColor {
    switch (this) {
      case LeaveStatus.pending:
        return AppColors.warningBorder;
      case LeaveStatus.approved:
        return AppColors.successBorder;
      case LeaveStatus.rejected:
        return AppColors.dangerBorder;
      case LeaveStatus.cancelled:
        return const Color(0xFFCBD5E1);
    }
  }
}

class LeaveTypeModel {
  final int id_leave_types;
  final String name;
  final int quota_days;
  final bool is_paid;

  const LeaveTypeModel({
    required this.id_leave_types,
    required this.name,
    required this.quota_days,
    required this.is_paid,
  });

  factory LeaveTypeModel.fromMap(Map<String, dynamic> map) {
    final rawId = map['id_leave_types'] ?? map['id'] ?? 0;
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    final rawQuota = map['quota_days'] ?? map['quota'] ?? 0;
    final quota = rawQuota is int ? rawQuota : int.tryParse(rawQuota.toString()) ?? 0;

    final rawPaid = map['is_paid'];
    final bool paid = rawPaid is bool
        ? rawPaid
        : (rawPaid == 1 || rawPaid == '1' || rawPaid == 'true');

    return LeaveTypeModel(
      id_leave_types: id,
      name: map['name'] as String? ?? 'Cuti',
      quota_days: quota,
      is_paid: paid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_leave_types': id_leave_types,
      'name': name,
      'quota_days': quota_days,
      'is_paid': is_paid,
    };
  }
}

class LeaveBalanceModel {
  final int id_leave_types;
  final String name;
  final int total_quota;
  final int used_days;
  final int remaining_days;
  final int pending_days;

  const LeaveBalanceModel({
    required this.id_leave_types,
    required this.name,
    required this.total_quota,
    required this.used_days,
    required this.remaining_days,
    this.pending_days = 0,
  });

  factory LeaveBalanceModel.fromMap(Map<String, dynamic> map) {
    final rawId = map['id_leave_types'] ?? map['id'] ?? 0;
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    final rawTotal = map['total_quota'] ??
        map['total_days'] ??
        map['quota_days'] ??
        map['quota'] ??
        0;
    final total = rawTotal is int ? rawTotal : int.tryParse(rawTotal.toString()) ?? 0;

    final rawUsed = map['used_days'] ?? map['used'] ?? 0;
    final used = rawUsed is int ? rawUsed : int.tryParse(rawUsed.toString()) ?? 0;

    final rawPending = map['pending_days'] ?? map['pending'] ?? 0;
    final pending = rawPending is int ? rawPending : int.tryParse(rawPending.toString()) ?? 0;

    final rawRemaining = map['remaining_days'] ?? map['remaining'] ?? map['balance'] ?? (total - used);
    final remaining = rawRemaining is int ? rawRemaining : int.tryParse(rawRemaining.toString()) ?? (total - used);

    final name = map['name'] as String? ??
        map['leave_type'] as String? ??
        map['type_name'] as String? ??
        'Cuti Tahunan';

    return LeaveBalanceModel(
      id_leave_types: id,
      name: name,
      total_quota: total,
      used_days: used,
      remaining_days: remaining,
      pending_days: pending,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_leave_types': id_leave_types,
      'name': name,
      'total_quota': total_quota,
      'used_days': used_days,
      'remaining_days': remaining_days,
      'pending_days': pending_days,
    };
  }
}

class LeaveRequestModel {
  final int id_leave_requests;
  final String? request_number;
  final int? id_employees;
  final String? employee_name;
  final String? employee_nik;
  final String? employee_department;
  final String? employee_position;
  final String? approver_name;
  final dynamic leave_type;
  final int? id_leave_types;
  final bool? is_paid;
  final String start_date;
  final String end_date;
  final int total_days;
  final String reason;
  final LeaveStatus status;
  final String? attachment_url;
  final String? rejection_note;
  final String? created_at;

  const LeaveRequestModel({
    required this.id_leave_requests,
    this.request_number,
    this.id_employees,
    this.employee_name,
    this.employee_nik,
    this.employee_department,
    this.employee_position,
    this.approver_name,
    required this.leave_type,
    this.id_leave_types,
    this.is_paid,
    required this.start_date,
    required this.end_date,
    required this.total_days,
    required this.reason,
    required this.status,
    this.attachment_url,
    this.rejection_note,
    this.created_at,
  });

  String get leave_type_name {
    if (leave_type is Map) {
      return (leave_type as Map)['name']?.toString() ?? 'Cuti';
    }
    if (leave_type is String) {
      return leave_type as String;
    }
    return 'Cuti';
  }

  bool get effectiveIsPaid {
    if (is_paid != null) return is_paid!;
    if (leave_type is Map && (leave_type as Map)['is_paid'] is bool) {
      return (leave_type as Map)['is_paid'] as bool;
    }
    return !leave_type_name.toLowerCase().contains('tanpa gaji');
  }

  String get categoryLabel => effectiveIsPaid ? 'Berbayar' : 'Tanpa Gaji';

  String get displayRequestNumber {
    final raw = request_number?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final parsedCreated = DateTime.tryParse(created_at?.trim() ?? '');
    final parsedDate = DateTime.tryParse(start_date.trim());
    final refDate = parsedCreated?.toLocal() ?? parsedDate ?? DateTime.now();
    final ym =
        '${refDate.year.toString().padLeft(4, '0')}${refDate.month.toString().padLeft(2, '0')}';
    final seq = (id_leave_requests < 0 ? 0 : id_leave_requests)
        .toString()
        .padLeft(6, '0');
    return 'LVR-$ym-$seq';
  }

  String? get resolvedAttachmentUrl {
    final raw = attachment_url?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final apiUri = Uri.tryParse(ApiEndpoints.baseUrl);
    if (apiUri != null && apiUri.hasScheme && apiUri.host.isNotEmpty) {
      final origin =
          '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ':${apiUri.port}' : ''}';
      final normalizedPath = raw.startsWith('/') ? raw : '/$raw';
      return '$origin$normalizedPath';
    }
    return raw;
  }

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map) {
    final rawId = map['id_leave_requests'] ?? map['id'] ?? 0;
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    final rawEmpId = map['id_employees'];
    final int? empId = rawEmpId != null
        ? (rawEmpId is int ? rawEmpId : int.tryParse(rawEmpId.toString()))
        : null;

    String? employeeName;
    String? employeeNik;
    String? employeeDept;
    String? employeePos;
    final empMap = map['employee'];
    if (empMap is Map) {
      employeeNik = empMap['nik']?.toString();
      employeeDept = empMap['department_name']?.toString() ??
          (empMap['department'] is Map
              ? (empMap['department'] as Map)['name']?.toString()
              : null);
      employeePos = empMap['job_position_name']?.toString() ??
          (empMap['job_position'] is Map
              ? (empMap['job_position'] as Map)['name']?.toString()
              : null) ??
          (empMap['jobPosition'] is Map
              ? (empMap['jobPosition'] as Map)['name']?.toString()
              : null);
      final userMap = empMap['user'];
      if (userMap is Map) {
        employeeName = userMap['name']?.toString();
      }
      employeeName ??=
          empMap['full_name']?.toString() ?? empMap['name']?.toString();
    }
    employeeName ??= map['employee_name']?.toString();

    String? approverName;
    if (map['approver'] is Map) {
      approverName = (map['approver'] as Map)['name']?.toString();
    }
    approverName ??= map['approver_name']?.toString();

    final rawTypeId = map['id_leave_types'];
    final int? typeId = rawTypeId != null
        ? (rawTypeId is int ? rawTypeId : int.tryParse(rawTypeId.toString()))
        : null;

    bool? isPaid;
    final rawPaid = map['is_paid'] ??
        (map['leave_type'] is Map ? (map['leave_type'] as Map)['is_paid'] : null) ??
        (map['leave_type_obj'] is Map
            ? (map['leave_type_obj'] as Map)['is_paid']
            : null);
    if (rawPaid is bool) {
      isPaid = rawPaid;
    } else if (rawPaid != null) {
      isPaid = rawPaid == 1 || rawPaid == '1' || rawPaid == 'true';
    }

    final rawDays = map['total_days'] ?? map['duration'] ?? 1;
    final totalDays = rawDays is int ? rawDays : int.tryParse(rawDays.toString()) ?? 1;

    final statusStr = map['status'] as String?;
    final status = LeaveStatus.fromString(statusStr);

    final rejectionNote = map['rejection_note'] as String? ??
        map['rejected_reason'] as String?;

    return LeaveRequestModel(
      id_leave_requests: id,
      request_number: map['request_number']?.toString(),
      id_employees: empId,
      employee_name: employeeName,
      employee_nik: employeeNik,
      employee_department: employeeDept,
      employee_position: employeePos,
      approver_name: approverName,
      leave_type: map['leave_type'] ?? map['type'] ?? 'Cuti',
      id_leave_types: typeId,
      is_paid: isPaid,
      start_date: map['start_date'] as String? ?? '',
      end_date: map['end_date'] as String? ?? '',
      total_days: totalDays,
      reason: map['reason'] as String? ?? '',
      status: status,
      attachment_url: map['attachment_url'] as String? ?? map['attachment'] as String?,
      rejection_note: rejectionNote,
      created_at: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_leave_requests': id_leave_requests,
      'request_number': request_number,
      'id_employees': id_employees,
      'employee_name': employee_name,
      'employee_nik': employee_nik,
      'employee_department': employee_department,
      'employee_position': employee_position,
      'approver_name': approver_name,
      'leave_type': leave_type,
      'id_leave_types': id_leave_types,
      'is_paid': is_paid,
      'start_date': start_date,
      'end_date': end_date,
      'total_days': total_days,
      'reason': reason,
      'status': status.name,
      'attachment_url': attachment_url,
      'rejection_note': rejection_note,
      'created_at': created_at,
    };
  }
}
