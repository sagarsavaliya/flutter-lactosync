import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

/// App-wide floating toast — light card on owner screens (never default dark inverse).
abstract final class AppSnackBar {
  static void show(
    BuildContext context,
    String message, {
    Duration? duration,
    bool defer = false,
    bool isError = false,
  }) {
    void present() {
      if (!context.mounted) return;
      final background = isError ? AppColors.danger : AppColors.surface;
      final foreground = isError ? Colors.white : AppColors.ink;
      final border = isError ? AppColors.danger : AppColors.border;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: AppText.body.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: background,
            behavior: SnackBarBehavior.floating,
            elevation: 6,
            margin: const EdgeInsets.all(16),
            duration: duration ?? const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: border),
            ),
          ),
        );
    }

    if (defer) {
      WidgetsBinding.instance.addPostFrameCallback((_) => present());
    } else {
      present();
    }
  }

  static void showError(BuildContext context, String message) {
    show(context, message, isError: true);
  }
}
