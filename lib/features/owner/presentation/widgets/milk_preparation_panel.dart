import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/owner_models.dart';
import 'dashboard/dashboard_styles.dart';

class MilkPreparationPanel extends StatelessWidget {
  const MilkPreparationPanel({super.key, required this.summary});

  final MilkPreparationSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MilkPreparationShiftSection(shift: summary.morning, isMorning: true),
        const SizedBox(height: DashboardSpace.section),
        MilkPreparationShiftSection(shift: summary.evening, isMorning: false),
      ],
    );
  }
}

class MilkPreparationShiftSection extends StatelessWidget {
  const MilkPreparationShiftSection({
    super.key,
    required this.shift,
    required this.isMorning,
  });

  final MilkPreparationShift shift;
  final bool isMorning;

  @override
  Widget build(BuildContext context) {
    final titleColor = isMorning ? DashboardColors.primary : DashboardColors.secondary;
    final shiftIcon = isMorning ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    final volumeBadgeBg = isMorning ? DashboardColors.primaryContainer : DashboardColors.secondaryFixed;
    final volumeBadgeFg = isMorning ? DashboardColors.onPrimaryContainer : DashboardColors.secondary;
    final statusBadge = isMorning ? AppStrings.dashboardToday : AppStrings.dashboardScheduled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(shiftIcon, size: 20, color: titleColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isMorning ? AppStrings.milkPrepMorningTitle : AppStrings.milkPrepEveningTitle,
                style: DashboardText.shiftTitle.copyWith(color: titleColor),
              ),
            ),
            dashboardBadge(
              formatDashboardLiters(shift.totalLitres).replaceAll(' ', ''),
              background: volumeBadgeBg,
              foreground: volumeBadgeFg,
            ),
            const SizedBox(width: 4),
            dashboardBadge(statusBadge),
          ],
        ),
        const SizedBox(height: DashboardSpace.page),
        MilkPreparationGroupSection(group: shift.glassBottle, compactGrid: true),
        const SizedBox(height: DashboardSpace.page),
        MilkPreparationGroupSection(group: shift.plasticBag, compactGrid: false),
      ],
    );
  }
}

class MilkPreparationGroupSection extends StatelessWidget {
  const MilkPreparationGroupSection({
    super.key,
    required this.group,
    required this.compactGrid,
  });

  final MilkPreparationContainerGroup group;
  final bool compactGrid;

  @override
  Widget build(BuildContext context) {
    if (group.products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHeader(label: group.containerLabel, liters: group.totalLitres),
        const SizedBox(height: 8),
        if (compactGrid)
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - DashboardSpace.sm) / 2;
              return Wrap(
                spacing: DashboardSpace.sm,
                runSpacing: DashboardSpace.sm,
                children: [
                  for (final product in group.products)
                    SizedBox(
                      width: cardWidth,
                      child: _ProductCard(
                        product: product,
                        sizes: group.sizes,
                        compactGrid: true,
                      ),
                    ),
                ],
              );
            },
          )
        else
          Column(
            children: [
              for (var i = 0; i < group.products.length; i++) ...[
                _ProductCard(
                  product: group.products[i],
                  sizes: group.sizes,
                  compactGrid: false,
                ),
                if (i < group.products.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.liters});

  final String label;
  final double liters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(child: Text(label.toUpperCase(), style: DashboardText.groupLabel)),
          DecoratedBox(
            decoration: BoxDecoration(
              color: DashboardColors.secondaryFixed,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text(
                formatDashboardLiters(liters),
                style: DashboardText.kpiBadge.copyWith(color: DashboardColors.secondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.sizes,
    required this.compactGrid,
  });

  final MilkPreparationProductRow product;
  final List<MilkPreparationSizeColumn> sizes;
  final bool compactGrid;

  @override
  Widget build(BuildContext context) {
    final columns = compactGrid ? 2 : sizes.length.clamp(1, 4);

    return dashboardCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.displayLabel,
                  style: DashboardText.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                formatDashboardLiters(product.totalLitres),
                style: DashboardText.productQty,
              ),
            ],
          ),
          SizedBox(height: compactGrid ? 8 : 6),
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: compactGrid ? 2.15 : 1.9,
            children: [
              for (final size in _sortedSizes(sizes))
                _SizeCell(
                  label: size.label,
                  value: product.counts[size.key] ?? 0,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SizeCell extends StatelessWidget {
  const _SizeCell({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final display = value > 0 ? '$value' : '-';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DashboardColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: DashboardColors.outlineVariant.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label.toUpperCase(), style: DashboardText.sizeLabel, maxLines: 1),
            const SizedBox(height: 1),
            Text(display, style: DashboardText.sizeValue, maxLines: 1),
          ],
        ),
      ),
    );
  }
}

List<MilkPreparationSizeColumn> _sortedSizes(List<MilkPreparationSizeColumn> sizes) {
  const order = {'500ml': 0, '1L': 1, '1.5L': 2, '2L': 3};
  return [...sizes]..sort((a, b) => (order[a.key] ?? 99).compareTo(order[b.key] ?? 99));
}
