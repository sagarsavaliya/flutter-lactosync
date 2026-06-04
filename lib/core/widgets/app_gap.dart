import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

// Token-driven spacing widgets.
// Use AppGap.sm() instead of SizedBox(height: 8).
abstract final class AppGap {
  // ── Vertical ──────────────────────────────────────────────────────────────
  static Widget xxs() => const SizedBox(height: AppSpace.xxs);
  static Widget xs()  => const SizedBox(height: AppSpace.xs);
  static Widget sm()  => const SizedBox(height: AppSpace.sm);
  static Widget md()  => const SizedBox(height: AppSpace.md);
  static Widget lg()  => const SizedBox(height: AppSpace.lg);
  static Widget xl()  => const SizedBox(height: AppSpace.xl);
  static Widget xxl() => const SizedBox(height: AppSpace.xxl);

  // ── Horizontal ────────────────────────────────────────────────────────────
  static Widget hXxs() => const SizedBox(width: AppSpace.xxs);
  static Widget hXs()  => const SizedBox(width: AppSpace.xs);
  static Widget hSm()  => const SizedBox(width: AppSpace.sm);
  static Widget hMd()  => const SizedBox(width: AppSpace.md);
  static Widget hLg()  => const SizedBox(width: AppSpace.lg);
  static Widget hXl()  => const SizedBox(width: AppSpace.xl);
  static Widget hXxl() => const SizedBox(width: AppSpace.xxl);
}
