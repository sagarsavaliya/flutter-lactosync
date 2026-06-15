import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../../core/constants/app_strings.dart';
import '../../../../core/models/subscription_status.dart';
import '../../../../core/providers/module_provider.dart';
import '../../../../core/providers/subscription_status_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/subscription/presentation/widgets/subscription_warning_banner.dart';
import '../widgets/customer_detail/customer_detail_styles.dart';
import '../widgets/customer_list_styles.dart';
import '../widgets/dashboard/dashboard_styles.dart';
import '../widgets/owner_top_bar.dart';



class OwnerShell extends ConsumerStatefulWidget {

  const OwnerShell({super.key, required this.child});



  final Widget child;



  @override

  ConsumerState<OwnerShell> createState() => _OwnerShellState();

}



class _OwnerShellState extends ConsumerState<OwnerShell> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(moduleProvider.notifier).fetch());
  }

  Future<void> _retryModules() async {
    await ref.read(moduleProvider.notifier).fetch();
  }

  // ── Nav item definitions ────────────────────────────────────────────────────

  static const _baseItems = [
    _NavDef(icon: Icons.home_rounded,        label: 'Home',       path: '/owner/home'),
    _NavDef(icon: Icons.group_outlined,       label: 'Customers',  path: '/owner/customers'),
    _NavDef(icon: Icons.local_shipping_outlined, label: 'Orders',  path: '/owner/daily-orders'),
    _NavDef(icon: Icons.receipt_long_outlined, label: 'Billing',   path: '/owner/billing'),
    _NavDef(icon: Icons.payments_outlined,    label: 'Payments',   path: '/owner/payment'),
  ];

  static const _routesItem = _NavDef(
    icon: Icons.route_outlined,
    label: 'Routes',
    path: '/owner/routes',
  );

  List<_NavDef> _navItems(bool routeDeliveryEnabled) {
    if (!routeDeliveryEnabled) return _baseItems;
    // Insert Routes after Orders (index 2), before Billing.
    return [
      _baseItems[0],
      _baseItems[1],
      _baseItems[2],
      _routesItem,
      _baseItems[3],
      _baseItems[4],
    ];
  }

  int _indexFromLocation(String location, List<_NavDef> items) {
    for (var i = 0; i < items.length; i++) {
      if (location.startsWith(items[i].path)) return i;
    }
    return 0;
  }

  String _titleForIndex(int index, List<_NavDef> items) {
    if (index < items.length) return items[index].label;
    return AppStrings.dashboardTitle;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final moduleState = ref.watch(moduleProvider);
    final routeDeliveryEnabled = moduleState.isEnabled('route_delivery');
    final items = _navItems(routeDeliveryEnabled);
    final index = _indexFromLocation(location, items);
    final isHome = index == 0;
    final isCustomers = index == 1;
    final isRoutes = items[index].path == '/owner/routes';
    final isRedesignScreen = isHome ||
        isRoutes ||
        isCustomers ||
        location.startsWith('/owner/daily-orders') ||
        location.startsWith('/owner/billing') ||
        location.startsWith('/owner/payment') ||
        location.startsWith('/owner/settings') ||
        location.startsWith('/owner/activity') ||
        location.startsWith('/owner/delivery-boys');

    // Fallback title for settings (not in bottom nav).
    final title = location.startsWith('/owner/settings')
        ? AppStrings.settingsTitle
        : _titleForIndex(index, items);

    return Scaffold(
      backgroundColor: isRedesignScreen ? CustomerDetailColors.background : AppColors.bg,
      appBar: OwnerTopBar(
        screenTitle: title,
        dashboardMode: isHome,
        titleColor: isCustomers ? const Color(0xFF2E6E45) : null,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final subState = ref.watch(subscriptionStatusProvider);
              if (subState.status == SubscriptionStatus.gracePeriod &&
                  subState.warning != null) {
                return SubscriptionWarningBanner(warning: subState.warning!);
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(child: widget.child),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: DashboardColors.surface,
          border: Border(top: BorderSide(
            color: DashboardColors.outlineVariant,
          )),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < items.length; i++)
                  _NavItem(
                    icon: items[i].icon,
                    label: items[i].label,
                    selected: index == i,
                    onTap: () => context.go(items[i].path),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavDef {
  const _NavDef({required this.icon, required this.label, required this.path});
  final IconData icon;
  final String label;
  final String path;
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

    final color = selected ? DashboardColors.primary : DashboardColors.onSurfaceVariant.withValues(alpha: 0.6);



    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(8),

      child: Padding(

        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

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


