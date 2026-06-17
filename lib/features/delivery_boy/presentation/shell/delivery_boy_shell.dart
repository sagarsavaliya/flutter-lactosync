import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/delivery_boy_styles.dart';
import '../widgets/delivery_boy_widgets.dart';
import '../../../../core/widgets/app_screen_safe_area.dart';

class DeliveryBoyShell extends StatelessWidget {
  const DeliveryBoyShell({super.key, required this.child});
  final Widget child;

  static const _paths = [
    '/delivery-boy/pickup',
    '/delivery-boy/stops',
    '/delivery-boy/cash',
    '/delivery-boy/profile',
  ];

  int _indexFromLocation(String location) {
    for (var i = 0; i < _paths.length; i++) {
      if (location.startsWith(_paths[i])) return i;
    }
    if (location.startsWith('/delivery-boy/home')) return 0;
    if (location.startsWith('/delivery-boy/route-sheet')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);

    return Scaffold(
      backgroundColor: DbBoyColors.background,
      body: AppScreenSafeArea(
        bottom: false,
        child: child,
      ),
      bottomNavigationBar: DbBoyNavBar(
        currentIndex: index,
        onTap: (i) => context.go(_paths[i]),
      ),
    );
  }
}
