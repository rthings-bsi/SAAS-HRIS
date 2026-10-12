import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

enum AppButtonVariant { primary, secondary, danger, outlined }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;
  final AppButtonVariant variant;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppDimensions.minTouchTarget,
    this.variant = AppButtonVariant.primary,
  });

  const AppButton.outlined({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppDimensions.minTouchTarget,
  }) : variant = AppButtonVariant.outlined;

  const AppButton.danger({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppDimensions.minTouchTarget,
  }) : variant = AppButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = isDisabled ? AppColors.borderNeutral : AppColors.actionAccent;
        foregroundColor = AppColors.canvasLight;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = isDisabled ? AppColors.surfaceMuted : AppColors.surfaceMuted;
        foregroundColor = isDisabled ? AppColors.inkMuted : AppColors.inkPrimary;
        borderSide = const BorderSide(color: AppColors.borderNeutral, width: AppDimensions.borderWidth);
        break;
      case AppButtonVariant.danger:
        backgroundColor = isDisabled ? AppColors.borderNeutral : AppColors.dangerText;
        foregroundColor = AppColors.canvasLight;
        break;
      case AppButtonVariant.outlined:
        backgroundColor = AppColors.canvasLight;
        foregroundColor = isDisabled ? AppColors.inkMuted : AppColors.inkPrimary;
        borderSide = const BorderSide(color: AppColors.borderNeutral, width: AppDimensions.borderWidth);
        break;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: width ?? double.infinity,
        minHeight: height.clamp(AppDimensions.minTouchTarget, double.infinity),
      ),
      child: Material(
        color: backgroundColor,
        borderRadius: borderSide == null ? AppDimensions.buttonBorderRadius : null,
        shape: borderSide != null
            ? RoundedRectangleBorder(
                borderRadius: AppDimensions.buttonBorderRadius,
                side: borderSide,
              )
            : null,
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          borderRadius: AppDimensions.buttonBorderRadius,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space12,
            ),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        icon!,
                        const SizedBox(width: AppDimensions.space8),
                      ],
                      Flexible(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: foregroundColor,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
