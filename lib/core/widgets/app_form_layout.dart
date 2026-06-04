import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Two fields side-by-side with consistent gap and equal flex.
class AppFieldRow extends StatelessWidget {
  const AppFieldRow({
    super.key,
    required this.left,
    required this.right,
    this.spacing = AppSpace.sm,
  });

  final Widget left;
  final Widget right;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        SizedBox(width: spacing),
        Expanded(child: right),
      ],
    );
  }
}

/// Label on the left with optional trailing control (e.g. compact switch).
class AppLabelRow extends StatelessWidget {
  const AppLabelRow({
    super.key,
    required this.label,
    this.trailing,
  });

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppText.label.copyWith(color: AppColors.inkMuted),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Compact switch for inline label rows.
class AppCompactSwitch extends StatelessWidget {
  const AppCompactSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.72,
      alignment: Alignment.centerRight,
      child: Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Soft bordered icon button (e.g. settings add product).
class AppSoftIconButton extends StatelessWidget {
  const AppSoftIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 36,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    final button = Material(
      color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: primary.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 20, color: primary),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Read-only total display matching input field height.
class AppReadOnlyField extends StatelessWidget {
  const AppReadOnlyField({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.label.copyWith(color: inkMuted)),
        const SizedBox(height: AppSpace.xs),
        Container(
          width: double.infinity,
          height: AppSize.field,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Text(value, style: AppText.numStrong),
        ),
      ],
    );
  }
}
