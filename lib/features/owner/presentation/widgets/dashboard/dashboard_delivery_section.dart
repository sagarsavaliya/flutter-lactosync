import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/owner_models.dart';
import '../packing_groups_panel.dart';

/// One shift block on the dashboard — frame 4 deliveries section.
class DashboardDeliverySection extends StatelessWidget {
  const DashboardDeliverySection({
    super.key,
    required this.title,
    required this.isMorning,
    required this.totalLiters,
    required this.statusTag,
    required this.cards,
  });

  final String title;
  final bool isMorning;
  final double totalLiters;
  final String statusTag;
  final List<MilkPreparationContainerCard> cards;

  static const _ink = Color(0xFF1E2A1E);
  static const _greenDark = Color(0xFF1E5233);
  static const _muted = Color(0xFF7E8A7B);

  String get _litersBadge {
    if (totalLiters == totalLiters.roundToDouble()) {
      return '${totalLiters.toInt()} Ltr';
    }
    return '${totalLiters.toStringAsFixed(1)} Ltr';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
            child: Row(
              children: [
                Icon(
                  isMorning
                      ? Icons.wb_sunny_rounded
                      : Icons.nights_stay_rounded,
                  size: 22,
                  color: isMorning
                      ? const Color(0xFFE89A2E)
                      : const Color(0xFF5E78B0),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: AppText.cardTitle.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCDE9CF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    _litersBadge,
                    style: AppText.meta.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _greenDark,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2E7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusTag,
                    style: AppText.meta.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: _muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PackingContainerGroups(cards: cards),
        ],
      ),
    );
  }
}
