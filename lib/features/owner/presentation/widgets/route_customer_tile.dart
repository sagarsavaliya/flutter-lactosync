import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_typography.dart';
import '../providers/delivery_provider.dart';
import 'customer_detail/customer_detail_styles.dart';
import 'owner_shared_widgets.dart';
import 'packing_groups_panel.dart';

/// Route detail customer row — matches redesign frame 3 (inline qty steppers).
class RouteCustomerTile extends StatelessWidget {
  const RouteCustomerTile({
    super.key,
    required this.customer,
    required this.index,
    this.dragHandle,
    this.onSkip,
    this.onUndo,
    this.onQtyChanged,
  });

  final RouteCustomerModel customer;
  final int index;
  final Widget? dragHandle;
  final VoidCallback? onSkip;
  final VoidCallback? onUndo;
  final void Function(int orderId, double qty)? onQtyChanged;

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final faded = c.onVacation || c.isSkipped || !c.isDeliverable;
    final showSkipped = c.isSkipped && !c.onVacation;
    final indexLabel = '$index';
    final address = c.address.trim();

    return Opacity(
      opacity: faded ? 0.62 : 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                children: [
                  dragHandle ??
                      const Icon(
                        LucideIcons.gripVertical,
                        size: 20,
                        color: CustomerDetailColors.iconMuted,
                      ),
                  const SizedBox(height: 8),
                  Container(
                    width: 27,
                    height: 27,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: CustomerDetailColors.accentLight,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      indexLabel,
                      style: AppText.meta.copyWith(
                        fontSize: indexLabel.length > 1 ? 11 : 13,
                        fontWeight: FontWeight.w800,
                        color: CustomerDetailColors.accent,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 7,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  c.name.toUpperCase(),
                                  style: AppText.cardTitle.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                    color: faded
                                        ? CustomerDetailColors.labelMuted
                                        : CustomerDetailColors.accent,
                                  ),
                                ),
                                if (showSkipped)
                                  const _StatusPill(
                                    label: 'SKIPPED',
                                    bg: CustomerDetailColors.morningChipBg,
                                    fg: CustomerDetailColors.morningChipInk,
                                  ),
                                if (c.onVacation)
                                  const _StatusPill(
                                    label: 'VACATION',
                                    bg: CustomerDetailColors.statBg,
                                    fg: CustomerDetailColors.labelMuted,
                                  ),
                              ],
                            ),
                            if (address.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    LucideIcons.mapPin,
                                    size: 11,
                                    color: CustomerDetailColors.iconMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: AppText.meta.copyWith(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: CustomerDetailColors.iconMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (!c.onVacation && c.isSkipped && onUndo != null)
                        _SkipUndoButton(
                          label: 'Undo',
                          icon: LucideIcons.rotateCcw,
                          isUndo: true,
                          onTap: onUndo!,
                        )
                      else if (!c.onVacation && !c.isSkipped && onSkip != null)
                        _SkipUndoButton(
                          label: 'Skip',
                          icon: LucideIcons.skipForward,
                          isUndo: false,
                          onTap: onSkip!,
                        ),
                    ],
                  ),
                  if (c.deliveryLines.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: c.deliveryLines
                          .map((line) => Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: _ProductStepperChip(
                                  line: line,
                                  disabled: faded || c.onVacation,
                                  onQtyChanged: onQtyChanged,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductStepperChip extends StatelessWidget {
  const _ProductStepperChip({
    required this.line,
    required this.disabled,
    this.onQtyChanged,
  });

  final RouteCustomerOrderLine line;
  final bool disabled;
  final void Function(int orderId, double qty)? onQtyChanged;

  void _step(int delta) {
    if (disabled || onQtyChanged == null || line.orderId == null) return;
    final current = nearestMilkQty(line.quantity);
    final idx = kMilkQtyOptions.indexOf(current);
    final newIdx = (idx + delta).clamp(0, kMilkQtyOptions.length - 1);
    final newQty = kMilkQtyOptions[newIdx];
    if (newQty != current) {
      onQtyChanged!(line.orderId!, newQty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = parseRouteProductLabel(line.productName);
    final qtyLabel = disabled ? '0 L' : formatRouteQtyLiters(line.quantity);
    final canStep = !disabled && line.orderId != null && onQtyChanged != null;
    final productLabel = parsed.rate != null
        ? '${parsed.animal} - ₹${parsed.rate}'
        : parsed.animal;

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 5, 6, 5),
      decoration: BoxDecoration(
        color: CustomerDetailColors.rateChipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CustomerDetailColors.rateChipBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: routeProductDotColor(parsed.animal),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            productLabel,
            style: AppText.meta.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: CustomerDetailColors.rateChipInk,
            ),
          ),
          const Spacer(),
          _RoundStepButton(
            icon: LucideIcons.minus,
            enabled: canStep && line.quantity > kMilkQtyOptions.first,
            onTap: () => _step(-1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              qtyLabel,
              style: AppText.cardTitle.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: CustomerDetailColors.calHalfInk,
              ),
            ),
          ),
          _RoundStepButton(
            icon: LucideIcons.plus,
            enabled: canStep && line.quantity < kMilkQtyOptions.last,
            onTap: () => _step(1),
          ),
        ],
      ),
    );
  }
}

class _RoundStepButton extends StatelessWidget {
  const _RoundStepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 23,
        height: 23,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? CustomerDetailColors.calHalfBorder
                : CustomerDetailColors.divider,
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled
              ? CustomerDetailColors.accent
              : CustomerDetailColors.iconMuted,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppText.meta.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SkipUndoButton extends StatelessWidget {
  const _SkipUndoButton({
    required this.label,
    required this.icon,
    required this.isUndo,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isUndo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isUndo
        ? CustomerDetailColors.morningChipBg
        : CustomerDetailColors.surface;
    final border = isUndo
        ? CustomerDetailColors.morningChipBorder
        : CustomerDetailColors.border;
    final fg = isUndo
        ? CustomerDetailColors.morningChipInk
        : CustomerDetailColors.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppText.meta.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat strip on route list cards — matches redesign frame 1.
class RouteStatBoxes extends StatelessWidget {
  const RouteStatBoxes({
    super.key,
    required this.stops,
    required this.liters,
    required this.offCount,
  });

  final int stops;
  final double liters;
  final int offCount;

  @override
  Widget build(BuildContext context) {
    final litersLabel = liters == liters.roundToDouble()
        ? '${liters.toInt()}'
        : liters.toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: CustomerDetailColors.statBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerDetailColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _RouteStatCell(value: '$stops', label: 'CUSTOMERS'),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: CustomerDetailColors.divider,
            ),
            Expanded(
              child: _RouteStatCell(
                value: '$litersLabel L',
                label: 'TO PACK',
                valueColor: CustomerDetailColors.accent,
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: CustomerDetailColors.divider,
            ),
            Expanded(
              child: _RouteStatCell(
                value: '$offCount',
                label: 'ON HOLD',
                valueColor: const Color(0xFFD98A2B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteStatCell extends StatelessWidget {
  const _RouteStatCell({
    required this.value,
    required this.label,
    this.valueColor = CustomerDetailColors.onSurface,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        children: [
          Text(
            value,
            style: AppText.cardTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppText.meta.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: CustomerDetailColors.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
