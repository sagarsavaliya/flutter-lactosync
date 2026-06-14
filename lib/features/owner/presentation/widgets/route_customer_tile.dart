import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/delivery_provider.dart';
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

  static const _indexBadgeBg = Color(0xFFEAF3EB);
  static const _indexBadgeFg = Color(0xFF2E6E45);
  static const _skippedBg = Color(0xFFFBEAD0);
  static const _skippedFg = Color(0xFFA06A1E);
  static const _chipBg = Color(0xFFEFF6EC);
  static const _chipBorder = Color(0xFFDCEBDC);
  static const _chipInk = Color(0xFF246B3A);
  static const _ink = Color(0xFF1E2A1E);

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final faded = c.onVacation || c.isSkipped || !c.isDeliverable;
    final showSkipped = c.isSkipped && !c.onVacation;
    final indexLabel = '$index';

    return Opacity(
      opacity: faded ? 0.62 : 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                children: [
                  dragHandle ??
                      const Icon(Icons.drag_indicator,
                          size: 20, color: Color(0xFFC2CABB)),
                  const SizedBox(height: 8),
                  Container(
                    width: 27,
                    height: 27,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _indexBadgeBg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      indexLabel,
                      style: AppText.meta.copyWith(
                        fontSize: indexLabel.length > 1 ? 11 : 13,
                        fontWeight: FontWeight.w800,
                        color: _indexBadgeFg,
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
                        child: Wrap(
                          spacing: 7,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              c.name.toUpperCase(),
                              style: AppText.cardTitle.copyWith(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                color: faded ? AppColors.inkMuted : _ink,
                              ),
                            ),
                            if (showSkipped)
                              const _StatusPill(
                                label: 'SKIPPED',
                                bg: _skippedBg,
                                fg: _skippedFg,
                              ),
                            if (c.onVacation)
                              const _StatusPill(
                                label: 'VACATION',
                                bg: Color(0xFFECEFE5),
                                fg: AppColors.inkMuted,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (!c.onVacation && c.isSkipped && onUndo != null)
                        _SkipUndoButton(
                          label: 'Undo',
                          icon: Icons.replay_rounded,
                          isUndo: true,
                          onTap: onUndo!,
                        )
                      else if (!c.onVacation && !c.isSkipped && onSkip != null)
                        _SkipUndoButton(
                          label: 'Skip',
                          icon: Icons.skip_next_rounded,
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

    return Container(
      padding: const EdgeInsets.fromLTRB(11, 5, 6, 5),
      decoration: BoxDecoration(
        color: RouteCustomerTile._chipBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RouteCustomerTile._chipBorder),
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
            parsed.animal,
            style: AppText.meta.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: RouteCustomerTile._chipInk,
            ),
          ),
          if (parsed.rate != null) ...[
            const SizedBox(width: 6),
            Text(
              '₹${parsed.rate}',
              style: AppText.meta.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6E8A72),
              ),
            ),
          ],
          const Spacer(),
          _RoundStepButton(
            icon: Icons.remove,
            enabled: canStep && line.quantity > kMilkQtyOptions.first,
            onTap: () => _step(-1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              qtyLabel,
              style: AppText.meta.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E5233),
              ),
            ),
          ),
          _RoundStepButton(
            icon: Icons.add,
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
            color: enabled ? const Color(0xFFCFE3CF) : const Color(0xFFE4E8DD),
          ),
        ),
        child: Icon(
          icon,
          size: 14,
          color: enabled ? const Color(0xFF2E6E45) : const Color(0xFFC2CABB),
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
    final bg = isUndo ? RouteCustomerTile._skippedBg : Colors.white;
    final border = isUndo ? const Color(0xFFF1D9AE) : const Color(0xFFE4E8DD);
    final fg = isUndo ? RouteCustomerTile._skippedFg : const Color(0xFF8C938A);

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
    required this.windowLabel,
  });

  final int stops;
  final double liters;
  final String windowLabel;

  @override
  Widget build(BuildContext context) {
    final litersLabel = liters == liters.roundToDouble()
        ? '${liters.toInt()}'
        : liters.toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F8F1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECEFE5)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _RouteStatCell(value: '$stops', label: 'STOPS'),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE4E8DD),
            ),
            Expanded(
              child: _RouteStatCell(
                value: '$litersLabel L',
                label: 'TO PACK',
                valueColor: AppColors.primary,
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE4E8DD),
            ),
            Expanded(
              child: _RouteStatCell(
                value: windowLabel,
                label: 'WINDOW',
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
    this.valueColor = const Color(0xFF1E2A1E),
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
              color: const Color(0xFF8C938A),
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
