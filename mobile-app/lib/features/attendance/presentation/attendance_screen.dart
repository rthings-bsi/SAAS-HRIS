import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/hr_hub_logo.dart';
import '../../auth/provider/auth_provider.dart';
import '../data/attendance_models.dart';
import '../provider/attendance_provider.dart';
import 'history_screen.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

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
              Text('Presensi Kerja'),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: AppEmptyState(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Presensi Khusus Karyawan',
              description:
                  'Akun Anda (${auth.roleLabel}) terdaftar sebagai pengelola tanpa profil karyawan operasional. Aplikasi mobile diperuntukkan bagi karyawan untuk melakukan pencatatan kehadiran. Silakan gunakan Web Admin untuk memonitor presensi tim atau ganti ke akun karyawan.',
              actionText: 'Keluar & Ganti Akun',
              onAction: () => ref.read(authStateProvider.notifier).logout(),
            ),
          ),
        ),
      );
    }

    final todayAsync = ref.watch(todayAttendanceProvider);
    final historyAsync = ref.watch(attendanceHistoryProvider);
    final actionState = ref.watch(attendanceActionProvider);
    String todayFormatted;
    try {
      todayFormatted =
          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    } catch (_) {
      todayFormatted =
          DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    // Listen for attendance action feedback
    ref.listen<AttendanceActionState>(attendanceActionProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.dangerText,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (next.successMessage != null &&
          next.successMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.successText,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.canvasLight,
      appBar: AppBar(
        title: const Row(
          children: [
            HrHubLogo(size: 24),
            SizedBox(width: 10),
            Text('Presensi Kerja'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Kehadiran',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayAttendanceProvider);
          ref.invalidate(attendanceHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.space12),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space12,
                  vertical: AppDimensions.space8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
                  border: Border.all(
                    color: AppColors.hairline,
                    width: AppDimensions.borderWidth,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 15,
                      color: AppColors.actionAccent,
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    Text(
                      todayFormatted,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.inkPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Today's Shift Card & Status
              todayAsync.when(
                loading: () => const Column(
                  children: [
                    AppSkeleton(height: 100),
                    SizedBox(height: AppDimensions.space12),
                    AppSkeleton(height: 130),
                  ],
                ),
                error: (error, _) => AppErrorState(
                  isCard: true,
                  title: 'Gagal Memuat Status Presensi',
                  message: error is ApiException
                      ? error.userFriendlyMessage
                      : error.toString().replaceFirst('Exception: ', ''),
                  retryText: 'Coba Lagi',
                  onRetry: () => ref.invalidate(todayAttendanceProvider),
                ),
                data: (data) {
                  final badge = data.badgeStatus;
                  final hasClockedIn = data.hasClockedIn;
                  final hasClockedOut = data.hasClockedOut;
                  final isCompleted = hasClockedIn && hasClockedOut;
                  final isClockInAction = !hasClockedIn;

                  final buttonText = isCompleted
                      ? 'Presensi Selesai'
                      : (isClockInAction
                          ? 'Clock In Sekarang'
                          : 'Clock Out Sekarang');

                  final buttonIcon = isCompleted
                      ? Icons.check_circle_outline_rounded
                      : (isClockInAction
                          ? Icons.login_rounded
                          : Icons.logout_rounded);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Enhanced Shift Card
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.space16),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppDimensions.space8),
                                  decoration: BoxDecoration(
                                    color: AppColors.orangeTint,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.orangeBorder,
                                      width: AppDimensions.borderWidth,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.access_time_filled_rounded,
                                    size: 18,
                                    color: AppColors.actionAccent,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.space12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.shiftName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.inkPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Jadwal Shift Kerja',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.space12),
                            Container(
                              padding: const EdgeInsets.all(AppDimensions.space12),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF1F5F9),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _ShiftDetailItem(
                                      icon: Icons.login_rounded,
                                      label: 'Jam Masuk',
                                      value: data.startTime,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 32,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  const SizedBox(width: AppDimensions.space8),
                                  Expanded(
                                    child: _ShiftDetailItem(
                                      icon: Icons.logout_rounded,
                                      label: 'Jam Pulang',
                                      value: data.endTime,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 32,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  const SizedBox(width: AppDimensions.space8),
                                  Expanded(
                                    child: _ShiftDetailItem(
                                      icon: Icons.timelapse_rounded,
                                      label: 'Toleransi',
                                      value: '${data.lateToleranceMinutes} Menit',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space12),

                      // Attendance Status Card
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.space16),
                        decoration: BoxDecoration(
                          color: hasClockedIn && !hasClockedOut
                              ? AppColors.orangeTint
                              : AppColors.canvasLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: hasClockedIn && !hasClockedOut
                                ? AppColors.orangeBorder
                                : const Color(0xFFE2E8F0),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.fingerprint_rounded,
                                      size: 18,
                                      color: AppColors.actionAccent,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Status Kehadiran',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.inkPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: AppDimensions.space4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badge.backgroundColor,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: badge.borderColor,
                                      width: AppDimensions.borderWidth,
                                    ),
                                  ),
                                  child: Text(
                                    badge.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: badge.textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.space16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimensions.space12,
                                      vertical: AppDimensions.space8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasClockedIn
                                          ? AppColors.orangeTint
                                          : AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: hasClockedIn
                                            ? AppColors.orangeBorder
                                            : const Color(0xFFE2E8F0),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_circle_down_rounded,
                                              size: 14,
                                              color: AppColors.successText,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Waktu Masuk',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.inkMuted,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppDimensions.space4),
                                        Text(
                                          data.clockInTime ?? '--:--',
                                          style: AppTextStyle.time(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.space12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppDimensions.space12,
                                      vertical: AppDimensions.space8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: hasClockedOut
                                          ? AppColors.orangeTint
                                          : AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: hasClockedOut
                                            ? AppColors.orangeBorder
                                            : const Color(0xFFE2E8F0),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.arrow_circle_up_rounded,
                                              size: 14,
                                              color: AppColors.actionAccent,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Waktu Pulang',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.inkMuted,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppDimensions.space4),
                                        Text(
                                          data.clockOutTime ?? '--:--',
                                          style: AppTextStyle.time(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.space12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.space8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFF1F5F9),
                                  width: 1.0,
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.verified_user_rounded,
                                    size: 14,
                                    color: AppColors.successText,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Validasi radius kantor & foto swafoto aktif',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space16),

                      // Clock-In / Clock-Out primary action button
                      AppButton(
                        text: buttonText,
                        icon: Icon(
                          buttonIcon,
                          size: 18,
                          color: isCompleted
                              ? AppColors.inkMuted
                              : AppColors.canvasLight,
                        ),
                        isLoading: actionState.isLoading,
                        onPressed: isCompleted
                            ? null
                            : () async {
                                await ref
                                    .read(attendanceActionProvider.notifier)
                                    .recordAttendance(
                                      isClockIn: isClockInAction,
                                    );
                              },
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: AppDimensions.space24),

              // History Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Presensi Bulan Ini',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppDimensions.minTouchTarget,
                      minHeight: AppDimensions.minTouchTarget,
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HistoryScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(AppDimensions.radiusInput),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimensions.space8,
                            vertical: AppDimensions.space4,
                          ),
                          child: Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.actionAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space12),

              historyAsync.when(
                loading: () => Column(
                  children: List.generate(
                    3,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: AppDimensions.space8),
                      child: AppSkeleton(height: 64),
                    ),
                  ),
                ),
                error: (error, _) => AppErrorState(
                  isCard: true,
                  title: 'Gagal Memuat Riwayat',
                  message: 'Gagal memuat riwayat kehadiran.',
                  retryText: 'Coba Lagi',
                  onRetry: () => ref.invalidate(attendanceHistoryProvider),
                ),
                data: (history) {
                  if (history.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.history_rounded,
                      title: 'Belum Ada Riwayat',
                      description: 'Belum ada riwayat kehadiran tercatat.',
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length > 5 ? 5 : history.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppDimensions.space8),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final badge = item.badgeStatus;
                      final inTime = item.clockIn ?? '--:--';
                      final outTime = item.clockOut ?? '--:--';

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space16,
                          vertical: AppDimensions.space12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.canvasLight,
                          borderRadius: BorderRadius.circular(14),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.date,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.space4),
                                Row(
                                  children: [
                                    const Text(
                                      'Masuk: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                    Text(
                                      inTime,
                                      style: AppTextStyle.time(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Text(
                                      ' / Pulang: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.inkMuted,
                                      ),
                                    ),
                                    Text(
                                      outTime,
                                      style: AppTextStyle.time(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: AppDimensions.space4,
                              ),
                              decoration: BoxDecoration(
                                color: badge.backgroundColor,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: badge.borderColor,
                                  width: AppDimensions.borderWidth,
                                ),
                              ),
                              child: Text(
                                badge.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: badge.textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ShiftDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.inkMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTextStyle.time(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
