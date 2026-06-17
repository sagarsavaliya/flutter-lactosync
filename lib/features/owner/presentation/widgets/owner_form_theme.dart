import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_typography.dart';
import 'customer_detail/customer_detail_styles.dart';
import 'customer_list_styles.dart';

/// Shared mint-green outline used on customer list search/sort and all owner inputs.
abstract final class OwnerFormTheme {
  static const borderColor = CustomerListColors.border;
  static const accentColor = CustomerListColors.accent;
  static const searchRowHeight = CustomerListMetrics.searchRowHeight;

  static OutlineInputBorder outlineBorder([Color? color, double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color ?? borderColor, width: width),
    );
  }

  static InputDecoration searchDecoration({
    required String hintText,
    Color? hintColor,
  }) {
    final border = outlineBorder();
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(fontSize: 14, height: 1.0, color: hintColor ?? CustomerListColors.addressMuted),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      prefixIcon: const Icon(LucideIcons.search, size: 17, color: CustomerListColors.searchIcon),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: searchRowHeight),
      border: border,
      enabledBorder: border,
      focusedBorder: outlineBorder(accentColor, 1.5),
    );
  }
}

/// Search field + square sort button (44px height).
class OwnerSearchSortRow extends StatelessWidget {
  const OwnerSearchSortRow({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onSort,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    const height = OwnerFormTheme.searchRowHeight;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppText.body.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.0),
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center,
              decoration: OwnerFormTheme.searchDecoration(hintText: hintText),
            ),
          ),
          const SizedBox(width: 8),
          OwnerSortButton(onSort: onSort),
        ],
      ),
    );
  }
}

class OwnerSortButton extends StatelessWidget {
  const OwnerSortButton({super.key, required this.onSort});

  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onSort,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CustomerListColors.searchBorder),
          ),
          alignment: Alignment.center,
          child: const Icon(LucideIcons.arrowUpDown, size: 18, color: CustomerDetailColors.accent),
        ),
      ),
    );
  }
}

/// Green-outlined compact button for secondary actions (e.g. Skip on daily orders).
/// Height shared by daily-order qty dropdown and Skip button.
const kOwnerCompactActionHeight = 36.0;

class OwnerOutlineButton extends StatelessWidget {
  const OwnerOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.height = kOwnerCompactActionHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? OwnerFormTheme.borderColor : OwnerFormTheme.borderColor.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: enabled ? CustomerListColors.sortIcon : CustomerListColors.addressMuted,
            ),
          ),
        ),
      ),
    );
  }
}
