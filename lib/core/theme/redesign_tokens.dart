import 'package:flutter/material.dart';

/// Exact tokens from `LactoSync Routes Redesign.dc.html`.
abstract final class RedesignTokens {
  static const background = Color(0xFFF4F6EE);
  static const canvas = Color(0xFFE7EAE2);
  static const surface = Color(0xFFFFFFFF);
  static const fieldFill = Color(0xFFF7F9F2);
  static const accent = Color(0xFF2E6E45);
  static const accentMid = Color(0xFF3C8557);
  static const accentLight = Color(0xFFEAF3EB);
  static const accentBorder = Color(0xFFD6E7D9);
  static const ink = Color(0xFF1E2A1E);
  static const inkMuted = Color(0xFF46524A);
  static const labelMuted = Color(0xFF8C938A);
  static const metaMuted = Color(0xFF9AA597);
  static const border = Color(0xFFECEFE5);
  static const borderSoft = Color(0xFFE4E8DD);
  static const divider = Color(0xFFF0F2EB);
  static const avatarGreen = Color(0xFFA7E0B0);
  static const avatarGreenInk = Color(0xFF1E5233);
  static const successInk = Color(0xFF1E7A40);
  static const dueBg = Color(0xFFFBEDE6);
  static const dueBorder = Color(0xFFF2DDD1);
  static const dueInk = Color(0xFFC25B3A);

  static const pagePaddingH = 16.0;
  static const sectionGap = 18.0;
  static const cardRadius = 18.0;
  static const fieldRadius = 12.0;
  static const chipRadius = 9.0;
  static const buttonRadius = 14.0;
  static const heroRadius = 22.0;

  static const cardShadow = BoxShadow(
    color: Color(0x14283C28),
    blurRadius: 14,
    offset: Offset(0, 4),
  );

  static const heroShadow = BoxShadow(
    color: Color(0x14283C28),
    blurRadius: 22,
    offset: Offset(0, 8),
  );

  static TextStyle sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: ink,
          );

  static TextStyle fieldLabel(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: labelMuted,
          );
}
