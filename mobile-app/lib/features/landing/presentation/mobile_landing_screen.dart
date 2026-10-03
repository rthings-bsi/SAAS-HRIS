import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/hr_hub_logo.dart';
import '../../auth/presentation/login_screen.dart';

class MobileLandingScreen extends StatelessWidget {
  const MobileLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space20,
                vertical: AppDimensions.space12,
              ),
              decoration: const BoxDecoration(
                color: AppColors.canvasLight,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderNeutral,
                    width: AppDimensions.borderWidth,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const HrHubLogo(
                    size: 32,
                    showText: true,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space8,
                      vertical: AppDimensions.space4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orangeTint,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.orangeBorder,
                        width: AppDimensions.borderWidth,
                      ),
                    ),
                    child: const Text(
                      'Mobile App',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.actionAccent,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space20,
                  vertical: AppDimensions.space24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tagline Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space12,
                            vertical: AppDimensions.space4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.orangeTint,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.orangeBorder,
                              width: AppDimensions.borderWidth,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: AppColors.actionAccent,
                              ),
                              SizedBox(width: AppDimensions.space4),
                              Text(
                                'SaaS HRIS Indonesia • Mobile Companion',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.actionAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),

                        // Main Headline
                        const Text(
                          'Presensi & Administrasi Karyawan dalam Genggaman',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkPrimary,
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space12),

                        // Subtitle
                        const Text(
                          'Solusi terpadu untuk staf lapangan dan kantor: presensi GPS geofence anti-mock, swafoto kamera aktif, cek jadwal shift, permohonan cuti, dan unduh slip gaji digital resmi.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.inkMuted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space24),

                        // Live Telemetry Showcase Card
                        Container(
                          width: double.infinity,
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
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.radar_rounded,
                                        size: 16,
                                        color: AppColors.actionAccent,
                                      ),
                                      SizedBox(width: AppDimensions.space8),
                                      Text(
                                        'RADAR PRESENSI AKTIF',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.inkPrimary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimensions.space8,
                                      vertical: AppDimensions.space4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.successBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: AppColors.successBorder,
                                        width: AppDimensions.borderWidth,
                                      ),
                                    ),
                                    child: const Text(
                                      'Akurasi ±3.2m',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.successText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppDimensions.space12),
                              const Divider(height: 1, color: AppColors.surfaceMuted),
                              const SizedBox(height: AppDimensions.space12),
                              _buildTelemetryRow(
                                icon: Icons.location_on_rounded,
                                label: 'Kantor Cabang Terdekat',
                                value: 'Sudirman Central (Radius 50m)',
                              ),
                              const SizedBox(height: AppDimensions.space8),
                              _buildTelemetryRow(
                                icon: Icons.security_rounded,
                                label: 'Status Deteksi Fake GPS',
                                value: 'Hardware Anti-Mock Level 3 (Aman)',
                                valueColor: AppColors.successText,
                              ),
                              const SizedBox(height: AppDimensions.space8),
                              _buildTelemetryRow(
                                icon: Icons.camera_front_rounded,
                                label: 'Sensor Swafoto Wajah',
                                value: 'Kamera Native Aktif (Anti-Galeri)',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space24),

                        // Section Heading
                        const Text(
                          'Empat Pilar Layanan Mandiri Karyawan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),

                        // 4 Core Feature Cards
                        _buildFeatureCard(
                          icon: Icons.my_location_rounded,
                          iconColor: AppColors.actionAccent,
                          iconBg: AppColors.orangeTint,
                          badgeText: 'GPS & Swafoto',
                          title: 'Presensi Anti-Mock Ketat',
                          description:
                              'Karyawan clock-in tepat saat berada di area kantor cabang. Sistem menolak manipulasi koordinat Fake GPS dan rooting.',
                        ),
                        const SizedBox(height: AppDimensions.space12),

                        _buildFeatureCard(
                          icon: Icons.access_time_rounded,
                          iconColor: AppColors.info,
                          iconBg: AppColors.infoBg,
                          badgeText: 'Shift Operasional',
                          title: 'Jadwal Kerja Bergilir & Denda',
                          description:
                              'Pantau shift pagi, siang, atau malam. Jam toleransi dan perhitungan denda menit telat transparan tanpa sengketa.',
                        ),
                        const SizedBox(height: AppDimensions.space12),

                        _buildFeatureCard(
                          icon: Icons.event_available_rounded,
                          iconColor: AppColors.warning,
                          iconBg: AppColors.warningBg,
                          badgeText: 'Cuti & Izin',
                          title: 'Pengajuan Cuti & Lampiran Sakit',
                          description:
                              'Unggah surat keterangan dokter secara langsung dari ponsel. Kuota cuti terpotong otomatis setelah manajer menyetujui.',
                        ),
                        const SizedBox(height: AppDimensions.space12),

                        _buildFeatureCard(
                          icon: Icons.receipt_long_rounded,
                          iconColor: AppColors.success,
                          iconBg: AppColors.successBg,
                          badgeText: 'PP No. 44/2015',
                          title: 'Slip Gaji Digital Resmi (PDF)',
                          description:
                              'Akses rincian gaji pokok, tunjangan, potongan BPJS TK (3%) dan BPJS Kes (1%), serta cetak format PDF resmi.',
                        ),
                        const SizedBox(height: AppDimensions.space24),

                        // Security & Privacy Box
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.space16),
                          decoration: BoxDecoration(
                            color: AppColors.canvasLight,
                            borderRadius: AppDimensions.cardBorderRadius,
                            border: Border.all(
                              color: AppColors.borderNeutral,
                              width: AppDimensions.borderWidth,
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                                color: AppColors.actionAccent,
                              ),
                              SizedBox(width: AppDimensions.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Multi-Tenancy & Isolasi Data Perusahaan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.inkPrimary,
                                      ),
                                    ),
                                    SizedBox(height: AppDimensions.space4),
                                    Text(
                                      'Seluruh riwayat presensi dan berkas medis dilindungi token Laravel Sanctum terenkripsi serta terisolasi per ID perusahaan.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.inkMuted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space32),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Fixed Bottom CTA Dock
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space20,
                vertical: AppDimensions.space16,
              ),
              decoration: const BoxDecoration(
                color: AppColors.canvasLight,
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderNeutral,
                    width: AppDimensions.borderWidth,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      text: 'Masuk ke Portal Karyawan',
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppColors.canvasLight,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTelemetryRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.inkMuted),
        const SizedBox(width: AppDimensions.space8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.inkMuted,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.inkPrimary,
          ),
        ),
      ],
    );
  }

  static Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String badgeText,
    required String title,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.canvasLight,
        borderRadius: AppDimensions.cardBorderRadius,
        border: Border.all(
          color: AppColors.borderNeutral,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.borderNeutral,
                          width: AppDimensions.borderWidth,
                        ),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
