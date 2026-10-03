import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const AppSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius,
  });

  const AppSkeleton.card({
    super.key,
    this.width,
    this.height = 100.0,
  }) : borderRadius = null;

  const AppSkeleton.line({
    super.key,
    this.width,
    this.height = 14.0,
  }) : borderRadius = null;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius =
        widget.borderRadius ?? BorderRadius.circular(AppDimensions.radiusInput);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: effectiveRadius,
              border: Border.all(
                color: AppColors.borderNeutral,
                width: AppDimensions.borderWidth,
              ),
            ),
          ),
        );
      },
    );
  }
}
