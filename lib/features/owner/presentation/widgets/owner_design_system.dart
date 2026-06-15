import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import 'customer_detail/customer_detail_styles.dart';
import 'owner_screen_widgets.dart';

/// LactoSync owner UI tokens — match customer detail mockup.
abstract final class OwnerTheme {
  static const Color background = CustomerDetailColors.background;
  static const Color primary = CustomerDetailColors.accent;
  static const Color ink = CustomerDetailColors.onSurface;
  static const Color inkMuted = CustomerDetailColors.labelMuted;
  static const Color chipFill = CustomerDetailColors.accentLight;
}

Future<T?> showOwnerBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: false,
    backgroundColor: CustomerDetailColors.surface,
    barrierColor: const Color(0x75141E12),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(OwnerScreenMetrics.sheetRadius)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          22 + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OwnerSheetDragHandle(),
            Flexible(child: child),
          ],
        ),
      ),
    ),
  );
}

class OwnerSheetTitle extends StatelessWidget {
  const OwnerSheetTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppText.screenTitle.copyWith(fontSize: 18, color: OwnerTheme.primary),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpace.xxs),
          Text(subtitle!, style: AppText.body.copyWith(color: OwnerTheme.inkMuted)),
        ],
      ],
    );
  }
}

class OwnerSectionHeader extends StatelessWidget {
  const OwnerSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.uppercase = false,
  });

  final String title;
  final Widget? trailing;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final displayTitle = uppercase ? title.toUpperCase() : title;
    final style = uppercase
        ? AppText.meta.copyWith(
            color: OwnerTheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            fontSize: 12,
          )
        : AppText.cardTitle.copyWith(
            color: OwnerTheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          );

    return Row(
      children: [
        Expanded(child: Text(displayTitle, style: style)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class OwnerStatusBadge extends StatelessWidget {
  const OwnerStatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.meta.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerContactRow extends StatelessWidget {
  const OwnerContactRow({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor ?? OwnerTheme.inkMuted),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            text,
            style: AppText.body.copyWith(color: OwnerTheme.ink, height: 1.35),
          ),
        ),
      ],
    );
  }
}

class OwnerMintChip extends StatelessWidget {
  const OwnerMintChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: OwnerTheme.chipFill.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: OwnerTheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppText.meta.copyWith(
              color: OwnerTheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerCircleActionButton extends StatelessWidget {
  const OwnerCircleActionButton({
    super.key,
    required this.icon,
    this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: OwnerTheme.chipFill.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: OwnerTheme.primary),
        ),
      ),
    );
  }
}

class OwnerIconCircle extends StatelessWidget {
  const OwnerIconCircle({
    super.key,
    required this.icon,
    required this.background,
    required this.iconColor,
    this.size = 40,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: iconColor),
    );
  }
}

class OwnerEmptyRowCard extends StatelessWidget {
  const OwnerEmptyRowCard({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.iconBackground = AppColors.successFaint,
    this.iconColor = AppColors.success,
  });

  final IconData icon;
  final String message;
  final String? subtitle;
  final Color iconBackground;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OwnerIconCircle(
            icon: icon,
            background: iconBackground,
            iconColor: iconColor,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: AppText.label.copyWith(
                    color: OwnerTheme.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppText.meta.copyWith(color: OwnerTheme.inkMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerDashedEmptyCard extends StatelessWidget {
  const OwnerDashedEmptyCard({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: OwnerDashedOutline(
        radius: AppRadius.md,
        color: OwnerTheme.primary.withValues(alpha: 0.22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: OwnerTheme.inkMuted.withValues(alpha: 0.7)),
              const SizedBox(height: AppSpace.sm),
              Text(
                message,
                style: AppText.body.copyWith(color: OwnerTheme.inkMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OwnerDashedOutline extends StatelessWidget {
  const OwnerDashedOutline({
    super.key,
    required this.child,
    required this.radius,
    required this.color,
  });

  final Widget child;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 6;
        final extract = metric.extractPath(distance, next.clamp(0, metric.length));
        canvas.drawPath(extract, paint);
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Green app bar matching customer detail (for standalone routes).
PreferredSizeWidget ownerDetailAppBar({
  required String title,
  List<Widget>? actions,
  VoidCallback? onBack,
}) {
  return AppBar(
    backgroundColor: OwnerTheme.background,
    surfaceTintColor: Colors.transparent,
    foregroundColor: OwnerTheme.primary,
    elevation: 0,
    scrolledUnderElevation: 0,
    iconTheme: const IconThemeData(color: OwnerTheme.primary),
    title: Text(
      title,
      style: AppText.screenTitle.copyWith(color: OwnerTheme.primary),
    ),
    leading: onBack != null
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          )
        : null,
    actions: actions,
  );
}

/// 32px bordered chip matching [OwnerAddButton] — for Paid / Pending labels in section headers.
class OwnerMetricBadge extends StatelessWidget {
  const OwnerMetricBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        color: OwnerTheme.chipFill.withValues(alpha: 0.35),
      ),
      child: Text(
        label,
        style: AppText.meta.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          height: 1.0,
        ),
      ),
    );
  }
}

class OwnerAddButton extends StatelessWidget {
  const OwnerAddButton({
    super.key,
    this.onPressed,
    this.tooltip = 'Add',
    this.icon = Icons.add,
    this.iconColor,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final color = iconColor ?? (enabled ? OwnerTheme.primary : Theme.of(context).disabledColor);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: color.withValues(alpha: enabled ? 0.45 : 0.25)),
              color: OwnerTheme.chipFill.withValues(alpha: enabled ? 0.35 : 0.15),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

class OwnerSheetActions extends StatelessWidget {
  const OwnerSheetActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.loading = false,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryLoading = false,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool loading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool secondaryLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (secondaryLabel != null) ...[
          Expanded(
            child: AppButton(
              label: secondaryLabel!,
              variant: AppButtonVariant.secondary,
              loading: secondaryLoading,
              onPressed: onSecondary,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
        ],
        Expanded(
          child: AppButton(label: primaryLabel, loading: loading, onPressed: onPrimary),
        ),
      ],
    );
  }
}
