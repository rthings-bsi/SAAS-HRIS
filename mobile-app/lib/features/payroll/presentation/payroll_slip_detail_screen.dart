import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../data/payroll_models.dart';
import '../provider/payroll_provider.dart';

class PayrollSlipDetailScreen extends ConsumerWidget {
  final PayrollSlipModel slip;

  const PayrollSlipDetailScreen({
    super.key,
    required this.slip,
  });

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: AppDimensions.cardBorderRadius,
        border: Border.all(
          color: AppColors.borderNeutral,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Periode Gaji',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space4),
                    Text(
                      slip.period_name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: AppDimensions.space4,
                ),
                decoration: BoxDecoration(
                  color: slip.status.backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: slip.status.borderColor,
                    width: AppDimensions.borderWidth,
                  ),
                ),
                child: Text(
                  slip.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: slip.status.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          const Divider(
            color: AppColors.borderNeutral,
            thickness: AppDimensions.borderWidth,
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tanggal Pembayaran',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                ),
              ),
              Text(
                slip.formattedPaymentDate,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required String value,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                color: isBold ? AppColors.inkPrimary : AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
          Text(
            value,
            style: AppTextStyle.currency(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: valueColor ?? AppColors.inkPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: AppDimensions.cardBorderRadius,
        border: Border.all(
          color: AppColors.borderNeutral,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 18,
                color: AppColors.actionAccent,
              ),
              SizedBox(width: AppDimensions.space8),
              Text(
                'Rincian Penerimaan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          _buildBreakdownRow(
            label: 'Gaji Pokok',
            value: slip.formattedBasicSalary,
          ),
          _buildBreakdownRow(
            label: 'Tunjangan Tetap',
            value: slip.formattedAllowanceFixed,
          ),
          _buildBreakdownRow(
            label: 'Lembur',
            value: slip.formattedOvertimePay,
          ),
          const SizedBox(height: AppDimensions.space8),
          const Divider(
            color: AppColors.borderNeutral,
            thickness: AppDimensions.borderWidth,
          ),
          const SizedBox(height: AppDimensions.space8),
          _buildBreakdownRow(
            label: 'Total Penerimaan',
            value: slip.formattedTotalEarnings,
            isBold: true,
            valueColor: AppColors.actionAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionsCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: AppDimensions.cardBorderRadius,
        border: Border.all(
          color: AppColors.borderNeutral,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.remove_circle_outline_rounded,
                size: 18,
                color: AppColors.dangerText,
              ),
              SizedBox(width: AppDimensions.space8),
              Text(
                'Rincian Potongan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          _buildBreakdownRow(
            label: 'Keterlambatan',
            value: slip.formattedDeductionLate,
          ),
          _buildBreakdownRow(
            label: 'Ketidakhadiran',
            value: slip.formattedDeductionAbsence,
          ),
          _buildBreakdownRow(
            label: 'Potongan Lain',
            value: slip.formattedDeductionOther,
          ),
          const SizedBox(height: AppDimensions.space8),
          const Divider(
            color: AppColors.borderNeutral,
            thickness: AppDimensions.borderWidth,
          ),
          const SizedBox(height: AppDimensions.space8),
          _buildBreakdownRow(
            label: 'Total Potongan',
            value: slip.formattedTotalDeductions,
            isBold: true,
            valueColor: AppColors.dangerText,
          ),
        ],
      ),
    );
  }

  Widget _buildNetSalaryCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: AppDimensions.cardBorderRadius,
        border: Border.all(
          color: AppColors.successBorder,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Gaji Bersih (Take Home Pay)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              slip.formattedNetSalary,
              style: AppTextStyle.currency(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.successText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(payrollDownloadNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        title: const Text('Detail Slip Gaji'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: AppDimensions.space16),
              _buildEarningsCard(),
              const SizedBox(height: AppDimensions.space16),
              _buildDeductionsCard(),
              const SizedBox(height: AppDimensions.space16),
              _buildNetSalaryCard(),
              const SizedBox(height: AppDimensions.space24),
              AppButton(
                text: 'Unduh Slip Gaji (PDF)',
                icon: const Icon(Icons.download_rounded, size: 20),
                isLoading: downloadState.isLoading,
                height: AppDimensions.minTouchTarget,
                onPressed: () async {
                  final success = await ref
                      .read(payrollDownloadNotifierProvider.notifier)
                      .downloadSlipPdf(slip.id_payroll_slips);

                  if (!context.mounted) return;

                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Slip gaji berhasil diunduh.'),
                        backgroundColor: AppColors.successText,
                      ),
                    );
                  } else {
                    final errorMsg = ref.read(payrollDownloadNotifierProvider).errorMessage;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMsg ?? 'Gagal mengunduh slip gaji.'),
                        backgroundColor: AppColors.dangerText,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: AppDimensions.space16),
            ],
          ),
        ),
      ),
    );
  }
}
