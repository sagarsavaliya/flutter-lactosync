import 'package:flutter/material.dart';

import '../../../../../core/theme/app_typography.dart';

/// KPI stat card — frame 4 dashboard redesign.
class DashboardKpiCard extends StatelessWidget {
  const DashboardKpiCard({
    super.key,
    required this.icon,
    required this.title,
    required this.total,
    required this.primaryValue,
    required this.footerLabel,
    required this.progressColor,
    required this.footerDotColor,
    required this.footerTextColor,
  });

  final IconData icon;
  final String title;
  final int total;
  final int primaryValue;
  final String footerLabel;
  final Color progressColor;
  final Color footerDotColor;
  final Color footerTextColor;

  static const _ink = Color(0xFF1E2A1E);
  static const _muted = Color(0xFF7E8A7B);
  static const _iconBg = Color(0xFFEAF3EB);
  static const _green = Color(0xFF2E6E45);
  static const _track = Color(0xFFEEF2E7);

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (primaryValue / total).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECEFE5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283C28).withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _iconBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 19, color: _green),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8F1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFECEFE5)),
                  ),
                  child: Text(
                    'TOTAL $total',
                    style: AppText.meta.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$primaryValue',
                  style: AppText.numStrong.copyWith(
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    title,
                    style: AppText.meta.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: _track,
                color: progressColor,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: footerDotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    footerLabel,
                    style: AppText.meta.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: footerTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
