import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/owner_models.dart';
import 'packing_groups_panel.dart';

/// Expanded route accordion — frame 2 "Today's packing".
class RouteMilkPrepCompact extends StatelessWidget {
  const RouteMilkPrepCompact({
    super.key,
    required this.cards,
    required this.isMorning,
    required this.totalLiters,
  });

  final List<MilkPreparationContainerCard> cards;
  final bool isMorning;
  final double totalLiters;

  static const _ink = Color(0xFF1E2A1E);
  static const _greenDark = Color(0xFF1E5233);
  static const _muted = Color(0xFF8C938A);

  String get _litersBadge {
    final v = totalLiters;
    if (v == v.roundToDouble()) return '${v.toInt()} L';
    return '${v.toStringAsFixed(1)} L';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(
            children: [
              Icon(
                isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                size: 20,
                color: isMorning
                    ? const Color(0xFFE89A2E)
                    : const Color(0xFF5C6BC0),
              ),
              const SizedBox(width: 9),
              Text(
                "Today's packing",
                style: AppText.cardTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFCDE9CF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _litersBadge,
                  style: AppText.cardTitle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _greenDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (cards.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'No deliverables today for this route.',
              style: AppText.meta.copyWith(color: _muted, fontSize: 12),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PackingContainerGroups(cards: cards),
          ),
      ],
    );
  }
}
