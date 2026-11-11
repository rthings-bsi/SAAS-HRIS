import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_phosphor_icons.dart';
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
    if (auth.user != null && !auth.hasEmployeeProfile && !auth.canApproveRequests) {
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
                  LucideIcons.shieldAlert,
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
        icon: PhosphorIconsRegular.squaresFour,
        activeIcon: PhosphorIconsFill.squaresFour,
        label: 'Beranda',
      ),
      _BottomNavItem(
        icon: PhosphorIconsRegular.clockClockwise,
        activeIcon: PhosphorIconsFill.clockClockwise,
        label: 'Lembur',
      ),
      _BottomNavItem(
        icon: PhosphorIconsRegular.calendarCheck,
        activeIcon: PhosphorIconsFill.calendarCheck,
        label: 'Cuti',
      ),
      _BottomNavItem(
        icon: PhosphorIconsRegular.receipt,
        activeIcon: PhosphorIconsFill.receipt,
        label: 'Gaji',
      ),
      _BottomNavItem(
        icon: PhosphorIconsRegular.userCircle,
        activeIcon: PhosphorIconsFill.userCircle,
        label: 'Profil',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surfaceCanvas,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceCard,
          border: Border(
            top: BorderSide(
              color: AppColors.borderSubtle,
              width: 1.0,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: List.generate(navItems.length, (index) {
                    final item = navItems[index];
                    final isActive = _currentIndex == index;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              if (_currentIndex != index) {
                                setState(() {
                                  _currentIndex = index;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: AppDimensions.minTouchTarget,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      curve: Curves.easeOut,
                                      width: 40,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppColors.navActive
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        isActive ? item.activeIcon : item.icon,
                                        size: 19,
                                        color: isActive
                                            ? Colors.white
                                            : AppColors.textBody,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isActive
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isActive
                                            ? AppColors.navActive
                                            : AppColors.textBody,
                                        letterSpacing: -0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
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
