import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
                LucideIcons.logOut,
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final userName = auth.userName;
    final userEmail = auth.userEmail;
    final roleLabel = auth.roleLabel;
    final jobPosition = auth.jobPositionName ?? roleLabel;
    final department = auth.departmentName ?? '-';
    final branch = auth.branchName ?? 'Kantor Utama';
    final nik = auth.employeeNik;
    final phone = auth.employeePhone ?? '-';
    final gender = auth.employeeGender ?? '-';
    final statusLabel = auth.employmentStatusLabel;

    final initials = userName.trim().isNotEmpty
        ? userName
            .trim()
            .split(' ')
            .take(2)
            .map((part) => part.isNotEmpty ? part[0].toUpperCase() : '')
            .join()
        : 'U';

    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 2.0);

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
                'Profil Saya',
                maxLines: 1,
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
                  await ref.read(authStateProvider.notifier).refreshProfile();
                },
                child: ListView(
                  padding: EdgeInsets.all(hPad),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // Single-Surface User Header Card (zero nested inner card)
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space16),
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 21,
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
                                    LucideIcons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppDimensions.space16),
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
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF047857),
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
                                          borderRadius:
                                              BorderRadius.circular(999),
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
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    // Section 1: Pekerjaan & Penugasan
                    _buildSectionHeader(
                      title: 'Pekerjaan & Penugasan',
                      icon: LucideIcons.briefcase,
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    _buildInfoCard(
                      children: [
                        _buildInfoTile(
                          icon: LucideIcons.building2,
                          label: 'Kantor Cabang',
                          value: branch,
                          textScale: textScale,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: LucideIcons.network,
                          label: 'Departemen',
                          value: department,
                          textScale: textScale,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: LucideIcons.idCard,
                          label: 'Jabatan / Posisi',
                          value: jobPosition,
                          textScale: textScale,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: LucideIcons.clock,
                          label: 'Shift Kerja',
                          value: 'Reguler Operasional',
                          textScale: textScale,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: LucideIcons.mapPin,
                          label: 'Geofence Presensi',
                          value: 'Verifikasi Lokasi Aktif',
                          valueColor: AppColors.statusSuccess,
                          textScale: textScale,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    // Section 2: Kontak & Keamanan Akun
                    _buildSectionHeader(
                      title: 'Kontak & Keamanan Akun',
                      icon: LucideIcons.user,
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    _buildInfoCard(
                      children: [
                        _buildInfoTile(
                          icon: LucideIcons.mail,
                          label: 'Alamat Email',
                          value: userEmail,
                          textScale: textScale,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: LucideIcons.phone,
                          label: 'Nomor Telepon',
                          value: phone,
                          textScale: textScale,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: LucideIcons.users,
                          label: 'Jenis Kelamin',
                          value: gender,
                          textScale: textScale,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: LucideIcons.shieldCheck,
                          label: 'Peran Akun',
                          value: roleLabel,
                          textScale: textScale,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space16),

                    // Section 3: Rekening Penggajian
                    if (auth.bankName != null && auth.bankName!.isNotEmpty) ...[
                      _buildSectionHeader(
                        title: 'Rekening Penggajian',
                        icon: LucideIcons.landmark,
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      _buildInfoCard(
                        children: [
                          _buildInfoTile(
                            icon: LucideIcons.landmark,
                            label: 'Nama Bank',
                            value: auth.bankName!,
                            textScale: textScale,
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: LucideIcons.creditCard,
                            label: 'Nomor Rekening',
                            value: auth.bankAccountNumber ?? '-',
                            textScale: textScale,
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: LucideIcons.user,
                            label: 'Pemilik Rekening',
                            value: auth.bankAccountHolder ?? userName,
                            textScale: textScale,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space16),
                    ],

                    // Section 4: Aplikasi & Dukungan
                    _buildSectionHeader(
                      title: 'Bantuan & Informasi',
                      icon: LucideIcons.info,
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    _buildInfoCard(
                      children: [
                        _buildInfoTile(
                          icon: LucideIcons.headset,
                          label: 'Pusat Bantuan',
                          value: 'Tim HR & Operasional',
                          textScale: textScale,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: LucideIcons.smartphone,
                          label: 'Versi Aplikasi',
                          value: 'HR Hub Mobile v2.4.0',
                          textScale: textScale,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: LucideIcons.shieldCheck,
                          label: 'Status Layanan',
                          value: 'Terkoneksi Aman (SSL)',
                          valueColor: AppColors.statusSuccess,
                          textScale: textScale,
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
                                    LucideIcons.logOut,
                                    color: Color(0xFFB91C1C),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Keluar dari Akun',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFB91C1C),
                                      ),
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
              );
            },
          ),
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
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: -0.1,
              ),
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
    double textScale = 1.0,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppDimensions.minTouchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space12,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final effectiveWidth = constraints.maxWidth / textScale;
            if (effectiveWidth < 250) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 17, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: valueColor ?? AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Row(
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
            );
          },
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
