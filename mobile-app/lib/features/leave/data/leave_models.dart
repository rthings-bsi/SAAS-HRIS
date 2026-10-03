// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
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
        return AppColors.warningText;
      case LeaveStatus.approved:
        return AppColors.successText;
      case LeaveStatus.rejected:
        return AppColors.dangerText;
      case LeaveStatus.cancelled:
        return AppColors.infoText;
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
        return AppColors.infoBg;
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
        return AppColors.infoBorder;
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

  const LeaveBalanceModel({
    required this.id_leave_types,
    required this.name,
    required this.total_quota,
    required this.used_days,
    required this.remaining_days,
  });

  factory LeaveBalanceModel.fromMap(Map<String, dynamic> map) {
    final rawId = map['id_leave_types'] ?? map['id'] ?? 0;
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    final rawTotal = map['total_quota'] ?? map['total_days'] ?? map['quota'] ?? 0;
    final total = rawTotal is int ? rawTotal : int.tryParse(rawTotal.toString()) ?? 0;

    final rawUsed = map['used_days'] ?? map['used'] ?? 0;
    final used = rawUsed is int ? rawUsed : int.tryParse(rawUsed.toString()) ?? 0;

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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_leave_types': id_leave_types,
      'name': name,
      'total_quota': total_quota,
      'used_days': used_days,
      'remaining_days': remaining_days,
    };
  }
}

class LeaveRequestModel {
  final int id_leave_requests;
  final dynamic leave_type;
  final int? id_leave_types;
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
    required this.leave_type,
    this.id_leave_types,
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

  factory LeaveRequestModel.fromMap(Map<String, dynamic> map) {
    final rawId = map['id_leave_requests'] ?? map['id'] ?? 0;
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    final rawTypeId = map['id_leave_types'];
    final int? typeId = rawTypeId != null
        ? (rawTypeId is int ? rawTypeId : int.tryParse(rawTypeId.toString()))
        : null;

    final rawDays = map['total_days'] ?? map['duration'] ?? 1;
    final totalDays = rawDays is int ? rawDays : int.tryParse(rawDays.toString()) ?? 1;

    final statusStr = map['status'] as String?;
    final status = LeaveStatus.fromString(statusStr);

    final rejectionNote = map['rejection_note'] as String? ??
        map['rejected_reason'] as String?;

    return LeaveRequestModel(
      id_leave_requests: id,
      leave_type: map['leave_type'] ?? map['type'] ?? 'Cuti',
      id_leave_types: typeId,
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
      'leave_type': leave_type,
      'id_leave_types': id_leave_types,
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
