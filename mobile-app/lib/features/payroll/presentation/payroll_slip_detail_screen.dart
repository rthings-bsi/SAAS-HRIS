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
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
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
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slip.period_name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: slip.status.backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: slip.status.borderColor,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: slip.status.textColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      slip.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: slip.status.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          const Divider(
            color: AppColors.borderSubtle,
            thickness: 1.0,
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Tanggal Pembayaran',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                slip.formattedPaymentDate,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
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
    String? subtitle,
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                    color: isBold ? AppColors.textPrimary : AppColors.textBody,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
          Text(
            value,
            style: AppTextStyle.currency(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
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
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccessBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 18,
                      color: AppColors.statusSuccess,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  const Text(
                    'Rincian Penerimaan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccessBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Pendapatan',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusSuccess,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          _buildBreakdownRow(
            label: 'Gaji Pokok',
            subtitle: 'Sesuai kontrak kerja reguler',
            value: slip.formattedBasicSalary,
          ),
          _buildBreakdownRow(
            label: 'Tunjangan Tetap',
            subtitle: 'Transportasi & operasional',
            value: slip.formattedAllowanceFixed,
          ),
          _buildBreakdownRow(
            label: 'Lembur',
            subtitle: 'Kompensasi lembur kerja',
            value: slip.formattedOvertimePay,
          ),
          const SizedBox(height: AppDimensions.space8),
          const Divider(
            color: AppColors.borderSubtle,
            thickness: 1.0,
          ),
          const SizedBox(height: AppDimensions.space8),
          _buildBreakdownRow(
            label: 'Total Penerimaan',
            value: slip.formattedTotalEarnings,
            isBold: true,
            valueColor: AppColors.statusSuccess,
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionsCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.statusDangerBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 18,
                      color: AppColors.statusDanger,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  const Text(
                    'Rincian Potongan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusDangerBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Pemotongan',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusDanger,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          _buildBreakdownRow(
            label: 'Keterlambatan',
            subtitle: 'Penalti disiplin jam masuk',
            value: slip.formattedDeductionLate,
          ),
          _buildBreakdownRow(
            label: 'Ketidakhadiran',
            subtitle: 'Potongan izin/alpha',
            value: slip.formattedDeductionAbsence,
          ),
          _buildBreakdownRow(
            label: 'Potongan Lain',
            subtitle: 'BPJS & iuran perusahaan',
            value: slip.formattedDeductionOther,
          ),
          const SizedBox(height: AppDimensions.space8),
          const Divider(
            color: AppColors.borderSubtle,
            thickness: 1.0,
          ),
          const SizedBox(height: AppDimensions.space8),
          _buildBreakdownRow(
            label: 'Total Potongan',
            value: slip.formattedTotalDeductions,
            isBold: true,
            valueColor: AppColors.statusDanger,
          ),
        ],
      ),
    );
  }

  Widget _buildNetSalaryCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.statusSuccessBorder,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06059669),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.statusSuccessBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  size: 18,
                  color: AppColors.statusSuccess,
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              const Expanded(
                child: Text(
                  'Total Gaji Bersih (Take Home Pay)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              slip.formattedNetSalary,
              style: AppTextStyle.currency(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.statusSuccess,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.account_balance_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ditransfer langsung ke rekening payroll terdaftar',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalNotice() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: AppColors.textMuted,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dokumen ini diterbitkan otomatis oleh sistem HR HUB Payroll dan sah sebagai bukti pembayaran resmi tanpa tanda tangan basah.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                height: 1.4,
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
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderSubtle, height: 1.0),
        ),
        title: const Text(
          'Detail Slip Gaji',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
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
              const SizedBox(height: AppDimensions.space16),
              _buildLegalNotice(),
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
                        backgroundColor: AppColors.statusSuccess,
                      ),
                    );
                  } else {
                    final errorMsg =
                        ref.read(payrollDownloadNotifierProvider).errorMessage;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMsg ?? 'Gagal mengunduh slip gaji.'),
                        backgroundColor: AppColors.statusDanger,
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
