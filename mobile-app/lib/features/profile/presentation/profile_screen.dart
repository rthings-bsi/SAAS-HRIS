import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/hr_hub_logo.dart';
import '../../auth/provider/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimensions.cardBorderRadius,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: AppDimensions.buttonBorderRadius,
                border: Border.all(color: AppColors.dangerBorder),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.dangerText,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Keluar Akun',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi aplikasi HR Hub pada perangkat ini?',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.inkMuted,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(80, AppDimensions.minTouchTarget),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerText,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(100, AppDimensions.minTouchTarget),
              shape: const RoundedRectangleBorder(
                borderRadius: AppDimensions.buttonBorderRadius,
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authStateProvider.notifier).logout();
            },
            child: const Text(
              'Keluar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(raw);
      return DateFormat('d MMMM yyyy', 'id_ID').format(parsed);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final userName = auth.userName;
    final userEmail = auth.userEmail;
    final companyName = auth.companyName;
    final roleLabel = auth.roleLabel;
    final jobPosition = auth.jobPositionName ?? roleLabel;
    final department = auth.departmentName ?? '-';
    final branch = auth.branchName ?? 'Kantor Utama';
    final nik = auth.employeeNik;
    final phone = auth.employeePhone ?? '-';
    final gender = auth.employeeGender ?? '-';
    final statusLabel = auth.employmentStatusLabel;
    final hireDateFormatted = _formatDate(auth.hireDate);

    // Initial avatar letters
    final initials = userName.trim().isNotEmpty
        ? userName
            .trim()
            .split(' ')
            .take(2)
            .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
            .join()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: const Row(
          children: [
            HrHubLogo(size: 24),
            SizedBox(width: 10),
            Text(
              'Profil Saya',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authStateProvider.notifier).refreshProfile();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space16,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // User Header Card with Avatar and Badges
            Container(
              padding: const EdgeInsets.all(AppDimensions.space20),
              decoration: BoxDecoration(
                color: AppColors.canvasLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Corporate Navy Avatar Matching Web-Admin
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.corporateNavy, AppColors.corporateBlueMuted],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x28094595),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // Name & Position
                  Text(
                    userName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    jobPosition,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.actionAccent,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space12),

                  // Badges (Employment Status & NIK)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (statusLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.successBorder,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: AppColors.successText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.successText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (nik != null && nik.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.hairline,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.badge_outlined,
                                size: 12,
                                color: AppColors.inkMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'NIK: $nik',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Section 1: Employment / Company Details
            _buildSectionHeader(
              title: 'Informasi Pekerjaan',
              icon: Icons.business_center_outlined,
            ),
            const SizedBox(height: AppDimensions.space8),
            _buildInfoCard(
              children: [
                _buildInfoTile(
                  icon: Icons.apartment_rounded,
                  label: 'Perusahaan',
                  value: companyName,
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.location_on_outlined,
                  label: 'Kantor Cabang',
                  value: branch,
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.domain_rounded,
                  label: 'Departemen',
                  value: department,
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.work_outline_rounded,
                  label: 'Jabatan / Posisi',
                  value: jobPosition,
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.event_available_outlined,
                  label: 'Tanggal Bergabung',
                  value: hireDateFormatted,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),

            // Section 2: Personal Contact Details
            _buildSectionHeader(
              title: 'Kontak & Akun',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: AppDimensions.space8),
            _buildInfoCard(
              children: [
                _buildInfoTile(
                  icon: Icons.mail_outline_rounded,
                  label: 'Alamat Email',
                  value: userEmail,
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Nomor Telepon',
                  value: phone,
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.wc_rounded,
                  label: 'Jenis Kelamin',
                  value: gender,
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.shield_outlined,
                  label: 'Peran Akun',
                  value: roleLabel,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),

            // Section 3: Payroll Bank Account (if present)
            if (auth.bankName != null && auth.bankName!.isNotEmpty) ...[
              _buildSectionHeader(
                title: 'Rekening Penggajian',
                icon: Icons.account_balance_outlined,
              ),
              const SizedBox(height: AppDimensions.space8),
              _buildInfoCard(
                children: [
                  _buildInfoTile(
                    icon: Icons.account_balance_rounded,
                    label: 'Nama Bank',
                    value: auth.bankName!,
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    icon: Icons.numbers_rounded,
                    label: 'Nomor Rekening',
                    value: auth.bankAccountNumber ?? '-',
                  ),
                  _buildDivider(),
                  _buildInfoTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Pemilik Rekening',
                    value: auth.bankAccountHolder ?? userName,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
            ],

            // Section 4: App Information
            _buildSectionHeader(
              title: 'Aplikasi',
              icon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: AppDimensions.space8),
            _buildInfoCard(
              children: [
                _buildInfoTile(
                  icon: Icons.phone_android_rounded,
                  label: 'Versi Aplikasi',
                  value: 'HR Hub Mobile v1.0.0',
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.cloud_done_outlined,
                  label: 'Status Layanan',
                  value: 'Terhubung ke Cloud',
                  valueColor: AppColors.successText,
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.dns_outlined,
                  label: 'Server API Terhubung',
                  value: 'api-hris.rickysatria.web.id',
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space24),

            // Destructive Log Out Action Card
            Container(
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.dangerBorder,
                  width: AppDimensions.borderWidth,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showLogoutDialog(context, ref),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppDimensions.minTouchTarget,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.space16,
                        vertical: AppDimensions.space16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: AppColors.dangerText,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Keluar dari Akun',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dangerText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.inkMuted),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 46),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space12,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: AppColors.inkMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.inkPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF1F5F9),
      indent: 16,
      endIndent: 16,
    );
  }
}
