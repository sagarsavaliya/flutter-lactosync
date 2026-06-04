import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, text, destructive }

// Unified button with loading state. Height is always AppSize.field (44px).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final effectiveCallback = loading ? null : onPressed;
    final child = loading
        ? const SizedBox(
            width: AppSize.iconMd,
            height: AppSize.iconMd,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: AppSize.iconSm),
                  const SizedBox(width: AppSpace.xs),
                  Text(label),
                ],
              )
            : Text(label);

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));

    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
          onPressed: effectiveCallback,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSize.field),
            shape: shape,
            elevation: 0,
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveCallback,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSize.field),
            shape: shape,
          ),
          child: child,
        ),
      AppButtonVariant.text => TextButton(
          onPressed: effectiveCallback,
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSize.field),
            shape: shape,
          ),
          child: child,
        ),
      AppButtonVariant.destructive => ElevatedButton(
          onPressed: effectiveCallback,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSize.field),
            shape: shape,
            elevation: 0,
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.75),
            textStyle: AppText.label.copyWith(fontWeight: FontWeight.w600),
          ),
          child: child,
        ),
    };
  }
}
