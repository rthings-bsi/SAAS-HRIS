import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_phosphor_icons.dart';
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
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(14),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.wallet,
                          size: 16,
                          color: AppColors.primaryContainer,
                        ),
                        const SizedBox(width: 6),
                        const Flexible(
                          child: Text(
                            'Gaji Bersih Terakhir',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                              letterSpacing: -0.1,
                            ),
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
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                            color: AppColors.textMuted,
                            size: 17,
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
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF1F5F9),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: 10,
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.landmark,
                  size: 14,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Dibayar: ${latestSlip.formattedPaymentDate}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textBody,
                    ),
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
                      PhosphorIconsRegular.receipt,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              slip.period_name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: slip.status.backgroundColor,
                                borderRadius: BorderRadius.circular(999),
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
                    LucideIcons.chevronRight,
                    color: AppColors.textMuted,
                    size: 18,
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
    final isNonEmployee = auth.user != null && !auth.hasEmployeeProfile;

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
              const Flexible(
                child: Text(
                  'Slip Gaji',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.space24),
                child: AppEmptyState(
                  icon: PhosphorIconsRegular.receipt,
                  title: 'Slip Gaji Khusus Karyawan',
                  description:
                      'Akun Anda (${auth.roleLabel}) terdaftar sebagai akun pengelola. Fitur slip gaji pada aplikasi mobile ini diperuntukkan bagi karyawan operasional. Untuk mengelola penggajian seluruh staf, silakan buka Web Admin.',
                  actionText: 'Keluar & Ganti Akun',
                  onAction: () => ref.read(authStateProvider.notifier).logout(),
                ),
              ),
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
            const Flexible(
              child: Text(
                'Slip Gaji',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: LayoutBuilder(
            builder: (context, viewportConstraints) {
              final double hPad = viewportConstraints.maxWidth < 310
                  ? 12
                  : (viewportConstraints.maxWidth < 470
                      ? AppDimensions.space16
                      : 20);

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myPayrollSlipsProvider);
                },
                child: slipsAsync.when(
                  loading: () => ListView(
                    padding: EdgeInsets.all(hPad),
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
                        padding: EdgeInsets.all(hPad),
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
                            icon: PhosphorIconsRegular.receipt,
                            title: 'Belum Ada Slip Gaji',
                            description:
                                'Slip gaji yang telah diproses oleh HR akan tampil di sini secara berkala.',
                          ),
                        ),
                      );
                    }

                    final latestSlip = slips.first;

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(hPad),
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
                            const Flexible(
                              child: Text(
                                'Riwayat Slip Gaji',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
