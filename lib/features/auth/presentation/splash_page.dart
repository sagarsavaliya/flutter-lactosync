import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/redesign_colors.dart';
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

    final isDeliveryBoyLoggedIn =
        ref.read(deliveryBoyAuthRepositoryProvider).isLoggedIn;
    if (!mounted) return;

    if (isDeliveryBoyLoggedIn) {
      context.go('/delivery-boy/pickup');
      return;
    }

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
    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CustomerDetailColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: CustomerDetailColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: CustomerDetailColors.accent.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/branding/app_icon.png',
                    width: 64,
                    height: 64,
                    errorBuilder: (_, __, ___) => const AppLogo(size: 48),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Text(
                  AppStrings.appName,
                  style: AppText.screenTitle.copyWith(
                    color: CustomerDetailColors.accent,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  AppStrings.appTagline,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(
                    color: CustomerDetailColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpace.xl),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: CustomerDetailColors.accent,
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
