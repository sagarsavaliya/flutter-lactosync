import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import 'customer_detail/customer_detail_styles.dart';
import 'customer_list_styles.dart';
import 'owner_form_theme.dart';
import 'owner_screen_widgets.dart';

const List<double> kMilkQtyOptions = [
  0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0,
  5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0,
];

String milkQtyLabel(double litres) {
  if (litres < 1.0) return '${(litres * 1000).toInt()} ml';
  if (litres == litres.roundToDouble()) return '${litres.toInt()} L';
  return '$litres L';
}

double nearestMilkQty(double value) {
  if (value <= 0) return kMilkQtyOptions.first;
  var best = kMilkQtyOptions.first;
  var diff = (value - best).abs();
  for (final option in kMilkQtyOptions) {
    final d = (value - option).abs();
    if (d < diff) {
      best = option;
      diff = d;
    }
  }
  return best;
}

const double kOwnerInputHeight = 44;

/// Search field + optional trailing control (e.g. sort) at a fixed shared height.
class OwnerSearchBar extends StatelessWidget {
  const OwnerSearchBar({
    super.key,
    this.controller,
    required this.hintText,
    this.onChanged,
    this.trailing,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;

  InputDecoration _decoration(BuildContext context, String hint) {
    final border = OwnerFormTheme.outlineBorder();
    return InputDecoration(
      hintText: hint,
      hintStyle: AppText.body.copyWith(fontSize: 13, height: 1.0),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      prefixIcon: const Icon(Icons.search, size: 18, color: CustomerListColors.searchIcon),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: kOwnerInputHeight),
      border: border,
      enabledBorder: border,
      focusedBorder: OwnerFormTheme.outlineBorder(OwnerFormTheme.accentColor, 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    const height = kOwnerInputHeight;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppText.body.copyWith(fontSize: 13, height: 1.0),
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center,
              decoration: _decoration(context, hintText),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpace.sm),
            SizedBox(
              height: height,
              width: height,
              child: trailing,
            ),
          ],
        ],
      ),
    );
  }
}

class BorderedIconButton extends StatelessWidget {
  const BorderedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = kOwnerInputHeight,
    this.expand = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: OwnerFormTheme.borderColor),
          ),
          child: Center(child: Icon(icon, size: AppSize.iconMd)),
        ),
      ),
    );

    if (expand) {
      return SizedBox.expand(child: button);
    }

    return SizedBox(height: size, width: size, child: button);
  }
}

class BorderedDateNavigator extends StatelessWidget {
  const BorderedDateNavigator({
    super.key,
    required this.date,
    required this.onPrevious,
    required this.onNext,
    this.onPickDate,
  });

  final DateTime date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onPickDate;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final subtitle = DateFormat('EEE, d MMM').format(date);

    return Container(
      decoration: ownerWhiteCardDecoration(radius: OwnerScreenMetrics.pagerRadius),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          _PagerArrow(icon: LucideIcons.chevronLeft, onPressed: onPrevious),
          Expanded(
            child: InkWell(
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Text(
                      isToday ? AppStrings.ordersToday : DateFormat('d MMM yyyy').format(date),
                      textAlign: TextAlign.center,
                      style: AppText.cardTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: CustomerDetailColors.onSurface,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: AppText.meta.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CustomerDetailColors.iconMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _PagerArrow(icon: LucideIcons.chevronRight, onPressed: onNext),
        ],
      ),
    );
  }
}

class BorderedMonthNavigator extends StatelessWidget {
  const BorderedMonthNavigator({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    this.height = kOwnerInputHeight,
    this.compact = false,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy').format(month);

    return Container(
      decoration: ownerWhiteCardDecoration(radius: compact ? 14 : OwnerScreenMetrics.pagerRadius),
      padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 8, vertical: compact ? 6 : 7),
      child: SizedBox(
        height: compact ? null : height,
        child: Row(
          children: [
            _PagerArrow(
              icon: LucideIcons.chevronLeft,
              onPressed: onPrevious,
              size: compact ? 30 : 34,
            ),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.cardTitle.copyWith(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: CustomerDetailColors.onSurface,
                ),
              ),
            ),
            _PagerArrow(
              icon: LucideIcons.chevronRight,
              onPressed: onNext,
              size: compact ? 30 : 34,
            ),
          ],
        ),
      ),
    );
  }
}

class BorderedFilterDropdown<T> extends StatelessWidget {
  const BorderedFilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 132,
    this.height = kOwnerInputHeight,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerDetailColors.border),
        color: CustomerDetailColors.surface,
        boxShadow: const [OwnerScreenMetrics.cardShadow],
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _PagerArrow extends StatelessWidget {
  const _PagerArrow({
    required this.icon,
    required this.onPressed,
    this.size = 34,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomerDetailColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 18, color: CustomerDetailColors.accent),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(child: child);
  }
}

class InfoBadge extends StatelessWidget {
  const InfoBadge({
    super.key,
    required this.label,
    this.highlight = false,
    this.color,
  });

  final String label;
  final bool highlight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    final bg = highlight ? base.withValues(alpha: 0.18) : base.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xxs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: base.withValues(alpha: highlight ? 0.6 : 0.35)),
      ),
      child: Text(
        label,
        style: AppText.meta.copyWith(
          color: base,
          fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class AmountSummaryRow extends StatelessWidget {
  const AmountSummaryRow({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppText.label)),
        InfoBadge(
          label: '₹${amount.toStringAsFixed(0)}',
          color: color,
          highlight: true,
        ),
      ],
    );
  }
}

class BillAmountHero extends StatelessWidget {
  const BillAmountHero({
    super.key,
    required this.billAmount,
    required this.paidAmount,
    required this.pendingAmount,
    required this.status,
    this.statusLabel,
  });

  final double billAmount;
  final double paidAmount;
  final double pendingAmount;
  final String status;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final isPaid = status == 'paid';
    final isPartial = status == 'partial';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? const Color(0xFF8A9199) : const Color(0xFF6B7280);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: OwnerFormTheme.borderColor),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (statusLabel != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  statusLabel!,
                  style: AppText.label.copyWith(
                    color: isPaid
                        ? Colors.green.shade700
                        : isPartial
                            ? Theme.of(context).colorScheme.primary
                            : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (statusLabel != null) const SizedBox(height: AppSpace.sm),
            ThreeColumnAmountGrid(
              columns: [
                AmountGridColumn(
                  label: AppStrings.billAmountLabel,
                  value: billAmount,
                  valueColor: Theme.of(context).colorScheme.primary,
                ),
                AmountGridColumn(
                  label: AppStrings.billingPaidShort,
                  value: paidAmount,
                  valueColor: Colors.green.shade700,
                ),
                AmountGridColumn(
                  label: AppStrings.billingPendingShort,
                  value: isPaid ? 0 : pendingAmount,
                  valueColor: isPaid ? inkMuted : Colors.red.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AmountGridColumn {
  const AmountGridColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final double value;
  final Color? valueColor;
}

class ThreeColumnAmountGrid extends StatelessWidget {
  const ThreeColumnAmountGrid({super.key, required this.columns});

  final List<AmountGridColumn> columns;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? const Color(0xFF8A9199) : const Color(0xFF6B7280);

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < columns.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  columns[i].label,
                  style: AppText.meta.copyWith(color: inkMuted),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.xxs),
        Row(
          children: [
            for (var i = 0; i < columns.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  '₹${columns[i].value.toStringAsFixed(0)}',
                  style: AppText.label.copyWith(
                    color: columns[i].valueColor,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
