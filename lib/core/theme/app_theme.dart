import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_sizes.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

// Builds the full Material 3 ThemeData from design tokens.
// All sub-themes are wired here; no widget hardcodes a raw value.
ThemeData buildLightTheme() => _build(
  brightness: Brightness.light,
  primary:    AppColors.primary,
  primaryFaint: AppColors.primaryFaint,
  bg:         AppColors.bg,
  surface:    AppColors.surface,
  border:     AppColors.border,
  ink:        AppColors.ink,
  inkMuted:   AppColors.inkMuted,
);

ThemeData buildDarkTheme() => _build(
  brightness: Brightness.dark,
  primary:    AppColors.darkPrimary,
  primaryFaint: AppColors.darkPrimaryFaint,
  bg:         AppColors.darkBg,
  surface:    AppColors.darkSurface,
  border:     AppColors.darkBorder,
  ink:        AppColors.darkInk,
  inkMuted:   AppColors.darkInkMuted,
);

ThemeData _build({
  required Brightness brightness,
  required Color primary,
  required Color primaryFaint,
  required Color bg,
  required Color surface,
  required Color border,
  required Color ink,
  required Color inkMuted,
}) {
  final cs = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
  ).copyWith(
    primary: primary,
    surface: surface,
    onSurface: ink,
  );

  final radius = BorderRadius.circular(AppRadius.md);
  final radiusLg = BorderRadius.circular(AppRadius.lg);

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    visualDensity: VisualDensity.compact,
    scaffoldBackgroundColor: bg,

    // ── AppBar ──────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: AppSize.appBar,
      titleTextStyle: AppText.screenTitle.copyWith(color: ink),
      iconTheme: IconThemeData(size: AppSize.iconMd, color: ink),
    ),

    // ── Card ────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: border),
      ),
      color: surface,
    ),

    // ── Input ───────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: 11,
      ),
      constraints: const BoxConstraints(minHeight: AppSize.field),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
      labelStyle: AppText.label.copyWith(color: inkMuted),
      hintStyle: AppText.body.copyWith(color: inkMuted),
      errorStyle: AppText.meta.copyWith(color: AppColors.danger),
    ),

    // ── Buttons ─────────────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSize.field),
        shape: RoundedRectangleBorder(borderRadius: radius),
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: primary.withValues(alpha: 0.35),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.75),
        textStyle: AppText.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSize.field),
        shape: RoundedRectangleBorder(borderRadius: radius),
        side: BorderSide(color: border),
        foregroundColor: ink,
        backgroundColor: surface,
        textStyle: AppText.cardTitle.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSize.field),
        shape: RoundedRectangleBorder(borderRadius: radius),
        foregroundColor: primary,
        textStyle: AppText.cardTitle.copyWith(fontWeight: FontWeight.w600),
      ),
    ),

    // ── ListTile ────────────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.xxs,
      ),
      minVerticalPadding: AppSpace.xs,
    ),

    // ── Dialog ──────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: radiusLg),
      contentTextStyle: AppText.body.copyWith(color: ink),
      titleTextStyle: AppText.sectionTitle.copyWith(color: ink),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.xl,
      ),
    ),

    // ── Bottom Sheet ────────────────────────────────────────────────────────
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      showDragHandle: true,
    ),

    // ── SnackBar ─────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: surface,
      elevation: 6,
      insetPadding: const EdgeInsets.all(16),
      contentTextStyle: AppText.body.copyWith(
        color: ink,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: border),
      ),
    ),

    // ── Chip ────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      labelStyle: AppText.label,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.sm,
        vertical: AppSpace.xxs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    ),

    // ── Switch ──────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),

    // ── Divider ─────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(thickness: 1, space: 1),

    textTheme: _buildTextTheme(ink, inkMuted),
  );
}

TextTheme _buildTextTheme(Color ink, Color inkMuted) {
  return TextTheme(
    titleLarge:   AppText.screenTitle.copyWith(color: ink),
    titleMedium:  AppText.sectionTitle.copyWith(color: ink),
    titleSmall:   AppText.cardTitle.copyWith(color: ink),
    bodyMedium:   AppText.body.copyWith(color: ink),
    bodySmall:    AppText.meta.copyWith(color: inkMuted),
    labelMedium:  AppText.label.copyWith(color: ink),
    labelSmall:   AppText.meta.copyWith(color: inkMuted),
  );
}
