import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_typography.dart';
import 'customer_detail/customer_detail_styles.dart';
import 'customer_list_styles.dart';

abstract final class OwnerScreenMetrics {
  static const cardRadius = 16.0;
  static const pagerRadius = 15.0;
  static const sheetRadius = 24.0;
  static const cardShadow = BoxShadow(
    color: Color(0x14283C28),
    blurRadius: 14,
    offset: Offset(0, 4),
  );
}

BoxDecoration ownerWhiteCardDecoration({double radius = OwnerScreenMetrics.cardRadius}) {
  return BoxDecoration(
    color: CustomerDetailColors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: CustomerDetailColors.border),
    boxShadow: const [OwnerScreenMetrics.cardShadow],
  );
}

String formatOwnerCurrency(double amount) {
  final rounded = amount.round();
  if (rounded >= 1000) {
    return NumberFormat('#,##0', 'en_IN').format(rounded);
  }
  return rounded.toString();
}

Color milkTypeDotColor(String milkTypeName) {
  final lower = milkTypeName.toLowerCase();
  if (lower.contains('buffalo')) return CustomerDetailColors.buffaloDot;
  if (lower.contains('cow') || lower.contains('gir') || lower.contains('desi')) {
    return CustomerDetailColors.cowDot;
  }
  return CustomerDetailColors.accent;
}

class OwnerSettingsSectionLabel extends StatelessWidget {
  const OwnerSettingsSectionLabel({
    super.key,
    required this.label,
    this.icon,
    this.trailing,
  });

  final String label;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: CustomerDetailColors.accent),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: AppText.meta.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: CustomerDetailColors.onSurfaceVariant,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class OwnerSettingsCard extends StatelessWidget {
  const OwnerSettingsCard({super.key, required this.child, this.padding = const EdgeInsets.all(15)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: ownerWhiteCardDecoration(radius: CustomerDetailMetrics.sectionCardRadius),
      child: child,
    );
  }
}

class OrdersSummaryChips extends StatelessWidget {
  const OrdersSummaryChips({
    super.key,
    required this.litres,
    required this.orderCount,
    required this.skippedCount,
  });

  final double litres;
  final int orderCount;
  final int skippedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(OwnerScreenMetrics.pagerRadius),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [CustomerDetailColors.accent, Color(0xFF3C8557)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${litres == litres.roundToDouble() ? litres.toInt() : litres} L',
                  style: AppText.screenTitle.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEAF7EC),
                  ),
                ),
                Text(
                  'to deliver',
                  style: AppText.meta.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC8EBD0),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            value: '$orderCount',
            label: 'orders',
            valueColor: CustomerDetailColors.onSurface,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            value: '$skippedCount',
            label: 'skipped',
            valueColor: CustomerListColors.inactiveDot,
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(OwnerScreenMetrics.pagerRadius),
        border: Border.all(color: CustomerDetailColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppText.screenTitle.copyWith(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
          Text(
            label,
            style: AppText.meta.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: CustomerDetailColors.iconMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerShiftTabs extends StatelessWidget {
  const OwnerShiftTabs({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.labels,
  });

  final int selected;
  final ValueChanged<int> onSelected;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _ShiftTab(
              label: labels[i],
              selected: selected == i,
              onTap: () => onSelected(i),
            ),
          ),
        ],
      ],
    );
  }
}

class _ShiftTab extends StatelessWidget {
  const _ShiftTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? CustomerDetailColors.accent : CustomerDetailColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? CustomerDetailColors.accent : CustomerListColors.searchBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.cardTitle.copyWith(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? Colors.white : CustomerDetailColors.labelMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class OwnerGreenSummaryCard extends StatelessWidget {
  const OwnerGreenSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    this.badge,
    this.footerTiles = const [],
  });

  final String title;
  final String amount;
  final String? badge;
  final List<OwnerSummaryFooterTile> footerTiles;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CustomerDetailColors.accent, Color(0xFF3C8557)],
        ),
        boxShadow: [
          BoxShadow(
            color: CustomerDetailColors.accent.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
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
                    Text(
                      title,
                      style: AppText.meta.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFBFE6C8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      amount,
                      style: AppText.screenTitle.copyWith(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEAF7EC),
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    badge!,
                    style: AppText.meta.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFEAF7EC),
                    ),
                  ),
                ),
            ],
          ),
          if (footerTiles.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < footerTiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: footerTiles[i]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class OwnerSummaryFooterTile extends StatelessWidget {
  const OwnerSummaryFooterTile({
    super.key,
    required this.label,
    required this.value,
    this.inline = false,
  });

  final String label;
  final String value;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: inline
          ? Row(
              children: [
                Text(
                  label,
                  style: AppText.meta.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC8EBD0),
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: AppText.cardTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEAF7EC),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.meta.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC8EBD0),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: AppText.cardTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEAF7EC),
                  ),
                ),
              ],
            ),
    );
  }
}

class BillingSearchSendRow extends StatelessWidget {
  const BillingSearchSendRow({
    super.key,
    required this.searchChild,
    required this.sendLabel,
    required this.onSend,
    this.sending = false,
    this.enabled = true,
  });

  final Widget searchChild;
  final String sendLabel;
  final VoidCallback? onSend;
  final bool sending;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: searchChild),
        const SizedBox(width: 10),
        Material(
          color: enabled ? CustomerDetailColors.accent : CustomerDetailColors.accent.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          elevation: enabled ? 4 : 0,
          shadowColor: CustomerDetailColors.accent.withValues(alpha: 0.45),
          child: InkWell(
            onTap: enabled && !sending ? onSend : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sending)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  else
                    const Icon(LucideIcons.send, size: 16, color: Colors.white),
                  const SizedBox(width: 7),
                  Text(
                    sendLabel,
                    style: AppText.cardTitle.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OwnerSheetDragHandle extends StatelessWidget {
  const OwnerSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFD7DECE),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class OwnerSheetHeader extends StatelessWidget {
  const OwnerSheetHeader({
    super.key,
    required this.title,
    this.icon = LucideIcons.fileText,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CustomerDetailColors.accentLight,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 20, color: CustomerDetailColors.accent),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: AppText.screenTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: CustomerDetailColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: AppText.meta.copyWith(color: CustomerDetailColors.bodyInk),
          ),
        ],
      ],
    );
  }
}

class OwnerSheetFieldLabel extends StatelessWidget {
  const OwnerSheetFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 7),
      child: Text(
        label.toUpperCase(),
        style: AppText.meta.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: CustomerDetailColors.labelMuted,
        ),
      ),
    );
  }
}

class OwnerQtyStepper extends StatelessWidget {
  const OwnerQtyStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.enabled = true,
  });

  final double quantity;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: CustomerDetailColors.rateChipBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: CustomerDetailColors.rateChipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: LucideIcons.minus,
            onTap: enabled ? () => _step(-1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              _label(quantity),
              style: AppText.cardTitle.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: CustomerDetailColors.calHalfInk,
              ),
            ),
          ),
          _StepperButton(
            icon: LucideIcons.plus,
            onTap: enabled ? () => _step(1) : null,
          ),
        ],
      ),
    );
  }

  String _label(double qty) {
    if (qty <= 0) return '0 ml';
    if (qty < 1) return '${(qty * 1000).round()} ml';
    if (qty == qty.roundToDouble()) return '${qty.toInt()} L';
    return '$qty L';
  }

  void _step(int direction) {
    const options = [
      0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0,
      5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0,
    ];
    var index = options.indexWhere((v) => (v - quantity).abs() < 0.01);
    if (index < 0) {
      index = 0;
      for (var i = 0; i < options.length; i++) {
        if ((options[i] - quantity).abs() < (options[index] - quantity).abs()) {
          index = i;
        }
      }
    }
    final next = (index + direction).clamp(0, options.length - 1);
    onChanged(options[next]);
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomerDetailColors.surface,
      shape: const CircleBorder(
        side: BorderSide(color: CustomerDetailColors.calHalfBorder),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 26,
          height: 26,
          child: Icon(icon, size: 14, color: CustomerDetailColors.accent),
        ),
      ),
    );
  }
}

class OwnerIconActionButton extends StatelessWidget {
  const OwnerIconActionButton({
    super.key,
    required this.icon,
    this.onTap,
    this.background = CustomerDetailColors.statBg,
    this.border = CustomerListColors.searchBorder,
    this.iconColor = CustomerDetailColors.labelMuted,
    this.size = 38,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color background;
  final Color border;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 17, color: iconColor),
        ),
      ),
    );
  }
}
