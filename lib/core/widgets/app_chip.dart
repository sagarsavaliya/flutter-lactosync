import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppChipStatus { success, warning, danger, neutral }

// Small status / info badge (pill shape).
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, this.status = AppChipStatus.neutral});

  final String label;
  final AppChipStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      AppChipStatus.success => (AppColors.successFaint, AppColors.success),
      AppChipStatus.warning => (AppColors.warningFaint, AppColors.warning),
      AppChipStatus.danger  => (AppColors.dangerFaint,  AppColors.danger),
      AppChipStatus.neutral => (AppColors.primaryFaint, AppColors.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: AppText.label.copyWith(color: fg)),
    );
  }
}
