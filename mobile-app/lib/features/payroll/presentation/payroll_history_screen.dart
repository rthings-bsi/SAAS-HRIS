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

class PayrollHistoryScreen extends ConsumerStatefulWidget {
  const PayrollHistoryScreen({super.key});

  @override
  ConsumerState<PayrollHistoryScreen> createState() => _PayrollHistoryScreenState();
}

class _PayrollHistoryScreenState extends ConsumerState<PayrollHistoryScreen> {
  bool _isSalaryVisible = true;

  Widget _buildSummaryCard(PayrollSlipModel latestSlip) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space16),
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
            color: Color(0x06000000),
            blurRadius: 10,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Gaji Bersih Terakhir',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space4),
                  IconButton(
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: AppDimensions.minTouchTarget,
                      minHeight: AppDimensions.minTouchTarget,
                    ),
                    icon: Icon(
                      _isSalaryVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    tooltip: _isSalaryVisible
                        ? 'Sembunyikan nominal gaji'
                        : 'Tampilkan nominal gaji',
                    onPressed: () {
                      setState(() {
                        _isSalaryVisible = !_isSalaryVisible;
                      });
                    },
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: latestSlip.status.backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: latestSlip.status.borderColor,
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
                          color: latestSlip.status.textColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      latestSlip.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: latestSlip.status.textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            latestSlip.period_name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _isSalaryVisible
                  ? latestSlip.formattedNetSalary
                  : 'Rp ••••••••',
              style: AppTextStyle.currency(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Dibayar: ${latestSlip.formattedPaymentDate}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBody,
                  ),
                ),
              ],
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
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
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
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
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
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                slip.status.label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: slip.status.textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          slip.formattedPaymentDate,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _isSalaryVisible
                              ? slip.formattedNetSalary
                              : 'Rp ••••••••',
                          style: AppTextStyle.currency(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: 22,
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
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final isNonEmployee =
        auth.user != null && (auth.isAdministrator || !auth.hasEmployeeProfile);

    if (isNonEmployee) {
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
          title: Row(
            children: [
              const HrHubLogo(size: 26),
              const SizedBox(width: 10),
              Container(width: 1, height: 16, color: AppColors.borderStrong),
              const SizedBox(width: 10),
              const Text(
                'Slip Gaji',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
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
      backgroundColor: AppColors.surfaceCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderSubtle, height: 1.0),
        ),
        title: Row(
          children: [
            const HrHubLogo(size: 26),
            const SizedBox(width: 10),
            Container(width: 1, height: 16, color: AppColors.borderStrong),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Slip Gaji',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (auth.companyName.isNotEmpty)
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.statusSuccess,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        auth.companyName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
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
              AppSkeleton(height: 140),
              SizedBox(height: AppDimensions.space16),
              AppSkeleton(height: 20, width: 140),
              SizedBox(height: AppDimensions.space12),
              AppSkeleton(height: 76),
              SizedBox(height: AppDimensions.space8),
              AppSkeleton(height: 76),
              SizedBox(height: AppDimensions.space8),
              AppSkeleton(height: 76),
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
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Riwayat Slip Gaji',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
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
