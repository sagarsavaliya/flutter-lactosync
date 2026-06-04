import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

class RateCalculationCard extends StatelessWidget {
  const RateCalculationCard({
    super.key,
    required this.productName,
    required this.unitRate,
    required this.couponAmount,
    required this.quantity,
    required this.unit,
  });

  final String productName;
  final double unitRate;
  final double couponAmount;
  final double quantity;
  final String unit;

  double get effectiveRate => (unitRate - couponAmount).clamp(0, double.infinity);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final primary = Theme.of(context).colorScheme.primary;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.rateCalculation, style: AppText.label),
                const SizedBox(height: AppSpace.xs),
                Text(productName, style: AppText.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${quantity.toStringAsFixed(quantity == quantity.roundToDouble() ? 0 : 1)} $unit',
                style: AppText.sectionTitle.copyWith(color: primary),
              ),
              const SizedBox(height: AppSpace.xxs),
              if (couponAmount > 0) ...[
                Text(
                  '₹${unitRate.toStringAsFixed(0)} − ₹${couponAmount.toStringAsFixed(0)}',
                  style: AppText.meta.copyWith(color: inkMuted),
                ),
                Text(
                  '₹${effectiveRate.toStringAsFixed(0)}${AppStrings.perLtr}',
                  style: AppText.label.copyWith(color: AppColors.success),
                ),
              ] else
                Text(
                  '₹${unitRate.toStringAsFixed(0)}${AppStrings.perLtr}',
                  style: AppText.label.copyWith(color: AppColors.success),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
