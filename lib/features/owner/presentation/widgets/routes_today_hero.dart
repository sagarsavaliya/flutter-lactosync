import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../providers/delivery_provider.dart';

/// Green gradient hero — stats reflect the active morning/evening tab.
class RoutesTodayHeroCard extends StatelessWidget {
  const RoutesTodayHeroCard({
    super.key,
    required this.ownerFirstName,
    required this.isMorning,
    required this.routeCount,
    required this.stops,
    required this.liters,
  });

  final String ownerFirstName;
  final bool isMorning;
  final int routeCount;
  final int stops;
  final double liters;

  static const _greenDark = Color(0xFF2E6E45);
  static const _greenMid = Color(0xFF3C8557);

  @override
  Widget build(BuildContext context) {
    final greeting = isMorning ? 'Good morning' : 'Good evening';
    final litersLabel = liters == liters.roundToDouble()
        ? '${liters.toInt()} L'
        : '${liters.toStringAsFixed(1)} L';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_greenDark, _greenMid],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _greenDark.withValues(alpha: 0.45),
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
                      ownerFirstName.isEmpty
                          ? greeting
                          : '$greeting, $ownerFirstName',
                      style: AppText.meta.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFBFE6C8),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "Today's deliveries",
                      style: AppText.cardTitle.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEAF7EC),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                size: 34,
                color: isMorning
                    ? const Color(0xFFFFD98A)
                    : const Color(0xFFC5D4F7),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroStatChip(value: '$routeCount', label: 'routes'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStatChip(value: '$stops', label: 'stops'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStatChip(value: litersLabel, label: 'to pack'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppText.numStrong.copyWith(
              fontSize: 17,
              color: const Color(0xFFEAF7EC),
            ),
          ),
          Text(
            label,
            style: AppText.meta.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFC8EBD0),
            ),
          ),
        ],
      ),
    );
  }
}

RoutesShiftTotals routesShiftTotals(List<DeliveryRouteModel> routes) {
  return RoutesShiftTotals(
    routeCount: routes.length,
    stops: routes.fold<int>(0, (sum, r) => sum + r.customerCount),
    liters: routes.fold<double>(0, (sum, r) => sum + r.totalLiters),
  );
}

class RoutesShiftTotals {
  const RoutesShiftTotals({
    required this.routeCount,
    required this.stops,
    required this.liters,
  });

  final int routeCount;
  final int stops;
  final double liters;
}
