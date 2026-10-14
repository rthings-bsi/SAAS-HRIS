import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/hr_hub_logo.dart';
import '../../attendance/data/attendance_models.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../attendance/provider/attendance_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../notification/presentation/notification_sheet.dart';
import '../../notification/provider/notification_provider.dart';

String getInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts[0].isEmpty) return 'HR';
  if (parts.length == 1) {
    final first = parts[0];
    return first.substring(0, first.length >= 2 ? 2 : 1).toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

class HomeDashboardView extends ConsumerWidget {
  final void Function(int index) onNavigateToTab;

  const HomeDashboardView({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final userName = auth.userName.trim().isNotEmpty
        ? auth.userName.trim()
        : 'Karyawan';

    final companyName = auth.companyName.isNotEmpty
        ? auth.companyName
        : 'HR Hub Workspace';

    final String userRole;
    if (auth.jobPositionName != null &&
        auth.jobPositionName!.isNotEmpty &&
        auth.departmentName != null &&
        auth.departmentName!.isNotEmpty) {
      userRole = '${auth.jobPositionName} • ${auth.departmentName}';
    } else if (auth.jobPositionName != null &&
        auth.jobPositionName!.isNotEmpty) {
      userRole = auth.jobPositionName!;
    } else if (auth.departmentName != null &&
        auth.departmentName!.isNotEmpty) {
      userRole = auth.departmentName!;
    } else {
      userRole = auth.roleLabel;
    }

    final initials = getInitials(userName);

    final todayAttendanceAsync = ref.watch(todayAttendanceProvider);
    final todayData = todayAttendanceAsync.valueOrNull;

    final shiftName = (todayData != null && todayData.shiftName.isNotEmpty)
        ? todayData.shiftName
        : 'Shift Reguler Pagi';

    final shiftHours = (todayData != null &&
            todayData.startTime.isNotEmpty &&
            todayData.endTime.isNotEmpty)
        ? '${todayData.startTime} - ${todayData.endTime}'
        : '08:00 - 17:00';
    final clockInTime = (todayData != null &&
            todayData.clockInTime != null &&
            todayData.clockInTime!.isNotEmpty)
        ? todayData.clockInTime!
        : '--:--';

    final clockOutTime = (todayData != null &&
            todayData.clockOutTime != null &&
            todayData.clockOutTime!.isNotEmpty)
        ? todayData.clockOutTime!
        : '--:--';

    final actionState = ref.watch(attendanceActionProvider);
    final hasClockedIn = todayData != null && todayData.hasClockedIn;
    final hasClockedOut = todayData != null && todayData.hasClockedOut;
    final isCompleted = hasClockedIn && hasClockedOut;
    final isClockInAction = !hasClockedIn;
    final unreadNotificationCount = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;

    // Listen for attendance actions feedback (Clock In / Clock Out)
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
      } else if (next.successMessage != null && next.successMessage!.isNotEmpty) {
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

    final todayFormatted =
        DateFormat('E, dd MMM yyyy', 'en_US').format(DateTime.now());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 1. Header Bar: Brand Mark + HR Hub + SPINDO Badge + Search + Notifications
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Squircle Brand Mark
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const HrHubLogo(size: 24),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'HR Hub',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0B2545),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFBBF7D0),
                                    ),
                                  ),
                                  child: const Text(
                                    'SPINDO',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF15803D),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              companyName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF475569),
                          size: 22,
                        ),
                        tooltip: 'Pencarian',
                        onPressed: () => _showSearchDialog(context),
                      ),
                      IconButton(
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF475569),
                              size: 22,
                            ),
                            if (unreadNotificationCount > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 10,
                                    minHeight: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        tooltip: 'Notifikasi',
                        onPressed: () => NotificationSheet.show(context, onNavigateToTab: onNavigateToTab),
                      ),
                    ],
                  ),
                ),

                // 2. Profile Welcome Row
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.space16,
                    0,
                    AppDimensions.space16,
                    14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0B2545),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userRole,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Shift & Attendance Card
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                      // Header Row: Today Date + Shift Name & Hours + Edit Icon
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Today ($todayFormatted)',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Shift: $shiftName [$shiftHours]',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => _showShiftScheduleDialog(
                                context,
                                shiftName,
                                shiftHours,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // Two-Column Attendance Info: Start Time & End Time
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Column 1: Start Time
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: AppColors.successBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.successBorder,
                                        width: 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.login_rounded,
                                      size: 16,
                                      color: AppColors.successText,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Clock In',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              clockInTime,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            const Text(
                                              'WIB',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          hasClockedIn
                                              ? (todayData.isLate == true
                                                  ? '+${todayData.lateMinutes}m terlambat'
                                                  : 'Tepat Waktu')
                                              : 'Belum presensi',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: hasClockedIn
                                                ? (todayData.isLate == true
                                                    ? AppColors.warningText
                                                    : AppColors.successText)
                                                : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 44,
                              width: 1,
                              color: const Color(0xFFF1F5F9),
                            ),
                            // Column 2: End Time
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFFDE68A),
                                        width: 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      size: 16,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Clock Out',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              clockOutTime,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            const Text(
                                              'WIB',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          hasClockedOut
                                              ? 'Selesai Kerja'
                                              : (hasClockedIn
                                                  ? 'Sedang Bekerja'
                                                  : 'Belum jam pulang'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: hasClockedOut
                                                ? AppColors.successText
                                                : (hasClockedIn
                                                    ? AppColors.infoText
                                                    : const Color(0xFF94A3B8)),
                                          ),
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
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // Primary Presensi Action Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                        child: actionState.isLoading
                            ? Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.actionAccent,
                                    ),
                                  ),
                                ),
                              )
                            : isCompleted
                                ? Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: AppColors.successBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.successBorder),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.successText,
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Presensi Hari Ini Selesai',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.successText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await ref
                                            .read(attendanceActionProvider.notifier)
                                            .recordAttendance(
                                              isClockIn: isClockInAction,
                                            );
                                        ref.invalidate(todayAttendanceProvider);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.actionAccent,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                      ),
                                      icon: Icon(
                                        isClockInAction
                                            ? Icons.login_rounded
                                            : Icons.logout_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        isClockInAction
                                            ? 'Clock In Sekarang'
                                            : 'Clock Out Sekarang',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                      ),

                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // Card Footer: Actions Row (Kamera & GPS + View Detail)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const AttendanceScreen(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        size: 16,
                                        color: AppColors.actionAccent,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Kamera & GPS',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.actionAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 18,
                              width: 1,
                              color: const Color(0xFFE2E8F0),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => _showAttendanceDetailSheet(
                                  context,
                                  shiftName,
                                  shiftHours,
                                  clockInTime,
                                  clockOutTime,
                                  todayData,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Rincian Shift',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.keyboard_arrow_right_rounded,
                                        size: 16,
                                        color: Color(0xFF64748B),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Favorite Menu Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                    vertical: 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Favorite Menu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkPrimary,
                            ),
                          ),
                          InkWell(
                            onTap: () => _showEditFavoriteDialog(context),
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.actionAccent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 4-column Grid matching the screenshot
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.74,
                        children: [
                          _FavoriteMenuItem(
                            label: 'Pengajuan\nLembur',
                            icon: Icons.more_time_rounded,
                            bgColor: AppColors.emeraldTint,
                            iconColor: AppColors.actionAccent,
                            onTap: () => onNavigateToTab(1),
                          ),
                          _FavoriteMenuItem(
                            label: 'Pengajuan\nCuti',
                            icon: Icons.calendar_month_rounded,
                            bgColor: AppColors.menuCyanBg,
                            iconColor: AppColors.menuCyanIcon,
                            onTap: () => onNavigateToTab(2),
                          ),
                          _FavoriteMenuItem(
                            label: 'Slip Gaji\nKaryawan',
                            icon: Icons.receipt_long_rounded,
                            bgColor: AppColors.menuCyanBg,
                            iconColor: AppColors.menuCyanIcon,
                            onTap: () => onNavigateToTab(3),
                          ),
                          _FavoriteMenuItem(
                            label: 'Presensi\nKamera GPS',
                            icon: Icons.camera_alt_rounded,
                            bgColor: AppColors.menuCyanBg,
                            iconColor: AppColors.menuCyanIcon,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AttendanceScreen(),
                                ),
                              );
                            },
                          ),
                          _FavoriteMenuItem(
                            label: 'Tugas Luar\n(On Duty)',
                            icon: Icons.business_center_rounded,
                            bgColor: AppColors.menuCyanBg,
                            iconColor: AppColors.menuCyanIcon,
                            onTap: () => _showOnDutyRequestDialog(context),
                          ),
                          _FavoriteMenuItem(
                            label: 'Profil &\nData Diri',
                            icon: Icons.badge_rounded,
                            bgColor: AppColors.menuGreenBg,
                            iconColor: AppColors.menuGreenIcon,
                            onTap: () => onNavigateToTab(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 5. Company Information Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Company Information',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkPrimary,
                            ),
                          ),
                          InkWell(
                            onTap: () => _showCompanyInfoListDialog(context),
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Text(
                                'See All',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.actionAccent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => _showCompanyInfoDetailDialog(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.emeraldTint,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.description_rounded,
                                      color: AppColors.actionAccent,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Pedoman & Tata Tertib Kerja Karyawan',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.inkPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          'Dokumen resmi HRD untuk keselamatan kerja & SOP operasional perusahaan.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 84),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Anti-Slop Interactive Actions & Modals ---

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.cardBorderRadius,
        ),
        title: const Text(
          'Pencarian Layanan HR',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.inkPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Cari menu, dokumen, atau shift...',
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Akses Cepat:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Presensi Kerja'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onNavigateToTab(3);
                  },
                ),
                ActionChip(
                  label: const Text('Pengajuan Cuti'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onNavigateToTab(1);
                  },
                ),
                ActionChip(
                  label: const Text('Slip Gaji'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onNavigateToTab(2);
                  },
                ),
                ActionChip(
                  label: const Text('Data Pribadi'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onNavigateToTab(4);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }


  void _showShiftScheduleDialog(
    BuildContext context,
    String shiftName,
    String shiftHours,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.cardBorderRadius,
        ),
        title: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.actionAccent),
            const SizedBox(width: 8),
            const Text(
              'Rincian Shift Kerja',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kode Shift: $shiftName',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Jam Operasional: $shiftHours',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              'Toleransi Keterlambatan: 15 Menit',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'Jika terjadi ketidaksesuaian jadwal shift, hubungi supervisor atau supervisor HR bagian penjadwalan.',
              style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.actionAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDetailSheet(
    BuildContext context,
    String shiftName,
    String shiftHours,
    String clockIn,
    String clockOut,
    TodayAttendanceData? todayData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detail Presensi Hari Ini',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _detailRow('Jadwal Shift', '$shiftName ($shiftHours)'),
            _detailRow('Jam Masuk (Clock-In)', clockIn),
            _detailRow('Jam Pulang (Clock-Out)', clockOut),
            _detailRow(
              'Status Hadir',
              todayData?.status ?? (clockIn != '--:--' ? 'Hadir' : 'Belum Hadir'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text(
                  'Buka Presensi Kerja (Kamera & GPS)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  onNavigateToTab(3);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.inkPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditFavoriteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.cardBorderRadius,
        ),
        title: const Text('Atur Menu Favorit'),
        content: const Text(
          'Menu favorit dapat disesuaikan dengan kebutuhan harian Anda. Shortcut terpilih saat ini: Overtime Request, Leave Request, On Duty Request, Overtime Employee Report, On Duty Report, dan Personal Data.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.actionAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  void _showOnDutyRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.cardBorderRadius,
        ),
        title: const Text(
          'Pengajuan Dinas Luar (On Duty)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Dinas luar digunakan saat penugasan kerja di luar area perimeter kantor/pabrik utama. Permintaan Anda akan diteruskan ke atasan langsung.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.actionAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Formulir dinas luar dibuka.'),
                  backgroundColor: AppColors.actionAccent,
                ),
              );
            },
            child: const Text('Buat Surat Tugas'),
          ),
        ],
      ),
    );
  }

  void _showCompanyInfoListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.cardBorderRadius,
        ),
        title: const Text(
          'Daftar Informasi Perusahaan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description, color: AppColors.actionAccent),
              title: const Text('Pedoman & Tata Tertib Kerja Karyawan', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Versi 2026 / HR Corporate', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _showCompanyInfoDetailDialog(context);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.health_and_safety, color: AppColors.actionAccent),
              title: const Text('Prosedur K3 & Keselamatan Operasional', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Panduan APD & Area Produksi', style: TextStyle(fontSize: 11)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showCompanyInfoDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.cardBorderRadius,
        ),
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: AppColors.actionAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pedoman & Tata Tertib Kerja',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan Regulasi Kerja:',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              SizedBox(height: 6),
              Text(
                '1. Seluruh karyawan wajib melakukan pencatatan presensi masuk dan pulang sesuai shift kerja yang ditetapkan.\n'
                '2. Keterlambatan melebihi toleransi wajib menyertakan konfirmasi supervisor.\n'
                '3. Penggunaan APD (Alat Pelindung Diri) wajib dipatuhi di area operasional pabrik dan gudang.\n'
                '4. Pengajuan izin dan cuti dilakukan selambat-lambatnya 3 hari kerja sebelum tanggal pelaksanaan.',
                style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.inkPrimary),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.actionAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }
}

class _FavoriteMenuItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _FavoriteMenuItem({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.inkPrimary,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
