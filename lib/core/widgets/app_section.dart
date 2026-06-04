import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

// Titled section: renders a header row then the child with consistent spacing.
class AppSection extends StatelessWidget {
  const AppSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppText.sectionTitle.copyWith(color: AppColors.inkMuted),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        child,
      ],
    );
  }
}
