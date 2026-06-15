import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens — aligned with briefs/redesign app screen lactosync frame 4.
abstract final class DashboardColors {
  static const primary = Color(0xFF2E6E45);
  static const onPrimary = Color(0xFFE8FFE9);
  static const primaryContainer = Color(0xFFA7E0B0);
  static const onPrimaryContainer = Color(0xFF1E5233);

  static const secondary = Color(0xFF665E53);
  static const secondaryFixed = Color(0xFFECE1D3);

  static const tertiary = Color(0xFF745C27);

  static const background = Color(0xFFF4F6EE);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFEEF2E7);
  static const surfaceContainerLow = Color(0xFFF0F5EE);

  static const onSurface = Color(0xFF1E2A1E);
  static const onSurfaceVariant = Color(0xFF7E8A7B);
  static const outlineVariant = Color(0xFFECEFE5);

  static const error = Color(0xFFA06A1E);
}

abstract final class DashboardText {
  static const farmName = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
    color: Color(0xFF46524A),
    height: 1.1,
  );

  static const overviewLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: DashboardColors.secondary,
    height: 1.2,
  );

  static TextStyle get greeting => GoogleFonts.quicksand(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: DashboardColors.primary,
    height: 1.1,
    letterSpacing: -0.4,
  );

  static const kpiBadge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: DashboardColors.onSurfaceVariant,
    height: 1.1,
  );

  static const kpiLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: DashboardColors.onSurfaceVariant,
    height: 1.1,
  );

  static TextStyle get kpiValue => GoogleFonts.quicksand(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: DashboardColors.primary,
    height: 1.0,
  );

  static const kpiFooterError = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: DashboardColors.error,
    height: 1.1,
  );

  static const kpiFooterMuted = TextStyle(
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: DashboardColors.onSurfaceVariant,
    height: 1.1,
  );

  static const shiftTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.2,
  );

  static const groupLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
    color: DashboardColors.secondary,
    height: 1.2,
  );

  static const productName = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.15,
    color: DashboardColors.primary,
    height: 1.1,
  );

  static const productQty = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: DashboardColors.primary,
    height: 1.0,
  );

  static const sizeLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: DashboardColors.onSurfaceVariant,
    height: 1.0,
  );

  static const sizeValue = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: DashboardColors.onSurface,
    height: 1.0,
  );

  static const quickActionLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
    color: DashboardColors.onSurfaceVariant,
    height: 1.1,
  );

  static const navLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );
}

abstract final class DashboardSpace {
  static const page = 16.0;
  static const section = 24.0;
  static const sm = 8.0;
  static const xs = 4.0;
}

double dashboardLitersFromCounts(Map<String, int> counts) {
  const mlByKey = {
    '500ml': 500,
    '1L': 1000,
    '1.5L': 1500,
    '2L': 2000,
  };
  var ml = 0;
  counts.forEach((key, value) {
    ml += (mlByKey[key] ?? 0) * value;
  });
  return ml / 1000.0;
}

String formatDashboardLiters(double liters) {
  if (liters == liters.roundToDouble()) {
    return '${liters.toInt()} Ltr';
  }
  return '${liters.toStringAsFixed(1)} Ltr';
}

Widget dashboardCard({required Widget child, EdgeInsetsGeometry? padding}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: DashboardColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: DashboardColors.outlineVariant.withValues(alpha: 0.35)),
    ),
    child: Padding(
      padding: padding ?? const EdgeInsets.all(DashboardSpace.page),
      child: child,
    ),
  );
}

Widget dashboardBadge(String text, {Color? background, Color? foreground}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: background ?? DashboardColors.surfaceContainer,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        text,
        style: DashboardText.kpiBadge.copyWith(color: foreground ?? DashboardColors.onSurfaceVariant),
      ),
    ),
  );
}
