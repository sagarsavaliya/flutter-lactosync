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
        MilkPreparationShiftSection(
          cards: summary.morning,
          totalLiters: summary.morningTotalLiters,
          isMorning: true,
        ),
        const SizedBox(height: DashboardSpace.section),
        MilkPreparationShiftSection(
          cards: summary.evening,
          totalLiters: summary.eveningTotalLiters,
          isMorning: false,
        ),
      ],
    );
  }
}

class MilkPreparationShiftSection extends StatelessWidget {
  const MilkPreparationShiftSection({
    super.key,
    required this.cards,
    required this.totalLiters,
    required this.isMorning,
  });

  final List<MilkPreparationContainerCard> cards;
  final double totalLiters;
  final bool isMorning;

  @override
  Widget build(BuildContext context) {
    final titleColor = isMorning ? DashboardColors.primary : DashboardColors.secondary;
    final shiftIcon = isMorning ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
    final volumeBadgeBg =
        isMorning ? DashboardColors.primaryContainer : DashboardColors.secondaryFixed;
    final volumeBadgeFg =
        isMorning ? DashboardColors.onPrimaryContainer : DashboardColors.secondary;
    final statusBadge =
        isMorning ? AppStrings.dashboardToday : AppStrings.dashboardScheduled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(shiftIcon, size: 20, color: titleColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isMorning
                    ? AppStrings.milkPrepMorningTitle
                    : AppStrings.milkPrepEveningTitle,
                style: DashboardText.shiftTitle.copyWith(color: titleColor),
              ),
            ),
            dashboardBadge(
              formatDashboardLiters(totalLiters).replaceAll(' ', ''),
              background: volumeBadgeBg,
              foreground: volumeBadgeFg,
            ),
            const SizedBox(width: 4),
            dashboardBadge(statusBadge),
          ],
        ),
        const SizedBox(height: DashboardSpace.page),
        for (var i = 0; i < cards.length; i++) ...[
          MilkPreparationCardSection(card: cards[i]),
          if (i < cards.length - 1) const SizedBox(height: DashboardSpace.page),
        ],
      ],
    );
  }
}

class MilkPreparationCardSection extends StatelessWidget {
  const MilkPreparationCardSection({super.key, required this.card});

  final MilkPreparationContainerCard card;

  @override
  Widget build(BuildContext context) {
    if (card.products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GroupHeader(label: card.containerTypeName, liters: card.totalLiters),
        const SizedBox(height: 8),
        Column(
          children: [
            for (var i = 0; i < card.products.length; i++) ...[
              _ProductCard(product: card.products[i], sizes: card.sizes),
              if (i < card.products.length - 1) const SizedBox(height: 8),
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
  const _ProductCard({required this.product, required this.sizes});

  final MilkPreparationProductRow product;
  final List<MilkPreparationSizeColumn> sizes;

  @override
  Widget build(BuildContext context) {
    final columns = sizes.length.clamp(1, 4);

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
                  product.productName,
                  style: DashboardText.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                formatDashboardLiters(product.totalLiters),
                style: DashboardText.productQty,
              ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              mainAxisExtent: 52,
            ),
            itemCount: sizes.length,
            itemBuilder: (_, i) => _SizeCell(
              label: sizes[i].label,
              value: product.counts[sizes[i].key] ?? 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeCell extends StatelessWidget {
  const _SizeCell({required this.label, required this.value});

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
