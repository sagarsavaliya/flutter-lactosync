import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/redesign_colors.dart';
import '../../../owner/presentation/widgets/dashboard/dashboard_styles.dart';

class DeliveryBoyShell extends StatelessWidget {
  const DeliveryBoyShell({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    _Tab(path: '/delivery-boy/home', icon: LucideIcons.home, label: 'Home'),
    _Tab(
      path: '/delivery-boy/route-sheet',
      icon: LucideIcons.map,
      label: 'Route Sheet',
    ),
  ];

  int _indexFromLocation(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: DashboardColors.surface,
          border: Border(
            top: BorderSide(
              color: DashboardColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  _NavItem(
                    icon: _tabs[i].icon,
                    label: _tabs[i].label,
                    selected: index == i,
                    onTap: () => context.go(_tabs[i].path),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.path, required this.icon, required this.label});
  final String path;
  final IconData icon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? DashboardColors.primary
        : DashboardColors.onSurfaceVariant.withValues(alpha: 0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(label, style: DashboardText.navLabel.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
