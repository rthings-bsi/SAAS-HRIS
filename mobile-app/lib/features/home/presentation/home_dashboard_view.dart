import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_phosphor_icons.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/hr_hub_logo.dart';
import '../../../core/widgets/ios_glass_menu_icon.dart';
import '../../attendance/data/attendance_models.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../attendance/presentation/history_screen.dart';
import '../../attendance/provider/attendance_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../notification/presentation/notification_sheet.dart';
import '../../notification/provider/notification_provider.dart';

class FavoriteMenuDefinition {
  final String id;
  final String gridLabel;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const FavoriteMenuDefinition({
    required this.id,
    required this.gridLabel,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

const List<FavoriteMenuDefinition> kAllFavoriteMenus = [
  FavoriteMenuDefinition(
    id: 'overtime',
    gridLabel: 'Pengajuan\nLembur',
    title: 'Pengajuan Lembur',
    subtitle: 'Ajukan dan pantau jam lembur kerja',
    icon: PhosphorIconsFill.clockClockwise,
    bgColor: Color(0xFFDBEAFE),
    iconColor: Color(0xFF1D4ED8),
  ),
  FavoriteMenuDefinition(
    id: 'leave',
    gridLabel: 'Pengajuan\nCuti',
    title: 'Pengajuan Cuti & Izin',
    subtitle: 'Kelola cuti tahunan dan izin karyawan',
    icon: PhosphorIconsFill.calendarCheck,
    bgColor: Color(0xFFD1FAE5),
    iconColor: Color(0xFF059669),
  ),
  FavoriteMenuDefinition(
    id: 'payroll',
    gridLabel: 'Slip Gaji\nKaryawan',
    title: 'Slip Gaji Karyawan',
    subtitle: 'Rincian gaji dan potongan bulanan',
    icon: PhosphorIconsFill.receipt,
    bgColor: Color(0xFFCCFBF1),
    iconColor: Color(0xFF0D9488),
  ),
  FavoriteMenuDefinition(
    id: 'attendance_camera',
    gridLabel: 'Presensi\nKamera GPS',
    title: 'Presensi Kamera GPS',
    subtitle: 'Rekam kehadiran swafoto & lokasi',
    icon: PhosphorIconsFill.camera,
    bgColor: Color(0xFFE0F2FE),
    iconColor: Color(0xFF0284C7),
  ),
  FavoriteMenuDefinition(
    id: 'on_duty',
    gridLabel: 'Tugas Luar\n(On Duty)',
    title: 'Tugas Luar (On Duty)',
    subtitle: 'Surat tugas dinas di luar area kantor',
    icon: PhosphorIconsFill.briefcase,
    bgColor: Color(0xFFFFEDD5),
    iconColor: Color(0xFFEA580C),
  ),
  FavoriteMenuDefinition(
    id: 'profile',
    gridLabel: 'Profil &\nData Diri',
    title: 'Profil & Data Diri',
    subtitle: 'Informasi kepegawaian dan akun',
    icon: PhosphorIconsFill.identificationCard,
    bgColor: Color(0xFFE2E8F0),
    iconColor: Color(0xFF1E293B),
  ),
  FavoriteMenuDefinition(
    id: 'attendance_history',
    gridLabel: 'Riwayat\nPresensi',
    title: 'Riwayat Presensi',
    subtitle: 'Daftar jam masuk dan pulang harian',
    icon: PhosphorIconsFill.clockCounterClockwise,
    bgColor: Color(0xFFE0E7FF),
    iconColor: Color(0xFF4338CA),
  ),
  FavoriteMenuDefinition(
    id: 'shift_schedule',
    gridLabel: 'Jadwal\nShift Kerja',
    title: 'Jadwal Shift Kerja',
    subtitle: 'Jam operasional dan toleransi shift',
    icon: PhosphorIconsFill.calendarDots,
    bgColor: Color(0xFFCFFAFE),
    iconColor: Color(0xFF0891B2),
  ),
  FavoriteMenuDefinition(
    id: 'company_policy',
    gridLabel: 'Pedoman &\nRegulasi',
    title: 'Pedoman & Regulasi',
    subtitle: 'Tata tertib kerja dan prosedur K3',
    icon: PhosphorIconsFill.bookOpenText,
    bgColor: Color(0xFFDBEAFE),
    iconColor: Color(0xFF1E3A8A),
  ),
];

const List<String> kDefaultFavoriteMenuIds = [
  'overtime',
  'leave',
  'payroll',
  'attendance_camera',
  'on_duty',
  'profile',
];

class FavoriteMenuNotifier extends StateNotifier<List<String>> {
  static const String _storageKey = 'hr_hub_favorite_menu_ids_v1';

  FavoriteMenuNotifier() : super(kDefaultFavoriteMenuIds) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_storageKey);
      if (saved != null && saved.isNotEmpty) {
        final validIds = kAllFavoriteMenus.map((m) => m.id).toSet();
        final filtered = saved.where(validIds.contains).toList();
        if (filtered.isNotEmpty) {
          state = filtered;
        }
      }
    } catch (_) {
      // Fallback to default in test/isolated environments
    }
  }

  Future<void> updateFavorites(List<String> newIds) async {
    if (newIds.isEmpty) return;
    state = List<String>.unmodifiable(newIds);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, state);
    } catch (_) {}
  }

  Future<void> resetToDefault() async {
    await updateFavorites(kDefaultFavoriteMenuIds);
  }
}

final favoriteMenuIdsProvider =
    StateNotifierProvider<FavoriteMenuNotifier, List<String>>((ref) {
  return FavoriteMenuNotifier();
});

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
    final favoriteMenuIds = ref.watch(favoriteMenuIdsProvider);
    final activeFavoriteMenus = favoriteMenuIds
        .map((id) => kAllFavoriteMenus.where((m) => m.id == id).firstOrNull)
        .whereType<FavoriteMenuDefinition>()
        .toList();

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
            child: RefreshIndicator(
              color: AppColors.actionAccent,
              onRefresh: () async {
                ref.invalidate(todayAttendanceProvider);
                ref.invalidate(unreadNotificationCountProvider);
                await Future.wait<void>([
                  ref
                      .read(todayAttendanceProvider.future)
                      .then((_) {})
                      .catchError((_) {}),
                  ref
                      .read(unreadNotificationCountProvider.future)
                      .then((_) {})
                      .catchError((_) {}),
                ]);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 2,
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
                          LucideIcons.search,
                          color: Color(0xFF475569),
                          size: 20,
                        ),
                        tooltip: 'Pencarian',
                        onPressed: () => _showSearchDialog(context),
                      ),
                      IconButton(
                        key: const Key('home_notification_bell_btn'),
                        constraints: const BoxConstraints(
                          minWidth: AppDimensions.minTouchTarget,
                          minHeight: AppDimensions.minTouchTarget,
                        ),
                        icon: Semantics(
                          label: unreadNotificationCount > 0
                              ? 'Notifikasi, $unreadNotificationCount belum dibaca'
                              : 'Notifikasi',
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(
                                LucideIcons.bell,
                                color: Color(0xFF475569),
                                size: 20,
                              ),
                              if (unreadNotificationCount > 0)
                                Positioned(
                                  top: -6,
                                  right: -8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      unreadNotificationCount > 99
                                          ? '99+'
                                          : '$unreadNotificationCount',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        tooltip: unreadNotificationCount > 0
                            ? 'Notifikasi ($unreadNotificationCount belum dibaca)'
                            : 'Notifikasi',
                        onPressed: () async {
                          await NotificationSheet.show(
                            context,
                            onNavigateToTab: onNavigateToTab,
                          );
                          ref.invalidate(unreadNotificationCountProvider);
                        },
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
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDBEAFE),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
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
                                fontWeight: FontWeight.w500,
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

                // 3. Shift & Attendance Card (single surface, flush header + sections)
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
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (context, cardConstraints) {
                        final double hPad;
                        final double vPad;
                        if (cardConstraints.maxWidth < 310) {
                          hPad = 12;
                          vPad = 12;
                        } else if (cardConstraints.maxWidth < 470) {
                          hPad = 16;
                          vPad = 14;
                        } else {
                          hPad = 20;
                          vPad = 16;
                        }

                        final textScale = MediaQuery.textScalerOf(context)
                            .scale(1.0)
                            .clamp(1.0, 2.0);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Zone 1: Flush Interactive Shift Header
                            Semantics(
                              button: true,
                              label: 'Lihat rincian shift hari ini',
                              child: InkWell(
                                onTap: () => _showShiftScheduleDialog(
                                  context,
                                  shiftName,
                                  shiftHours,
                                ),
                                hoverColor: const Color(0xFFF8FAFC),
                                splashColor: const Color(0xFFE2E8F0),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: AppDimensions.minTouchTarget,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: hPad,
                                      vertical: vPad,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            LucideIcons.calendarDays,
                                            size: 18,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Today ($todayFormatted)',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Shift: $shiftName [$shiftHours]',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF475569),
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          LucideIcons.chevronRight,
                                          size: 18,
                                          color: Color(0xFF64748B),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF1F5F9),
                            ),

                            // Zone 2: Attendance Metrics & Primary CTA
                            Padding(
                              padding: EdgeInsets.all(hPad),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  LayoutBuilder(
                                    builder: (context, attendanceConstraints) {
                                      final effectiveWidth =
                                          attendanceConstraints.maxWidth /
                                              textScale;
                                      final stackAttendance =
                                          effectiveWidth < 280;

                                      final clockInColumn = Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              LucideIcons.logIn,
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
                                                    color: Color(0xFF475569),
                                                  ),
                                                ),
                                                const SizedBox(height: 1),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .baseline,
                                                  textBaseline:
                                                      TextBaseline.alphabetic,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        clockInTime,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color:
                                                              Color(0xFF0F172A),
                                                          fontFamily:
                                                              'monospace',
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    const Text(
                                                      'WIB',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  hasClockedIn
                                                      ? (todayData.isLate ==
                                                              true
                                                          ? '+${todayData.lateMinutes}m terlambat'
                                                          : 'Tepat Waktu')
                                                      : 'Belum presensi',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: hasClockedIn
                                                        ? (todayData.isLate ==
                                                                true
                                                            ? AppColors
                                                                .warningText
                                                            : AppColors
                                                                .successText)
                                                        : AppColors.successText,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );

                                      final clockOutColumn = Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDBEAFE),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              LucideIcons.logOut,
                                              size: 16,
                                              color: Color(0xFF2563EB),
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
                                                    color: Color(0xFF475569),
                                                  ),
                                                ),
                                                const SizedBox(height: 1),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .baseline,
                                                  textBaseline:
                                                      TextBaseline.alphabetic,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        clockOutTime,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color:
                                                              Color(0xFF0F172A),
                                                          fontFamily:
                                                              'monospace',
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 2),
                                                    const Text(
                                                      'WIB',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Color(0xFF64748B),
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
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: hasClockedOut
                                                        ? AppColors.successText
                                                        : (hasClockedIn
                                                            ? AppColors.infoText
                                                            : const Color(
                                                                0xFF64748B)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );

                                      if (stackAttendance) {
                                        return Column(
                                          children: [
                                            clockInColumn,
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 10,
                                              ),
                                              child: Divider(
                                                height: 1,
                                                color: Color(0xFFE2E8F0),
                                              ),
                                            ),
                                            clockOutColumn,
                                          ],
                                        );
                                      }

                                      return Row(
                                        children: [
                                          Expanded(child: clockInColumn),
                                          const SizedBox(width: 10),
                                          Container(
                                            height: 44,
                                            width: 1,
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(child: clockOutColumn),
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(height: vPad),

                                  // Primary Presensi Action Button
                                  if (actionState.isLoading)
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight:
                                            AppDimensions.minTouchTarget,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFCBD5E1),
                                          ),
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
                                      ),
                                    )
                                  else if (isCompleted)
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight:
                                            AppDimensions.minTouchTarget,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.successBg,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.successBorder,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              LucideIcons.circleCheck,
                                              color: AppColors.successText,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'Presensi Hari Ini Selesai',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.successText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight:
                                            AppDimensions.minTouchTarget,
                                        minWidth: double.infinity,
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          await ref
                                              .read(
                                                attendanceActionProvider
                                                    .notifier,
                                              )
                                              .recordAttendance(
                                                isClockIn: isClockInAction,
                                              );
                                          ref.invalidate(
                                            todayAttendanceProvider,
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.actionAccent,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                        ),
                                        icon: Icon(
                                          isClockInAction
                                              ? LucideIcons.logIn
                                              : LucideIcons.logOut,
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
                                ],
                              ),
                            ),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFF1F5F9),
                            ),

                            // Zone 3: Footer Quick Utility Actions
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const AttendanceScreen(),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight:
                                              AppDimensions.minTouchTarget,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                LucideIcons.camera,
                                                size: 15,
                                                color: AppColors.actionAccent,
                                              ),
                                              SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  'Kamera & GPS',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        AppColors.actionAccent,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    height: 18,
                                    width: 1,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  const SizedBox(width: 4),
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
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight:
                                              AppDimensions.minTouchTarget,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                LucideIcons.clock,
                                                size: 15,
                                                color: Color(0xFF475569),
                                              ),
                                              SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  'Rincian Shift',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF475569),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // 4. Favorite Menu Section (card-less multi-breakpoint grid)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.space16,
                    4,
                    AppDimensions.space16,
                    8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'Favorite Menu',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            key: const Key('favorite_menu_edit_btn'),
                            onTap: () => _showEditFavoriteDialog(context, ref),
                            borderRadius: BorderRadius.circular(999),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: AppDimensions.minTouchTarget,
                                minHeight: AppDimensions.minTouchTarget,
                              ),
                              child: Center(
                                widthFactor: 1.0,
                                heightFactor: 1.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFFFFF),
                                        Color(0xFFEFF6FF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                      width: 1.0,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x121D4ED8),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.slidersHorizontal,
                                        size: 13,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Edit',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Content-driven responsive menu rows across phone, tablet, and desktop widths
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final int columns;
                          final double horizontalGap;
                          final double verticalGap;
                          final double labelFontSize;

                          if (constraints.maxWidth < 310) {
                            columns = 3;
                            horizontalGap = 8;
                            verticalGap = 10;
                            labelFontSize = 11;
                          } else if (constraints.maxWidth < 470) {
                            columns = 4;
                            horizontalGap = 8;
                            verticalGap = 12;
                            labelFontSize = 11.5;
                          } else if (constraints.maxWidth < 550) {
                            columns = 5;
                            horizontalGap = 10;
                            verticalGap = 12;
                            labelFontSize = 12;
                          } else {
                            columns = 6;
                            horizontalGap = 12;
                            verticalGap = 12;
                            labelFontSize = 12;
                          }

                          final int rowCount =
                              (activeFavoriteMenus.length / columns).ceil();

                          return Column(
                            children: [
                              for (int r = 0; r < rowCount; r++) ...[
                                if (r > 0) SizedBox(height: verticalGap),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (int c = 0; c < columns; c++) ...[
                                      if (c > 0) SizedBox(width: horizontalGap),
                                      Expanded(
                                        child: (r * columns + c) <
                                                activeFavoriteMenus.length
                                            ? () {
                                                final menu =
                                                    activeFavoriteMenus[
                                                        r * columns + c];
                                                return _FavoriteMenuItem(
                                                  label: menu.gridLabel,
                                                  icon: menu.icon,
                                                  bgColor: menu.bgColor,
                                                  iconColor: menu.iconColor,
                                                  labelFontSize: labelFontSize,
                                                  onTap: () =>
                                                      _handleFavoriteMenuTap(
                                                    context,
                                                    menu.id,
                                                    shiftName: shiftName,
                                                    shiftHours: shiftHours,
                                                  ),
                                                );
                                              }()
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
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
                          const Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.building2,
                                  size: 17,
                                  color: Color(0xFF2563EB),
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Company Information',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => _showCompanyInfoListDialog(context),
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: AppDimensions.minTouchTarget,
                                minHeight: AppDimensions.minTouchTarget,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'See All',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.actionAccent,
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(
                                      LucideIcons.chevronRight,
                                      size: 15,
                                      color: AppColors.actionAccent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
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
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => _showCompanyInfoDetailDialog(context),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          companyName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Stronger Pipe, Brighter Future',
                                          style: TextStyle(
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
                                  const SizedBox(width: 12),
                                  const _CompanyBuildingIllustration(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
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
                prefixIcon: const Icon(LucideIcons.search, size: 18),
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AttendanceScreen(),
                      ),
                    );
                  },
                ),
                ActionChip(
                  label: const Text('Pengajuan Lembur'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onNavigateToTab(1);
                  },
                ),
                ActionChip(
                  label: const Text('Pengajuan Cuti'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onNavigateToTab(2);
                  },
                ),
                ActionChip(
                  label: const Text('Slip Gaji'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onNavigateToTab(3);
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
            const Icon(LucideIcons.calendarDays, color: AppColors.actionAccent),
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
                  icon: const Icon(LucideIcons.x, size: 18),
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
                icon: const Icon(LucideIcons.camera, size: 18),
                label: const Text(
                  'Buka Presensi Kerja (Kamera & GPS)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AttendanceScreen(),
                    ),
                  );
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

  void _handleFavoriteMenuTap(
    BuildContext context,
    String menuId, {
    required String shiftName,
    required String shiftHours,
  }) {
    switch (menuId) {
      case 'overtime':
        onNavigateToTab(1);
        break;
      case 'leave':
        onNavigateToTab(2);
        break;
      case 'payroll':
        onNavigateToTab(3);
        break;
      case 'attendance_camera':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AttendanceScreen(),
          ),
        );
        break;
      case 'on_duty':
        _showOnDutyRequestDialog(context);
        break;
      case 'profile':
        onNavigateToTab(4);
        break;
      case 'attendance_history':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const HistoryScreen(),
          ),
        );
        break;
      case 'shift_schedule':
        _showShiftScheduleDialog(context, shiftName, shiftHours);
        break;
      case 'company_policy':
        _showCompanyInfoDetailDialog(context);
        break;
    }
  }

  void _showEditFavoriteDialog(BuildContext context, WidgetRef ref) {
    final currentIds = List<String>.from(ref.read(favoriteMenuIdsProvider));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _EditFavoriteMenuSheet(
        initialSelectedIds: currentIds,
        onSave: (updatedIds) async {
          await ref
              .read(favoriteMenuIdsProvider.notifier)
              .updateFavorites(updatedIds);
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Susunan Favorite Menu berhasil disimpan.'),
                backgroundColor: AppColors.actionAccent,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
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
              leading: const Icon(LucideIcons.fileText, color: AppColors.actionAccent),
              title: const Text('Pedoman & Tata Tertib Kerja Karyawan', style: TextStyle(fontSize: 13)),
              subtitle: const Text('Versi 2026 / HR Corporate', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                _showCompanyInfoDetailDialog(context);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.shieldCheck, color: AppColors.actionAccent),
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
            Icon(LucideIcons.bookOpen, color: AppColors.actionAccent, size: 20),
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
  final double labelFontSize;

  const _FavoriteMenuItem({
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
    this.labelFontSize = 11.5,
  });

  @override
  Widget build(BuildContext context) {
    final menuId = kAllFavoriteMenus
            .where((m) => m.gridLabel == label)
            .firstOrNull
            ?.id ??
        'overtime';
    return _IosFavoriteMenuTile(
      menuId: menuId,
      label: label,
      accentColor: iconColor,
      onTap: onTap,
      labelFontSize: labelFontSize,
    );
  }
}

class _IosFavoriteMenuTile extends StatefulWidget {
  final String menuId;
  final String label;
  final Color accentColor;
  final VoidCallback onTap;
  final double labelFontSize;

  const _IosFavoriteMenuTile({
    required this.menuId,
    required this.label,
    required this.accentColor,
    required this.onTap,
    this.labelFontSize = 11.5,
  });

  @override
  State<_IosFavoriteMenuTile> createState() => _IosFavoriteMenuTileState();
}

class _IosFavoriteMenuTileState extends State<_IosFavoriteMenuTile> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 140);

    return Semantics(
      button: true,
      label: widget.label.replaceAll('\n', ' '),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          borderRadius: BorderRadius.circular(18),
          hoverColor: widget.accentColor.withValues(alpha: 0.05),
          splashColor: widget.accentColor.withValues(alpha: 0.12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppDimensions.minTouchTarget,
              minHeight: 78,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  AnimatedScale(
                    scale: _isPressed ? 0.93 : 1.0,
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    child: IosGlassMenuIcon(
                      menuId: widget.menuId,
                      size: 52,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: widget.labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                      height: 1.24,
                      letterSpacing: -0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditFavoriteMenuSheet extends StatefulWidget {
  final List<String> initialSelectedIds;
  final ValueChanged<List<String>> onSave;

  const _EditFavoriteMenuSheet({
    required this.initialSelectedIds,
    required this.onSave,
  });

  @override
  State<_EditFavoriteMenuSheet> createState() => _EditFavoriteMenuSheetState();
}

class _EditFavoriteMenuSheetState extends State<_EditFavoriteMenuSheet> {
  late List<String> _selectedIds;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(widget.initialSelectedIds);
  }

  void _toggleMenu(String id) {
    setState(() {
      _validationError = null;
      if (_selectedIds.contains(id)) {
        if (_selectedIds.length <= 1) {
          _validationError = 'Minimal 1 menu favorit harus tetap aktif.';
          return;
        }
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length >= 8) {
          _validationError = 'Maksimal 8 menu favorit dapat ditampilkan.';
          return;
        }
        _selectedIds.add(id);
      }
    });
  }

  void _moveItem(int currentIndex, int delta) {
    final targetIndex = currentIndex + delta;
    if (targetIndex < 0 || targetIndex >= _selectedIds.length) return;
    setState(() {
      _validationError = null;
      final item = _selectedIds.removeAt(currentIndex);
      _selectedIds.insert(targetIndex, item);
    });
  }

  void _resetDefault() {
    setState(() {
      _validationError = null;
      _selectedIds = List<String>.from(kDefaultFavoriteMenuIds);
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeMenus = _selectedIds
        .map((id) => kAllFavoriteMenus.where((m) => m.id == id).firstOrNull)
        .whereType<FavoriteMenuDefinition>()
        .toList();
    final inactiveMenus = kAllFavoriteMenus
        .where((m) => !_selectedIds.contains(m.id))
        .toList();
    final orderedMenus = [...activeMenus, ...inactiveMenus];

    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.82;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atur Favorite Menu',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pilih dan urutkan pintasan layanan di beranda Anda',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _resetDefault,
                    icon: const Icon(LucideIcons.rotateCcw, size: 15),
                    label: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
              if (_validationError != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.info,
                        size: 16,
                        color: Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _validationError!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: orderedMenus.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final menu = orderedMenus[index];
                    final selectedIndex = _selectedIds.indexOf(menu.id);
                    final isSelected = selectedIndex != -1;

                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF8FAFC)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFBFDBFE)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _toggleMenu(menu.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              IosGlassMenuIcon(
                                menuId: menu.id,
                                size: 42,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      menu.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      menu.subtitle,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected) ...[
                                IconButton(
                                  tooltip: 'Geser ke atas',
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    LucideIcons.chevronUp,
                                    size: 18,
                                    color: selectedIndex > 0
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                  onPressed: selectedIndex > 0
                                      ? () => _moveItem(selectedIndex, -1)
                                      : null,
                                ),
                                IconButton(
                                  tooltip: 'Geser ke bawah',
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(
                                    LucideIcons.chevronDown,
                                    size: 18,
                                    color: selectedIndex <
                                            _selectedIds.length - 1
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                  onPressed: selectedIndex <
                                          _selectedIds.length - 1
                                      ? () => _moveItem(selectedIndex, 1)
                                      : null,
                                ),
                              ],
                              Checkbox(
                                value: isSelected,
                                activeColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (_) => _toggleMenu(menu.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onSave(_selectedIds);
                      },
                      child: Text(
                        'Simpan (${_selectedIds.length} Menu)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyBuildingIllustration extends StatelessWidget {
  const _CompanyBuildingIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 52,
      child: CustomPaint(
        painter: const _BuildingPainter(),
      ),
    );
  }
}

class _BuildingPainter extends CustomPainter {
  const _BuildingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final baseLinePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final buildingPaint1 = Paint()
      ..color = const Color(0xFFEFF6FF)
      ..style = PaintingStyle.fill;

    final buildingBorder1 = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final buildingPaint2 = Paint()
      ..color = const Color(0xFFDBEAFE)
      ..style = PaintingStyle.fill;

    final buildingBorder2 = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final windowPaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Ground line
    canvas.drawLine(Offset(0, h - 2), Offset(w, h - 2), baseLinePaint);

    // Building 1 (Taller back tower, right side)
    final b1Rect = Rect.fromLTWH(w * 0.45, h * 0.12, w * 0.42, h * 0.86);
    canvas.drawRRect(RRect.fromRectAndRadius(b1Rect, const Radius.circular(3)), buildingPaint2);
    canvas.drawRRect(RRect.fromRectAndRadius(b1Rect, const Radius.circular(3)), buildingBorder2);

    // Windows on Building 1
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 2; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              w * 0.50 + col * (w * 0.16),
              h * 0.22 + row * (h * 0.16),
              w * 0.10,
              h * 0.08,
            ),
            const Radius.circular(1),
          ),
          windowPaint,
        );
      }
    }

    // Building 2 (Shorter front tower, left side)
    final b2Rect = Rect.fromLTWH(w * 0.12, h * 0.35, w * 0.38, h * 0.63);
    canvas.drawRRect(RRect.fromRectAndRadius(b2Rect, const Radius.circular(3)), buildingPaint1);
    canvas.drawRRect(RRect.fromRectAndRadius(b2Rect, const Radius.circular(3)), buildingBorder1);

    // Windows on Building 2
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 2; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              w * 0.18 + col * (w * 0.14),
              h * 0.45 + row * (h * 0.15),
              w * 0.08,
              h * 0.07,
            ),
            const Radius.circular(1),
          ),
          buildingBorder1,
        );
      }
    }

    // Plant accent on left
    final plantStemPaint = Paint()
      ..color = const Color(0xFF15803D)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(w * 0.06, h - 2), Offset(w * 0.06, h - 12), plantStemPaint);
    final plantLeafPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.06, h - 14), 5, plantLeafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
