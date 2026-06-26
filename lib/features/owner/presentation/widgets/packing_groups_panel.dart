import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/owner_models.dart';

/// Shared milk-packing UI — used on dashboard and route accordion.
class PackingContainerGroups extends StatelessWidget {
  const PackingContainerGroups({
    super.key,
    required this.cards,
    this.chipBackground = const Color(0xFFF7F9F2),
    this.onProductTap,
  });

  final List<MilkPreparationContainerCard> cards;
  final Color chipBackground;
  final void Function(MilkPreparationProductRow product)? onProductTap;

  static const _muted = Color(0xFF8C938A);
  static const _tanBg = Color(0xFFF1E2C9);
  static const _tanFg = Color(0xFF9A7B3E);
  static const _border = Color(0xFFECEFE5);
  String _containerLiters(double liters) {
    if (liters == liters.roundToDouble()) return '${liters.toInt()} Ltr';
    return '${liters.toStringAsFixed(1)} Ltr';
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No packing for this shift.',
          style: AppText.meta.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _muted,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final card in cards) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    card.containerTypeName.toUpperCase(),
                    style: AppText.meta.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: _muted,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tanBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _containerLiters(card.totalLiters),
                    style: AppText.meta.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: _tanFg,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF283C28).withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  for (var i = 0; i < card.products.length; i++) ...[
                    PackingProductRow(
                      product: card.products[i],
                      sizes: card.sizes,
                      chipBackground: chipBackground,
                      onTap: onProductTap == null
                          ? null
                          : () => onProductTap!(card.products[i]),
                    ),
                    if (i < card.products.length - 1)
                      const Divider(height: 1, thickness: 1, color: _border),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class PackingProductRow extends StatelessWidget {
  const PackingProductRow({
    super.key,
    required this.product,
    required this.sizes,
    this.chipBackground = const Color(0xFFF7F9F2),
    this.onTap,
  });

  final MilkPreparationProductRow product;
  final List<MilkPreparationSizeColumn> sizes;
  final Color chipBackground;
  final VoidCallback? onTap;

  static const _green = Color(0xFF2E6E45);
  static const _greenDark = Color(0xFF1E5233);
  static const _muted = Color(0xFF7E8A7B);
  static const _faded = Color(0xFFB3BAAE);
  static const _cowDot = Color(0xFF84C68E);
  static const _bufDot = Color(0xFF4E8C6E);

  bool get _isEmpty =>
      product.totalLiters <= 0 ||
      !product.counts.values.any((c) => c > 0);

  ({String animal, String? rate}) _parseName() {
    final name = product.productName.trim();
    final rateInName = RegExp(r'₹\s*(\d+)').firstMatch(name);
    if (rateInName != null) {
      return (animal: name, rate: null);
    }
    final rateMatch = RegExp(r'(\d+)\s*/-').firstMatch(name);
    final rate = rateMatch?.group(1);
    return (animal: name, rate: rate);
  }

  Color _dotColor(String animal) {
    if (animal.toLowerCase().contains('buffalo')) return _bufDot;
    return _cowDot;
  }

  String _litersLabel() {
    final v = product.totalLiters;
    if (v == v.roundToDouble()) return '${v.toInt()} L';
    return '${v.toStringAsFixed(1)} L';
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parseName();
    final empty = _isEmpty;

    return Opacity(
      opacity: empty ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: empty ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: _dotColor(parsed.animal),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        parsed.rate == null ? parsed.animal : parsed.animal,
                        style: AppText.cardTitle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _greenDark,
                        ),
                      ),
                    ),
                    if (parsed.rate != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '₹${parsed.rate}',
                        style: AppText.meta.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                        ),
                      ),
                    ],
                    Text(
                      _litersLabel(),
                      style: AppText.cardTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: empty ? _faded : _green,
                      ),
                    ),
                    if (!empty && onTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 18, color: _muted),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                if (empty)
                  Text(
                    'No packing today',
                    style: AppText.meta.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: _faded,
                    ),
                  )
                else
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final size in sizes)
                        if ((product.counts[size.key] ?? 0) > 0)
                          PackingSizeCountChip(
                            label: size.label,
                            count: product.counts[size.key]!,
                            background: chipBackground,
                          ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PackingSizeCountChip extends StatelessWidget {
  const PackingSizeCountChip({
    super.key,
    required this.label,
    required this.count,
    this.background = const Color(0xFFF7F9F2),
  });

  final String label;
  final int count;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 9, 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFDFE6D8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppText.meta.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF46604C),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            constraints: const BoxConstraints(minWidth: 18),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFCDE9CF),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: AppText.meta.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E5233),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Parse product line label for chips.
({String animal, String? rate}) parseRouteProductLabel(String productName) {
  final rateMatch = RegExp(r'(\d+)\s*/-').firstMatch(productName);
  final rate = rateMatch?.group(1);
  final animal = productName.split(' ').first;
  return (animal: animal, rate: rate);
}

Color routeProductDotColor(String animal) {
  if (animal.toLowerCase().contains('buffalo')) {
    return const Color(0xFF4E8C6E);
  }
  return const Color(0xFF84C68E);
}

String formatRouteQtyLiters(double qty) {
  if (qty == qty.roundToDouble()) return '${qty.toInt()} L';
  return '${qty.toStringAsFixed(1)} L';
}
