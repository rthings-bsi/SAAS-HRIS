import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../auth/provider/auth_provider.dart';
import '../../leave/presentation/leave_screen.dart';
import '../../overtime/presentation/overtime_screen.dart';
import '../../payroll/presentation/payroll_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'home_dashboard_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  bool _dialogShown = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeDashboardView(
        onNavigateToTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const OvertimeScreen(),
      const LeaveScreen(),
      const PayrollScreen(),
      const ProfileScreen(),
    ];
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
            borderRadius: AppDimensions.cardBorderRadius,
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: AppDimensions.cardBorderRadius,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.warningText,
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
                  borderRadius: AppDimensions.buttonBorderRadius,
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
    const navItems = [
      _BottomNavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        label: 'Beranda',
      ),
      _BottomNavItem(
        icon: Icons.more_time_outlined,
        activeIcon: Icons.more_time_rounded,
        label: 'Lembur',
      ),
      _BottomNavItem(
        icon: Icons.event_available_outlined,
        activeIcon: Icons.event_available_rounded,
        label: 'Cuti',
      ),
      _BottomNavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        label: 'Gaji',
      ),
      _BottomNavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profil',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x180B2545),
                  blurRadius: 28,
                  offset: Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(navItems.length, (index) {
                final item = navItems[index];
                final isActive = _currentIndex == index;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      if (_currentIndex != index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Elevated active squircle pill vs clean inactive icon
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: isActive ? 42 : 36,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.navActive : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isActive ? item.activeIcon : item.icon,
                            size: 19,
                            color: isActive ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? AppColors.navActive : AppColors.navInactive,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
