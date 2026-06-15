import 'package:flutter/material.dart';

// Design token: semantic color palette for light and dark modes.
// Never use Color(...) directly outside this file.
abstract final class AppColors {
  // ── Light ──────────────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF386948);
  static const Color primaryFaint   = Color(0xFFB9EFC5);

  static const Color bg             = Color(0xFFF7FAF4);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color border         = Color(0xFFE3E6EA);

  static const Color ink            = Color(0xFF1A1D21);
  static const Color inkMuted       = Color(0xFF6B727B);
  static const Color inkFaint       = Color(0xFF9AA1AA);

  static const Color success        = Color(0xFF1E8E5A);
  static const Color successFaint   = Color(0xFFE4F4EC);
  static const Color warning        = Color(0xFFB9770A);
  static const Color warningFaint   = Color(0xFFFBF1DE);
  static const Color danger         = Color(0xFFC0392B);
  static const Color dangerFaint    = Color(0xFFFBEAE8);

  // ── Dark ───────────────────────────────────────────────────────────────────
  static const Color darkPrimary        = Color(0xFF4DB89A);
  static const Color darkPrimaryFaint   = Color(0xFF1A3530);

  static const Color darkBg             = Color(0xFF111418);
  static const Color darkSurface        = Color(0xFF1C2027);
  static const Color darkBorder         = Color(0xFF2C3038);

  static const Color darkInk            = Color(0xFFE8EAED);
  static const Color darkInkMuted       = Color(0xFF9AA1AA);
  static const Color darkInkFaint       = Color(0xFF6B727B);

  static const Color darkSuccess        = Color(0xFF3ECE82);
  static const Color darkSuccessFaint   = Color(0xFF152C20);
  static const Color darkWarning        = Color(0xFFE8A230);
  static const Color darkWarningFaint   = Color(0xFF2E2210);
  static const Color darkDanger         = Color(0xFFE05C4E);
  static const Color darkDangerFaint    = Color(0xFF2E1512);
}

// Customer-app design tokens — aligned with CustomerDetailColors (redesign DNA)
abstract final class CusColors {
  static const Color primary            = Color(0xFF2E6E45);
  static const Color primaryContainer   = Color(0xFF2E6E45);
  static const Color onPrimary          = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFEAF3EB);

  static const Color secondaryContainer    = Color(0xFFEAF3EB);
  static const Color onSecondaryContainer  = Color(0xFF46524A);

  static const Color surface                 = Color(0xFFF4F6EE);
  static const Color surfaceContainerLowest  = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow     = Color(0xFFF6F8F1);
  static const Color surfaceContainer        = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh    = Color(0xFFF4F6EE);
  static const Color surfaceContainerHighest = Color(0xFFECEFE5);

  static const Color onSurface        = Color(0xFF1E2A1E);
  static const Color onSurfaceVariant = Color(0xFF8C938A);
  static const Color outline          = Color(0xFF9AA597);
  static const Color outlineVariant   = Color(0xFFECEFE5);

  static const Color error            = Color(0xFFC25B3A);
  static const Color errorContainer   = Color(0xFFFBEDE6);
  static const Color onError          = Color(0xFFFFFFFF);

  static const Color successGreen     = Color(0xFF2E9E54);
  static const Color warningAmber     = Color(0xFF9A7B3E);
  static const Color vacationBlue     = Color(0xFF3D5896);
}
