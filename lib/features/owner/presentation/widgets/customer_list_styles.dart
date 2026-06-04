import 'package:flutter/material.dart';

import 'owner_form_theme.dart';

export 'owner_form_theme.dart' show OwnerSearchSortRow;

/// @deprecated Use [OwnerSearchSortRow] from owner_form_theme.dart
typedef CustomerListSearchRow = OwnerSearchSortRow;

/// Tokens from customers list design.html (compact view).
abstract final class CustomerListColors {
  static const background = Color(0xFFF9FBF9);
  static const cardFill = Color(0xFFE8F5EE);
  static const border = Color(0xFFA8D5BA);
  static const accent = Color(0xFF4B8B6B);
  static const fab = Color(0xFF2D5A41);
  static const nameInk = Color(0xFF1F2937);
  static const addressMuted = Color(0xFF6B7280);
  static const searchIcon = Color(0xFF9CA3AF);
  static const sortIcon = Color(0xFF374151);
}

abstract final class CustomerListMetrics {
  static const cardRadius = 12.0;
  static const cardPadding = 8.0;
  static const cardGap = 8.0;
  static const columnGap = 12.0;
  static const minCardHeight = 64.0;
  static const statusLineWidth = 4.0;
  static const fabSize = 56.0;
  static const fabRadius = 16.0;
  /// Matches [kOwnerInputHeight] so search field and sort button align on every screen.
  static const searchRowHeight = 44.0;
}

/// Dark green rounded FAB from the mockup.
class CustomerListFab extends StatelessWidget {
  const CustomerListFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomerListColors.fab,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(CustomerListMetrics.fabRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(CustomerListMetrics.fabRadius),
        child: const SizedBox(
          width: CustomerListMetrics.fabSize,
          height: CustomerListMetrics.fabSize,
          child: Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
