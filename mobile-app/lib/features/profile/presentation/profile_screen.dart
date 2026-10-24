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
        backgroundColor: AppColors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.statusDangerBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.statusDangerBorder),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.statusDanger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Keluar Akun',
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
        content: const Text(
          'Apakah Anda yakin ingin keluar dari sesi aplikasi HR Hub pada perangkat ini?',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textBody,
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(80, AppDimensions.minTouchTarget),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusDanger,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(100, AppDimensions.minTouchTarget),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authStateProvider.notifier).logout();
            },
            child: const Text(
              'Keluar',
              style: TextStyle(fontWeight: FontWeight.w700),
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

    final initials = userName.trim().isNotEmpty
        ? userName
            .trim()
            .split(' ')
            .take(2)
            .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
            .join()
        : 'U';

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
              'Profil Saya',
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
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(authStateProvider.notifier).refreshProfile();
        },
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // User Header Card
            Container(
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
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Corporate Avatar with verified badge
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -3,
                            right: -3,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: AppColors.statusSuccess,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppDimensions.space16),

                      // Name & Position details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (statusLabel != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusSuccessBg,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppColors.statusSuccessBorder,
                                      ),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.statusSuccess,
                                      ),
                                    ),
                                  ),
                                if (nik != null && nik.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'NIK: $nik',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              jobPosition,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space16),

                  // Mini stats banner: Organisasi & Masa Kerja
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCanvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.borderSubtle,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tenant Organisasi',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                companyName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.borderSubtle,
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mulai Bekerja',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                hireDateFormatted,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Section 1: Pekerjaan & Penugasan
            _buildSectionHeader(
              title: 'Pekerjaan & Penugasan',
              icon: Icons.business_center_outlined,
            ),
            const SizedBox(height: AppDimensions.space8),
            _buildInfoCard(
              children: [
                _buildInfoTile(
                  icon: Icons.store_rounded,
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
                  icon: Icons.schedule_rounded,
                  label: 'Shift Kerja',
                  value: 'Reguler Operasional',
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.near_me_rounded,
                  label: 'Geofence Presensi',
                  value: 'Radius 50m Aktif',
                  valueColor: AppColors.statusSuccess,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),

            // Section 2: Kontak & Keamanan Akun
            _buildSectionHeader(
              title: 'Kontak & Keamanan Akun',
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

            // Section 3: Rekening Penggajian
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

            // Section 4: Aplikasi & Dukungan
            _buildSectionHeader(
              title: 'Bantuan & Informasi',
              icon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: AppDimensions.space8),
            _buildInfoCard(
              children: [
                _buildInfoTile(
                  icon: Icons.support_agent_rounded,
                  label: 'Pusat Bantuan',
                  value: 'Tim HR & Operasional',
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.phone_android_rounded,
                  label: 'Versi Aplikasi',
                  value: 'HR Hub Mobile v2.4.0',
                ),
                _buildDivider(),
                _buildInfoTile(
                  icon: Icons.cloud_done_outlined,
                  label: 'Status Layanan',
                  value: 'Terkoneksi Aman (SSL)',
                  valueColor: AppColors.statusSuccess,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space24),

            // Log Out Button
            Container(
              decoration: BoxDecoration(
                color: AppColors.statusDangerBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.statusDangerBorder,
                  width: 1.0,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
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
                            color: AppColors.statusDanger,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Keluar dari Akun',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusDanger,
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
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
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
            blurRadius: 6,
            offset: Offset(0, 1),
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
      constraints: const BoxConstraints(minHeight: 48),
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
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
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
                  color: valueColor ?? AppColors.textPrimary,
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
      color: AppColors.borderSubtle,
      indent: 16,
      endIndent: 16,
    );
  }
}
