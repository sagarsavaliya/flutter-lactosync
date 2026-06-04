import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';

class CustomerComingSoonPage extends StatelessWidget {
  const CustomerComingSoonPage({super.key, this.fromSignup = false});

  final bool fromSignup;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.roleCustomerTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpace.xl),
              const Center(
                child: Icon(
                  Icons.construction_outlined,
                  size: 56,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                AppStrings.customerComingSoonTitle,
                textAlign: TextAlign.center,
                style: AppText.sectionTitle,
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                AppStrings.customerComingSoonBody,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: inkMuted),
              ),
              const Spacer(),
              if (fromSignup)
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text(AppStrings.rolePickerBack),
                ),
              if (fromSignup) const SizedBox(height: AppSpace.sm),
              AppButton(
                label: AppStrings.goToSignIn,
                onPressed: () => context.go('/sign-in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
