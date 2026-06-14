import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/owner_models.dart';

/// Customers directory — frame 5 in redesign brief.
abstract final class CustomerListColors {
  static const background = Color(0xFFF4F6EE);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFECEFE5);
  static const searchBorder = Color(0xFFE4E8DD);
  static const accent = Color(0xFF2E6E45);
  static const nameInk = Color(0xFF1E2A1E);
  static const addressMuted = Color(0xFF8C938A);
  static const summaryInk = Color(0xFF46524A);
  static const summaryMuted = Color(0xFF8C938A);
  static const searchIcon = Color(0xFF9AA597);
  static const sortIcon = Color(0xFF6E7A6C);
  static const inactiveOrange = Color(0xFFA06A1E);
  static const inactiveDot = Color(0xFFD98A2B);
  static const vacationBlue = Color(0xFF4A66A6);
  static const vacationChipBg = Color(0xFFE4ECF7);
  static const vacationChipBorder = Color(0xFFD4E0F2);
  static const vacationChipInk = Color(0xFF3D5896);
  static const vacationCardBg = Color(0xFFF5F8FC);
  static const vacationCardBorder = Color(0xFFDEE7F4);
  static const vacationAvatarBg = Color(0xFFE4ECF7);
  static const inactiveAvatarBg = Color(0xFFF1E3D4);
  static const activeAvatarBg = Color(0xFFDDEFE0);
  static const fab = Color(0xFF2E6E45);
  static const indexInk = Color(0xFFC2CABB);
  static const sectionInk = Color(0xFF2E6E45);
  static const sectionLine = Color(0xFFE1E5D9);
  static const pauseBg = Color(0xFFF4F6EE);
  static const pauseInk = Color(0xFF8C938A);
  static const inactiveBadgeBg = Color(0xFFF6EEE3);
  static const inactiveBadgeBorder = Color(0xFFEEDFCB);
}

abstract final class CustomerListMetrics {
  static const cardRadius = 16.0;
  static const cardGap = 9.0;
  static const searchRowHeight = 46.0;
  static const fabSize = 56.0;
  static const fabRadius = 18.0;
  static const cardShadow = BoxShadow(
    color: Color(0x38283C28), // rgba(40,60,40,0.22)
    blurRadius: 12,
    spreadRadius: -9,
    offset: Offset(0, 3),
  );
}

class CustomersSearchSortRow extends StatelessWidget {
  const CustomersSearchSortRow({
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
    const height = CustomerListMetrics.searchRowHeight;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: AppText.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppText.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFA0A99B),
                ),
                isDense: true,
                filled: true,
                fillColor: CustomerListColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: CustomerListColors.searchIcon,
                ),
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 44, minHeight: height),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CustomerListColors.searchBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: CustomerListColors.searchBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: CustomerListColors.accent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: CustomerListColors.surface,
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
                child: const Icon(
                  Icons.import_export_rounded,
                  size: 20,
                  color: CustomerListColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomersStatusStrip extends StatelessWidget {
  const CustomersStatusStrip({
    super.key,
    required this.activeCount,
    required this.inactiveCount,
    required this.vacationCount,
  });

  final int activeCount;
  final int inactiveCount;
  final int vacationCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
      child: Row(
        children: [
          RichText(
            text: TextSpan(
              style: AppText.meta.copyWith(fontSize: 12.5, height: 1.2),
              children: [
                TextSpan(
                  text: '$activeCount ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CustomerListColors.summaryInk,
                  ),
                ),
                const TextSpan(
                  text: 'active',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: CustomerListColors.summaryMuted,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (vacationCount > 0) ...[
            const Icon(
              Icons.flight_takeoff_rounded,
              size: 13,
              color: CustomerListColors.vacationBlue,
            ),
            const SizedBox(width: 5),
            Text(
              '$vacationCount on vacation',
              style: AppText.meta.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CustomerListColors.vacationBlue,
              ),
            ),
            const SizedBox(width: 14),
          ],
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: CustomerListColors.inactiveDot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$inactiveCount inactive',
            style: AppText.meta.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CustomerListColors.inactiveOrange,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomersSectionHeader extends StatelessWidget {
  const CustomersSectionHeader({super.key, required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 0, 9),
      child: Row(
        children: [
          Text(
            letter,
            style: AppText.cardTitle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: CustomerListColors.sectionInk,
              height: 1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: CustomerListColors.sectionLine,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomersAlphabetIndex extends StatelessWidget {
  const CustomersAlphabetIndex({
    super.key,
    required this.letters,
    required this.onLetter,
  });

  final List<String> letters;
  final ValueChanged<String> onLetter;

  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ#';

  @override
  Widget build(BuildContext context) {
    final available = letters.toSet();
    return Padding(
      padding: const EdgeInsets.only(right: 5, top: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (final ch in _alphabet.split(''))
            GestureDetector(
              onTap: available.contains(ch) ? () => onLetter(ch) : null,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  ch,
                  style: AppText.meta.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: available.contains(ch)
                        ? CustomerListColors.accent
                        : CustomerListColors.indexInk,
                    height: 1.35,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CustomerListFab extends StatelessWidget {
  const CustomerListFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomerListColors.fab,
      elevation: 8,
      shadowColor: CustomerListColors.fab.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(CustomerListMetrics.fabRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(CustomerListMetrics.fabRadius),
        child: const SizedBox(
          width: CustomerListMetrics.fabSize,
          height: CustomerListMetrics.fabSize,
          child: Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

String customerInitials(String name) {
  final cleaned = name.replaceAll(RegExp(r'[^A-Za-z ]'), '').trim();
  final parts = cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  final a = parts.first.isNotEmpty ? parts.first[0] : '';
  final b = parts.length > 1
      ? (parts[1].isNotEmpty ? parts[1][0] : '')
      : (parts.first.length > 1 ? parts.first[1] : '');
  return '$a$b'.toUpperCase();
}

String customerIndexLetter(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '#';
  final first = trimmed[0].toUpperCase();
  if (RegExp(r'[A-Z]').hasMatch(first)) return first;
  return '#';
}

String customersSortLabel(CustomerSort sort) {
  return switch (sort) {
    CustomerSort.nameDesc => 'Sorted Z–A',
    CustomerSort.updatedDesc => 'Sorted recent',
    CustomerSort.updatedAsc => 'Sorted oldest',
    _ => 'Sorted A–Z',
  };
}
