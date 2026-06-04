import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class OwnerPlaceholderPage extends StatelessWidget {
  const OwnerPlaceholderPage({
    super.key,
    required this.title,
    this.subtitle = AppStrings.comingSoonModule,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_outlined, size: 48, color: inkMuted),
            const SizedBox(height: AppSpace.md),
            Text(title, style: AppText.sectionTitle, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.sm),
            Text(subtitle, style: AppText.body.copyWith(color: inkMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
