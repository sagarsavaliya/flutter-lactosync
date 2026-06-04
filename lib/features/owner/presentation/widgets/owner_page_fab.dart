import 'package:flutter/material.dart';

import '../widgets/dashboard/dashboard_styles.dart';

class OwnerPageFab extends StatelessWidget {
  const OwnerPageFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: DashboardColors.primary,
      foregroundColor: DashboardColors.onPrimary,
      elevation: 4,
      child: Icon(icon, size: 28),
    );
  }
}
