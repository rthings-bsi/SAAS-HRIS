// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';

enum PayrollStatus {
  draft,
  locked,
  paid;

  static PayrollStatus fromString(String? status) {
    switch (status?.toLowerCase().trim()) {
      case 'paid':
      case 'dibayar':
      case 'selesai':
        return PayrollStatus.paid;
      case 'locked':
      case 'finalized':
      case 'final':
      case 'terkunci':
        return PayrollStatus.locked;
      case 'draft':
      case 'draf':
      default:
        return PayrollStatus.draft;
    }
  }
}

extension PayrollStatusX on PayrollStatus {
  String get label {
    switch (this) {
      case PayrollStatus.draft:
        return 'Draf';
      case PayrollStatus.locked:
        return 'Final';
      case PayrollStatus.paid:
        return 'Dibayar';
    }
  }

  Color get textColor {
    switch (this) {
      case PayrollStatus.draft:
        return AppColors.inkMuted;
      case PayrollStatus.locked:
        return AppColors.warningText;
      case PayrollStatus.paid:
        return AppColors.successText;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case PayrollStatus.draft:
        return AppColors.surfaceMuted;
      case PayrollStatus.locked:
        return AppColors.warningBg;
      case PayrollStatus.paid:
        return AppColors.successBg;
    }
  }

  Color get borderColor {
    switch (this) {
      case PayrollStatus.draft:
        return AppColors.borderNeutral;
      case PayrollStatus.locked:
        return AppColors.warningBorder;
      case PayrollStatus.paid:
        return AppColors.successBorder;
    }
  }
}

class PayrollPeriodModel {
  final int id_payroll_periods;
  final String name;
  final String start_date;
  final String end_date;
  final String? payment_date;
  final String status;

  const PayrollPeriodModel({
    required this.id_payroll_periods,
    required this.name,
    required this.start_date,
    required this.end_date,
    this.payment_date,
    required this.status,
  });

  factory PayrollPeriodModel.fromMap(Map<String, dynamic> map) {
    final rawId = map['id_payroll_periods'] ?? map['id'] ?? 0;
    final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;

    return PayrollPeriodModel(
      id_payroll_periods: id,
      name: map['name'] as String? ?? 'Periode Gaji',
      start_date: map['start_date'] as String? ?? '',
      end_date: map['end_date'] as String? ?? '',
      payment_date: map['payment_date'] as String?,
      status: map['status'] as String? ?? 'draft',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_payroll_periods': id_payroll_periods,
      'name': name,
      'start_date': start_date,
      'end_date': end_date,
      'payment_date': payment_date,
      'status': status,
    };
  }
}

class PayrollSlipModel {
  final int id_payroll_slips;
  final int id_payroll_periods;
  final int id_employees;
  final double basic_salary;
  final double allowance_fixed;
  final double overtime_pay;
  final double deduction_late;
  final double deduction_absence;
  final double deduction_other;
  final double net_salary;
  final String? pdf_url;
  final String? pdf_path;
  final String period_name;
  final String? payment_date;
  final PayrollStatus status;
  final PayrollPeriodModel? payroll_period;

  const PayrollSlipModel({
    required this.id_payroll_slips,
    required this.id_payroll_periods,
    required this.id_employees,
    required this.basic_salary,
    required this.allowance_fixed,
    required this.overtime_pay,
    required this.deduction_late,
    required this.deduction_absence,
    required this.deduction_other,
    required this.net_salary,
    this.pdf_url,
    this.pdf_path,
    required this.period_name,
    this.payment_date,
    this.status = PayrollStatus.draft,
    this.payroll_period,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  factory PayrollSlipModel.fromMap(Map<String, dynamic> map) {
    PayrollPeriodModel? periodModel;
    String periodName = 'Periode Gaji';
    String? payDate = map['payment_date'] as String?;
    String? statusString = map['status'] as String?;

    if (map['payroll_period'] is Map<String, dynamic>) {
      periodModel = PayrollPeriodModel.fromMap(map['payroll_period'] as Map<String, dynamic>);
      periodName = periodModel.name;
      payDate ??= periodModel.payment_date;
      statusString ??= periodModel.status;
    } else if (map['period'] is String) {
      periodName = map['period'] as String;
    } else if (map['period_name'] is String) {
      periodName = map['period_name'] as String;
    }

    final id = _parseInt(map['id_payroll_slips'] ?? map['id']);
    final periodId = _parseInt(map['id_payroll_periods'] ?? map['payroll_period_id']);
    final empId = _parseInt(map['id_employees'] ?? map['employee_id']);

    final basic = _parseDouble(map['basic_salary']);
    final allowance = _parseDouble(map['allowance_fixed']);
    final overtime = _parseDouble(map['overtime_pay']);
    final lateDed = _parseDouble(map['deduction_late']);
    final absDed = _parseDouble(map['deduction_absence']);
    final othDed = _parseDouble(map['deduction_other']);
    final net = _parseDouble(map['net_salary']);

    return PayrollSlipModel(
      id_payroll_slips: id,
      id_payroll_periods: periodId,
      id_employees: empId,
      basic_salary: basic,
      allowance_fixed: allowance,
      overtime_pay: overtime,
      deduction_late: lateDed,
      deduction_absence: absDed,
      deduction_other: othDed,
      net_salary: net,
      pdf_url: map['pdf_url'] as String?,
      pdf_path: map['pdf_path'] as String?,
      period_name: periodName,
      payment_date: payDate,
      status: PayrollStatus.fromString(statusString),
      payroll_period: periodModel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_payroll_slips': id_payroll_slips,
      'id_payroll_periods': id_payroll_periods,
      'id_employees': id_employees,
      'basic_salary': basic_salary,
      'allowance_fixed': allowance_fixed,
      'overtime_pay': overtime_pay,
      'deduction_late': deduction_late,
      'deduction_absence': deduction_absence,
      'deduction_other': deduction_other,
      'net_salary': net_salary,
      'pdf_url': pdf_url,
      'pdf_path': pdf_path,
      'period_name': period_name,
      'payment_date': payment_date,
      'status': status.name,
      if (payroll_period != null) 'payroll_period': payroll_period!.toMap(),
    };
  }

  double get totalEarnings => basic_salary + allowance_fixed + overtime_pay;
  double get totalDeductions => deduction_late + deduction_absence + deduction_other;

  static String formatRupiah(num amount) {
    try {
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(amount);
    } catch (_) {
      final formattedNumber = amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
      return 'Rp $formattedNumber';
    }
  }

  String get formattedNetSalary => formatRupiah(net_salary);
  String get formattedBasicSalary => formatRupiah(basic_salary);
  String get formattedAllowanceFixed => formatRupiah(allowance_fixed);
  String get formattedOvertimePay => formatRupiah(overtime_pay);
  String get formattedDeductionLate => formatRupiah(deduction_late);
  String get formattedDeductionAbsence => formatRupiah(deduction_absence);
  String get formattedDeductionOther => formatRupiah(deduction_other);
  String get formattedTotalEarnings => formatRupiah(totalEarnings);
  String get formattedTotalDeductions => formatRupiah(totalDeductions);

  String get formattedPaymentDate {
    if (payment_date == null || payment_date!.isEmpty) {
      return 'Tanggal belum ditentukan';
    }
    try {
      final parsed = DateTime.parse(payment_date!);
      return DateFormat('d MMMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      return payment_date!;
    }
  }
}
