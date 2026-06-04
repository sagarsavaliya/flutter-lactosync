import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_logo.dart';
import 'providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final session = await ref.read(authRepositoryProvider).readStoredSession();
    if (!mounted) return;

    if (session == null) {
      context.go('/sign-in');
      return;
    }

    if (session.onboarding.isCompleted) {
      context.go('/dashboard');
      return;
    }

    context.go(session.onboardingRoute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.darkInk : AppColors.ink;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/branding/app_icon.png',
                  width: 88,
                  height: 88,
                  errorBuilder: (_, __, ___) => const AppLogo(size: 56),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  AppStrings.appName,
                  style: AppText.screenTitle.copyWith(color: ink, fontSize: 20),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  AppStrings.appTagline,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: inkMuted),
                ),
                const SizedBox(height: AppSpace.xl),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
