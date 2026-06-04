import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

// Single helper for all bottom sheets — consistent shape, padding, drag handle.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    // shape + backgroundColor come from bottomSheetTheme in app_theme.dart
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.sm,
          AppSpace.lg,
          AppSpace.lg + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: child,
      ),
    ),
  );
}
