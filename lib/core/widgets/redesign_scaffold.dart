import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/redesign_colors.dart';

/// Auth / onboarding form shell — frame 7 add-customer DNA.
class RedesignFormScaffold extends StatelessWidget {
  const RedesignFormScaffold({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.bottom,
    this.scrollable = true,
    this.centerBody = false,
    this.showBack = true,
    this.padding,
  });

  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? bottom;
  final bool scrollable;
  final bool centerBody;
  final bool showBack;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final bodyPadding = padding ?? const EdgeInsets.all(AppSpace.lg);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (subtitle != null) ...[
          Text(
            subtitle!,
            style: AppText.body.copyWith(color: CustomerDetailColors.bodyInk),
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        child,
      ],
    );

    if (centerBody) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (subtitle != null) ...[
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: CustomerDetailColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          child,
        ],
      );
    }

    final themed = Theme(
      data: _formTheme(context),
      child: scrollable
          ? SingleChildScrollView(
              padding: bodyPadding,
              child: content,
            )
          : Padding(
              padding: bodyPadding,
              child: content,
            ),
    );

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      appBar: title != null
          ? AppBar(
              backgroundColor: CustomerDetailColors.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: showBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      color: CustomerDetailColors.onSurface,
                      onPressed: () => context.pop(),
                    )
                  : null,
              title: Text(
                title!,
                style: AppText.screenTitle.copyWith(
                  color: CustomerDetailColors.accent,
                  fontSize: 17,
                ),
              ),
              iconTheme: const IconThemeData(color: CustomerDetailColors.onSurface),
            )
          : null,
      body: SafeArea(
        child: centerBody && !scrollable
            ? Center(child: themed)
            : themed,
      ),
      bottomNavigationBar: bottom == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Theme(data: _formTheme(context), child: bottom!),
              ),
            ),
    );
  }
}

/// White bordered surface card used across redesign screens.
class RedesignSurfaceCard extends StatelessWidget {
  const RedesignSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.radius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? CustomerDetailMetrics.sectionCardRadius;
    final inner = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpace.md),
      child: child,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: CustomerDetailColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283C28).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: onTap == null
          ? inner
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(r),
                child: inner,
              ),
            ),
    );
  }
}

ThemeData _formTheme(BuildContext context) {
  final base = Theme.of(context);
  final radius = BorderRadius.circular(12);

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(primary: CustomerDetailColors.accent),
    scaffoldBackgroundColor: CustomerDetailColors.background,
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(
          AppText.cardTitle.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CustomerDetailColors.accentLight;
          }
          return CustomerDetailColors.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CustomerDetailColors.accent;
          }
          return CustomerDetailColors.bodyInk;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: CustomerDetailColors.border),
        ),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: CustomerDetailColors.statBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: CustomerDetailColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: CustomerDetailColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: CustomerDetailColors.accent, width: 1.5),
      ),
      labelStyle: AppText.label.copyWith(
        color: CustomerDetailColors.labelMuted,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: AppText.body.copyWith(
        color: CustomerDetailColors.labelMuted,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CustomerDetailColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppText.cardTitle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CustomerDetailColors.accent,
        side: const BorderSide(color: CustomerDetailColors.accentBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppText.cardTitle.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CustomerDetailColors.accent,
        textStyle: AppText.cardTitle.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: CustomerDetailColors.surface,
      foregroundColor: CustomerDetailColors.onSurface,
    ),
  );
}
