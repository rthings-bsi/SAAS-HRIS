import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_button.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppDimensions.cardBorderRadius,
                  border: Border.all(
                    color: AppColors.borderNeutral,
                    width: AppDimensions.borderWidth,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.inkPrimary,
              ),
            ),
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.inkMuted,
                  height: 1.4,
                ),
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.space20),
              AppButton(
                text: actionText!,
                onPressed: onAction,
                width: 180,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
