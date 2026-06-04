import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

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

  int _indexFromLocation(String location) {

    if (location.startsWith('/owner/customers')) return 1;

    if (location.startsWith('/owner/daily-orders')) return 2;

    if (location.startsWith('/owner/billing')) return 3;

    if (location.startsWith('/owner/payment')) return 4;

    if (location.startsWith('/owner/settings')) return 5;

    return 0;

  }



  void _onTap(int index) {

    final path = switch (index) {

      1 => '/owner/customers',

      2 => '/owner/daily-orders',

      3 => '/owner/billing',

      4 => '/owner/payment',

      5 => '/owner/settings',

      _ => '/owner/home',

    };

    context.go(path);

  }



  String _titleForIndex(int index) {

    return switch (index) {

      1 => AppStrings.customersScreenTitle,

      2 => AppStrings.navDailyOrders,

      3 => AppStrings.navBilling,

      4 => AppStrings.navPayment,

      5 => AppStrings.settingsTitle,

      _ => AppStrings.dashboardTitle,

    };

  }



  @override

  Widget build(BuildContext context) {

    final location = GoRouterState.of(context).uri.toString();

    final index = _indexFromLocation(location);

    final isHome = index == 0;
    final isCustomers = index == 1;

    return Scaffold(
      backgroundColor: isHome
          ? DashboardColors.background
          : isCustomers
              ? CustomerListColors.background
              : AppColors.bg,
      appBar: OwnerTopBar(
        screenTitle: _titleForIndex(index),
        dashboardMode: isHome,
        titleColor: isCustomers ? CustomerListColors.accent : null,
      ),

      body: widget.child,

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: DecoratedBox(

        decoration: BoxDecoration(

          color: DashboardColors.surface,

          border: Border(top: BorderSide(color: DashboardColors.outlineVariant.withValues(alpha: 0.3))),

        ),

        child: SafeArea(

          top: false,

          child: Padding(

            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),

            child: Row(

              mainAxisAlignment: MainAxisAlignment.spaceAround,

              children: [

                _NavItem(

                  icon: Icons.home_rounded,

                  label: AppStrings.navHome,

                  selected: index == 0,

                  onTap: () => _onTap(0),

                ),

                _NavItem(

                  icon: Icons.group_outlined,

                  label: AppStrings.navCustomers,

                  selected: index == 1,

                  onTap: () => _onTap(1),

                ),

                _NavItem(

                  icon: Icons.local_shipping_outlined,

                  label: AppStrings.dashboardNavOrders,

                  selected: index == 2,

                  onTap: () => _onTap(2),

                ),

                _NavItem(

                  icon: Icons.receipt_long_outlined,

                  label: AppStrings.navBilling,

                  selected: index == 3,

                  onTap: () => _onTap(3),

                ),

                _NavItem(

                  icon: Icons.payments_outlined,

                  label: AppStrings.navPayment,

                  selected: index == 4,

                  onTap: () => _onTap(4),

                ),

              ],

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


