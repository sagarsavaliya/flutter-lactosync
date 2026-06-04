import 'package:flutter/material.dart';

import 'dashboard_styles.dart';

class DashboardKpiCard extends StatelessWidget {
  const DashboardKpiCard({
    super.key,
    required this.icon,
    required this.title,
    required this.total,
    required this.primaryValue,
    required this.footerLabel,
    required this.progressColor,
    required this.footerColor,
  });

  final IconData icon;
  final String title;
  final int total;
  final int primaryValue;
  final String footerLabel;
  final Color progressColor;
  final Color footerColor;

  @override
  Widget build(BuildContext context) {
    final progress = total <= 0 ? 0.0 : (primaryValue / total).clamp(0.0, 1.0);

    return dashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 22, color: DashboardColors.onSurfaceVariant),
              dashboardBadge('TOTAL $total'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(title.toUpperCase(), style: DashboardText.kpiLabel),
              ),
              Text('$primaryValue', style: DashboardText.kpiValue),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: DashboardColors.surfaceContainer,
              color: progressColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            footerLabel.toUpperCase(),
            style: footerColor == DashboardColors.error
                ? DashboardText.kpiFooterError
                : DashboardText.kpiFooterMuted.copyWith(color: footerColor),
          ),
        ],
      ),
    );
  }
}
