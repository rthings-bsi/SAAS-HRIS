import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/hr_hub_logo.dart';
import '../../attendance/presentation/attendance_screen.dart';
import '../../auth/provider/auth_provider.dart';
import '../../leave/presentation/leave_screen.dart';
import '../../payroll/presentation/payroll_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _dialogShown = false;

  final List<Widget> _pages = const [
    AttendanceScreen(),
    LeaveScreen(),
    PayrollScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminNotice();
    });
  }

  void _checkAdminNotice() {
    if (!mounted || _dialogShown) return;
    final auth = ref.read(authStateProvider);
    if (auth.user != null && (auth.isAdministrator || !auth.hasEmployeeProfile)) {
      _dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Akun Pengelola',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Anda masuk sebagai ${auth.roleLabel}.',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aplikasi mobile HR Hub dikhususkan untuk karyawan operasional melakukan pencatatan kehadiran (Clock-In/Out) dan pengajuan cuti.\n\nAkun Anda adalah akun pengelola dan belum terhubung dengan profil karyawan. Untuk manajemen data, persetujuan cuti, dan payroll, silakan gunakan Web Admin.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                  height: 1.45,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ref.read(authStateProvider.notifier).logout();
              },
              child: const Text(
                'Ganti Akun Karyawan',
                style: TextStyle(
                  color: AppColors.dangerText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.actionAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Mengerti',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final userName = auth.user?['name'] as String? ?? 'Karyawan';
    final userEmail = auth.user?['email'] as String? ?? '';
    final companyName = (auth.user?['company'] is Map)
        ? (auth.user?['company']['name'] as String? ?? 'Perusahaan')
        : 'HR Hub Workspace';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.canvasLight,
          border: Border(
            top: BorderSide(
              color: Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.canvasLight,
          indicatorColor: AppColors.orangeTint,
          elevation: 0,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.access_time_rounded, color: AppColors.inkMuted, size: 22),
              selectedIcon: Icon(Icons.access_time_filled_rounded, color: AppColors.actionAccent, size: 22),
              label: 'Presensi',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined, color: AppColors.inkMuted, size: 22),
              selectedIcon: Icon(Icons.calendar_month_rounded, color: AppColors.actionAccent, size: 22),
              label: 'Cuti',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined, color: AppColors.inkMuted, size: 22),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.actionAccent, size: 22),
              label: 'Slip Gaji',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: AppColors.inkMuted, size: 22),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.actionAccent, size: 22),
              label: 'Profil',
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.canvasLight,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drawer Brand Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space20,
                  vertical: AppDimensions.space20,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const HrHubLogo(size: 32),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HR Hub',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              companyName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.actionAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space20),

                    // User Info Card in Drawer
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.actionAccent,
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : 'K',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                                if (userEmail.isNotEmpty)
                                  Text(
                                    userEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (auth.isAdministrator || !auth.hasEmployeeProfile)
                                        ? const Color(0xFFFEF3C7)
                                        : AppColors.orangeTint,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: (auth.isAdministrator || !auth.hasEmployeeProfile)
                                          ? const Color(0xFFF59E0B)
                                          : AppColors.orangeBorder,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    auth.roleLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: (auth.isAdministrator || !auth.hasEmployeeProfile)
                                          ? const Color(0xFF92400E)
                                          : AppColors.actionAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (auth.user != null && (auth.isAdministrator || !auth.hasEmployeeProfile)) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Color(0xFFB45309),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mobile khusus presensi & cuti karyawan. Gunakan Web Admin untuk persetujuan & kelola tim.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF92400E),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Drawer Navigation Items
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space12,
                  vertical: AppDimensions.space8,
                ),
                child: Column(
                  children: [
                    _DrawerNavTile(
                      icon: Icons.access_time_rounded,
                      title: 'Presensi Hari Ini',
                      isSelected: _currentIndex == 0,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 0);
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.calendar_month_rounded,
                      title: 'Pengajuan Cuti & Izin',
                      isSelected: _currentIndex == 1,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 1);
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.receipt_long_rounded,
                      title: 'Riwayat Slip Gaji',
                      isSelected: _currentIndex == 2,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 2);
                      },
                    ),
                    _DrawerNavTile(
                      icon: Icons.person_rounded,
                      title: 'Profil Saya',
                      isSelected: _currentIndex == 3,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _currentIndex = 3);
                      },
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Logout Action
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space12,
                ),
                child: Material(
                  color: AppColors.dangerBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: AppColors.dangerBorder,
                      width: 1.0,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.dangerText,
                      size: 20,
                    ),
                    title: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(
                        color: AppColors.dangerText,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerBg,
                                  borderRadius: BorderRadius.circular(10),
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
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerNavTile({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? AppColors.orangeTint : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? const BorderSide(color: AppColors.orangeBorder, width: 1.0)
              : BorderSide.none,
        ),
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            size: 20,
            color: isSelected ? AppColors.actionAccent : AppColors.inkMuted,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.actionAccent : AppColors.inkPrimary,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
