import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_logo.dart';
import '../../customer/presentation/providers/customer_auth_provider.dart';
import '../../delivery_boy/presentation/providers/delivery_boy_auth_provider.dart';
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

    // Check owner session first (owners take priority on this device).
    final session = await ref.read(authRepositoryProvider).readStoredSession();
    if (!mounted) return;

    if (session != null) {
      if (session.onboarding.isCompleted) {
        context.go('/dashboard');
      } else {
        context.go(session.onboardingRoute);
      }
      return;
    }

    // No owner session — check for a delivery boy session.
    final isDeliveryBoyLoggedIn =
        ref.read(deliveryBoyAuthRepositoryProvider).isLoggedIn;
    if (!mounted) return;

    if (isDeliveryBoyLoggedIn) {
      context.go('/delivery-boy/home');
      return;
    }

    // No delivery boy session — check for a customer session.
    final isCustomerLoggedIn =
        await ref.read(customerAuthRepositoryProvider).isLoggedIn;
    if (!mounted) return;

    if (isCustomerLoggedIn) {
      context.go('/customer/home');
      return;
    }

    context.go('/sign-in');
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
