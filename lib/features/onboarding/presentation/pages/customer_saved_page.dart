import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/onboarding_provider.dart';

class CustomerSavedPage extends ConsumerWidget {
  const CustomerSavedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prefetch subscription data so the next screen opens quickly.
    ref.watch(subscriptionBootstrapProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.customerSavedTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpace.xl),
              const Center(
                child: Icon(
                  Icons.check_circle_outline,
                  size: 56,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                AppStrings.customerSavedSubtitle,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: inkMuted),
              ),
              const Spacer(),
              AppButton(
                label: AppStrings.createSubscription,
                onPressed: () => context.go('/onboarding/subscription'),
              ),
              const SizedBox(height: AppSpace.sm),
              OutlinedButton(
                onPressed: () => context.push('/onboarding/customer?another=1'),
                child: const Text(AppStrings.addAnotherCustomer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
