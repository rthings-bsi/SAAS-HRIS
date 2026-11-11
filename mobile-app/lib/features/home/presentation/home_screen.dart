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
          child: _AnimatedTabBody(
            currentIndex: _currentIndex,
            pages: _pages,
          ),
        ),
      ),
      bottomNavigationBar: _SmoothBottomNavBar(
        currentIndex: _currentIndex,
        items: navItems,
        onTap: (index) {
          if (_currentIndex != index) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}

class _AnimatedTabBody extends StatefulWidget {
  final int currentIndex;
  final List<Widget> pages;

  const _AnimatedTabBody({
    required this.currentIndex,
    required this.pages,
  });

  @override
  State<_AnimatedTabBody> createState() => _AnimatedTabBodyState();
}

class _AnimatedTabBodyState extends State<_AnimatedTabBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _outgoingIndex;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _outgoingIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _isTransitioning = false;
            _outgoingIndex = widget.currentIndex;
          });
        }
      });
  }

  @override
  void didUpdateWidget(covariant _AnimatedTabBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.stop();
        _controller.value = 1.0;
        _outgoingIndex = widget.currentIndex;
        _isTransitioning = false;
      } else {
        _outgoingIndex = oldWidget.currentIndex;
        _isTransitioning = true;
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final activeTransition = _isTransitioning && !reduceMotion;
    final direction = widget.currentIndex >= _outgoingIndex ? 1.0 : -1.0;

    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final enterT = activeTransition
              ? Curves.easeOutCubic.transform(_controller.value)
              : 1.0;
          final exitT = activeTransition
              ? Curves.easeOutCubic.transform(_controller.value)
              : 1.0;

          return Stack(
            fit: StackFit.expand,
            children: List.generate(widget.pages.length, (i) {
              final isCurrent = i == widget.currentIndex;
              final isOutgoing = activeTransition &&
                  i == _outgoingIndex &&
                  _outgoingIndex != widget.currentIndex;
              final offstage = !isCurrent && !isOutgoing;

              Offset translation = Offset.zero;
              double opacity = 1.0;
              if (activeTransition) {
                if (isCurrent) {
                  translation = Offset(direction * 0.045 * (1.0 - enterT), 0.0);
                  opacity = enterT;
                } else if (isOutgoing) {
                  translation = Offset(-direction * 0.03 * exitT, 0.0);
                  opacity = (1.0 - exitT).clamp(0.0, 1.0);
                }
              }

              return Offstage(
                offstage: offstage,
                child: TickerMode(
                  enabled: isCurrent || isOutgoing,
                  child: IgnorePointer(
                    ignoring: !isCurrent,
                    child: ExcludeSemantics(
                      excluding: !isCurrent,
                      child: FractionalTranslation(
                        translation: translation,
                        child: Opacity(
                          opacity: opacity,
                          child: widget.pages[i],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _SmoothBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_BottomNavItem> items;
  final ValueChanged<int> onTap;

  const _SmoothBottomNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final slideDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 240);

    return Container(
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slotCount = items.length;
                  final slotWidth = constraints.maxWidth / slotCount;
                  final pillWidth = (slotWidth - 10).clamp(38.0, 48.0);
                  const pillHeight = 28.0;

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: currentIndex.toDouble()),
                            duration: slideDuration,
                            curve: Curves.easeOutCubic,
                            builder: (context, animatedIndex, child) {
                              final travel =
                                  (animatedIndex - currentIndex).abs().clamp(0.0, 1.5);
                              final stretchX = reduceMotion
                                  ? 1.0
                                  : (1.0 + travel * 0.14);
                              final xOffset = animatedIndex * slotWidth +
                                  (slotWidth - pillWidth) / 2;

                              return Align(
                                alignment: Alignment.topLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Transform.translate(
                                    offset: Offset(xOffset, 0),
                                    child: Transform.scale(
                                      alignment: Alignment.center,
                                      scaleX: stretchX,
                                      scaleY: 1.0,
                                      child: child,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: pillWidth,
                              height: pillHeight,
                              decoration: BoxDecoration(
                                color: AppColors.navActive,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x1F1E40AF),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(slotCount, (index) {
                          return Expanded(
                            child: _SmoothNavTabButton(
                              item: items[index],
                              isActive: currentIndex == index,
                              reduceMotion: reduceMotion,
                              onTap: () => onTap(index),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmoothNavTabButton extends StatefulWidget {
  final _BottomNavItem item;
  final bool isActive;
  final bool reduceMotion;
  final VoidCallback onTap;

  const _SmoothNavTabButton({
    required this.item,
    required this.isActive,
    required this.reduceMotion,
    required this.onTap,
  });

  @override
  State<_SmoothNavTabButton> createState() => _SmoothNavTabButtonState();
}

class _SmoothNavTabButtonState extends State<_SmoothNavTabButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pressDuration = widget.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 110);
    final switchDuration = widget.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return Semantics(
      button: true,
      selected: widget.isActive,
      label: widget.item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.navActive.withValues(alpha: 0.08),
          highlightColor: AppColors.navActive.withValues(alpha: 0.04),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppDimensions.minTouchTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: AnimatedScale(
                scale: _isPressed && !widget.reduceMotion ? 0.92 : 1.0,
                duration: pressDuration,
                curve: Curves.easeOutCubic,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 28,
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: switchDuration,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.88,
                                end: 1.0,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: Icon(
                            widget.isActive
                                ? widget.item.activeIcon
                                : widget.item.icon,
                            key: ValueKey<bool>(widget.isActive),
                            size: 19,
                            color: widget.isActive
                                ? Colors.white
                                : AppColors.textBody,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: switchDuration,
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: widget.isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: widget.isActive
                            ? AppColors.navActive
                            : AppColors.textBody,
                        letterSpacing: -0.1,
                      ),
                      child: Text(
                        widget.item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
