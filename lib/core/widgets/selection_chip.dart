import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Milk type / container picker — green label when selected (matches checkmark).
class SelectionChip extends StatelessWidget {
  const SelectionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? AppColors.darkInk : AppColors.ink;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return FilterChip(
      label: Text(
        label,
        style: AppText.label.copyWith(
          color: selected ? primary : ink,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: selected,
      checkmarkColor: primary,
      selectedColor: primary.withValues(alpha: 0.12),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      side: BorderSide(color: selected ? primary : border),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
