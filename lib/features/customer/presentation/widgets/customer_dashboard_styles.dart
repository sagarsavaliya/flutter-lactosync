import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Customer home dashboard — stitch / DairyEase premium frame tokens.
abstract final class CusDashColors {
  static const background = Color(0xFFF7F8F2);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8EBE3);
  static const ink = Color(0xFF1B4332);
  static const inkMuted = Color(0xFF6B7B6E);
  static const labelMuted = Color(0xFF9AA597);
  static const accent = Color(0xFF2E6E45);
  static const accentLight = Color(0xFFE4F2E6);
  static const accentBorder = Color(0xFFD6E7D9);
  static const monthCard = Color(0xFF2E6E45);
  static const monthStatBg = Color(0x33FFFFFF);
  static const morningChipBg = Color(0xFFFCF0DC);
  static const morningChipBorder = Color(0xFFF1E2C9);
  static const morningChipInk = Color(0xFF9A7B3E);
  static const payBrown = Color(0xFF8B4E32);
  static const payBrownMuted = Color(0xFFC28A6E);
  static const payButton = Color(0xFFC05E3D);
  static const payIconBg = Color(0xFFFBEDE6);
  static const todayBg = Color(0xFFFFF4D6);
  static const todayBorder = Color(0xFFE8A230);
  static const todayInk = Color(0xFF9A7B3E);
  static const calDelivered = Color(0xFF2E6E45);
  static const calSkippedBg = Color(0xFFF1F4EC);
  static const calSkippedBorder = Color(0xFFE7EBE0);
  static const calVacationBg = Color(0xFFEDE7F6);
  static const calVacationBorder = Color(0xFF9575CD);
  static const calVacationInk = Color(0xFF6A5ACD);
  static const calFutureBorder = Color(0xFFD8DECF);
  static const progressTrack = Color(0x33FFFFFF);
  static const progressFill = Color(0xFFE8C547);
  static const activeBg = Color(0xFFE4F2E6);
  static const activeInk = Color(0xFF1E7A40);
  static const cowDot = Color(0xFF84C68E);
  static const orderBarPast = Color(0xFF84C68E);
  static const orderBarPastSoft = Color(0x9984C68E);
  static const orderBarMuted = Color(0xFFD4DDD0);
}

abstract final class CusDashMetrics {
  static const cardRadius = 24.0;
  static const innerRadius = 16.0;
  static const chipRadius = 10.0;
  static const horizontalPad = 16.0;
  static const sectionGap = 16.0;
}

abstract final class CusDashText {
  static TextStyle get greeting => GoogleFonts.quicksand(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: CusDashColors.ink,
        height: 1.1,
        letterSpacing: -0.3,
      );

  static TextStyle get cardTitle => GoogleFonts.quicksand(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: CusDashColors.ink,
        height: 1.2,
      );

  static TextStyle get sectionLabel => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: CusDashColors.labelMuted,
        height: 1.2,
      );

  static BoxDecoration whiteCard({double radius = CusDashMetrics.cardRadius}) {
    return BoxDecoration(
      color: CusDashColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: CusDashColors.border),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF283C28).withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
