import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

// Standard section container. Uses cardTheme from app_theme.dart.
// Pass onTap to make it interactive with an InkWell.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final inner = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpace.md),
      child: child,
    );

    return Card(
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(
                Theme.of(context).cardTheme.shape is RoundedRectangleBorder
                    ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder)
                        .borderRadius
                        .resolve(TextDirection.ltr)
                        .topLeft
                        .x
                    : 10,
              ),
              child: inner,
            )
          : inner,
    );
  }
}
