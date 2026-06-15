import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../widgets/customer_dashboard_styles.dart';
import '../../../owner/presentation/widgets/dashboard/dashboard_styles.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabEntry(path: '/customer/home', icon: LucideIcons.home, label: 'Home'),
    _TabEntry(path: '/customer/orders', icon: LucideIcons.clipboardList, label: 'Orders'),
    _TabEntry(path: '/customer/payments', icon: LucideIcons.wallet, label: 'Payments'),
    _TabEntry(path: '/customer/profile', icon: LucideIcons.user, label: 'Profile'),
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
      backgroundColor: CusDashColors.background,
      body: child,
      bottomNavigationBar: _CusNavBar(
        currentIndex: index,
        onTap: (i) => context.go(_tabs[i].path),
        tabs: _tabs,
      ),
    );
  }
}

class _CusNavBar extends StatelessWidget {
  const _CusNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabEntry> tabs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: CusDashColors.surface,
        border: Border(top: BorderSide(color: CusDashColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              tabs.length,
              (i) => _NavItem(
                icon: tabs[i].icon,
                label: tabs[i].label,
                selected: currentIndex == i,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
        ? CusDashColors.accent
        : CusDashColors.inkMuted.withValues(alpha: 0.72);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: DashboardText.navLabel.copyWith(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabEntry {
  const _TabEntry({required this.path, required this.icon, required this.label});
  final String path;
  final IconData icon;
  final String label;
}
