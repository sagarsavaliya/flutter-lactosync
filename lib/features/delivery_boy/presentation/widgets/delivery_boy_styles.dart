import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Delivery boy app — stitch premium frame tokens.
abstract final class DbBoyColors {
  static const background = Color(0xFFF7F8F2);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8EBE3);
  static const divider = Color(0xFFF0F2EB);
  static const ink = Color(0xFF1B4332);
  static const inkMuted = Color(0xFF6B7B6E);
  static const labelMuted = Color(0xFF9AA597);
  static const accent = Color(0xFF2E6E45);
  static const accentLight = Color(0xFFE4F2E6);
  static const accentBorder = Color(0xFFD6E7D9);
  static const heroStart = Color(0xFF2E6E45);
  static const heroEnd = Color(0xFF3C8557);
  static const heroMuted = Color(0xFFBFE6C8);
  static const heroInk = Color(0xFFEAF7EC);
  static const morningChipBg = Color(0xFFFCF0DC);
  static const morningChipInk = Color(0xFF9A7B3E);
  static const done = Color(0xFF2E9E54);
  static const doneBg = Color(0xFFE4F2E6);
  static const skipped = Color(0xFFC28A6E);
  static const skippedBg = Color(0xFFFBEDE6);
  static const pendingBg = Color(0xFFF1F4EC);
  static const activeBorder = Color(0xFF2E6E45);
  static const activeGlow = Color(0x332E6E45);
  static const cowDot = Color(0xFF84C68E);
  static const buffaloDot = Color(0xFF4E8C6E);
  static const danger = Color(0xFFC25B3A);
}

abstract final class DbBoyMetrics {
  static const cardRadius = 22.0;
  static const innerRadius = 16.0;
  static const chipRadius = 10.0;
  static const horizontalPad = 16.0;
}

abstract final class DbBoyText {
  static TextStyle get greeting => GoogleFonts.quicksand(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: DbBoyColors.ink,
        height: 1.15,
        letterSpacing: -0.2,
      );

  static TextStyle get screenTitle => GoogleFonts.quicksand(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: DbBoyColors.ink,
        height: 1.2,
      );

  static TextStyle get cardTitle => GoogleFonts.quicksand(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: DbBoyColors.ink,
        height: 1.25,
      );

  static TextStyle get sectionLabel => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
        color: DbBoyColors.labelMuted,
        height: 1.2,
      );

  static TextStyle get meta => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: DbBoyColors.inkMuted,
        height: 1.3,
      );

  static TextStyle get navLabel => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.1,
      );

  static BoxDecoration whiteCard({double radius = DbBoyMetrics.cardRadius}) {
    return BoxDecoration(
      color: DbBoyColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: DbBoyColors.border),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF283C28).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration heroCard() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [DbBoyColors.heroStart, DbBoyColors.heroEnd],
      ),
      borderRadius: BorderRadius.circular(DbBoyMetrics.cardRadius),
      boxShadow: [
        BoxShadow(
          color: DbBoyColors.accent.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
