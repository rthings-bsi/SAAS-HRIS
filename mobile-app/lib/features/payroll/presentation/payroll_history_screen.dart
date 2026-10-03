import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/hr_hub_logo.dart';
import '../../auth/provider/auth_provider.dart';
import '../data/payroll_models.dart';
import '../provider/payroll_provider.dart';
import 'payroll_slip_detail_screen.dart';

class PayrollHistoryScreen extends ConsumerWidget {
  const PayrollHistoryScreen({super.key});

  Widget _buildSummaryCard(PayrollSlipModel latestSlip) {
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
            children: [
              const Text(
                'Gaji Bersih Terakhir',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: AppDimensions.space4,
                ),
                decoration: BoxDecoration(
                  color: latestSlip.status.backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: latestSlip.status.borderColor,
                    width: AppDimensions.borderWidth,
                  ),
                ),
                child: Text(
                  latestSlip.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: latestSlip.status.textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            latestSlip.period_name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.inkPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              latestSlip.formattedNetSalary,
              style: AppTextStyle.currency(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.actionAccent,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            'Dibayar: ${latestSlip.formattedPaymentDate}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlipItem(BuildContext context, PayrollSlipModel slip) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space8),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: AppDimensions.cardBorderRadius,
        border: Border.all(
          color: AppColors.borderNeutral,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppDimensions.cardBorderRadius,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PayrollSlipDetailScreen(slip: slip),
              ),
            );
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                slip.period_name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: slip.status.textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space4),
                        Text(
                          slip.formattedPaymentDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space4),
                        Text(
                          slip.formattedNetSalary,
                          style: AppTextStyle.currency(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.actionAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.inkMuted,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isNonEmployee =
        auth.user != null && (auth.isAdministrator || !auth.hasEmployeeProfile);

    if (isNonEmployee) {
      return Scaffold(
        backgroundColor: AppColors.canvasLight,
        appBar: AppBar(
          title: const Row(
            children: [
              HrHubLogo(size: 24),
              SizedBox(width: 10),
              Text('Slip Gaji'),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: AppEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Slip Gaji Khusus Karyawan',
              description:
                  'Akun Anda (${auth.roleLabel}) terdaftar sebagai akun pengelola. Fitur slip gaji pada aplikasi mobile ini diperuntukkan bagi karyawan operasional. Untuk mengelola penggajian seluruh staf, silakan buka Web Admin.',
              actionText: 'Keluar & Ganti Akun',
              onAction: () => ref.read(authStateProvider.notifier).logout(),
            ),
          ),
        ),
      );
    }

    final slipsAsync = ref.watch(myPayrollSlipsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        title: const Row(
          children: [
            HrHubLogo(size: 24),
            SizedBox(width: 10),
            Text('Slip Gaji'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myPayrollSlipsProvider);
        },
        child: slipsAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(AppDimensions.space16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              AppSkeleton(height: 120),
              SizedBox(height: AppDimensions.space16),
              AppSkeleton(height: 20, width: 140),
              SizedBox(height: AppDimensions.space12),
              AppSkeleton(height: 72),
              SizedBox(height: AppDimensions.space8),
              AppSkeleton(height: 72),
              SizedBox(height: AppDimensions.space8),
              AppSkeleton(height: 72),
            ],
          ),
          error: (error, _) => Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: AppErrorState(
                  isCard: true,
                  title: 'Gagal Memuat Slip Gaji',
                  message: error.toString(),
                  retryText: 'Muat Ulang',
                  onRetry: () => ref.invalidate(myPayrollSlipsProvider),
                ),
              ),
            ),
          ),
          data: (slips) {
            if (slips.isEmpty) {
              return const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 400,
                  child: AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum Ada Slip Gaji',
                    description: 'Slip gaji yang telah diproses oleh HR akan tampil di sini secara berkala.',
                  ),
                ),
              );
            }

            final latestSlip = slips.first;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.space16),
              children: [
                _buildSummaryCard(latestSlip),
                const SizedBox(height: AppDimensions.space16),
                const Text(
                  'Riwayat Slip Gaji',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.space12),
                ...slips.map((slip) => _buildSlipItem(context, slip)),
              ],
            );
          },
        ),
      ),
    );
  }
}
