import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../../../owner/presentation/widgets/customer_detail/customer_detail_styles.dart';

class CustomerComingSoonPage extends StatelessWidget {
  const CustomerComingSoonPage({super.key, this.fromSignup = false});

  final bool fromSignup;

  @override
  Widget build(BuildContext context) {
    return RedesignFormScaffold(
      title: AppStrings.roleCustomerTitle,
      showBack: fromSignup,
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.xl),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: CustomerDetailColors.morningChipBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: CustomerDetailColors.morningChipBorder),
              ),
              child: Icon(
                LucideIcons.hardHat,
                size: 36,
                color: CustomerDetailColors.morningChipInk,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            AppStrings.customerComingSoonTitle,
            textAlign: TextAlign.center,
            style: AppText.screenTitle.copyWith(color: CustomerDetailColors.onSurface),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            AppStrings.customerComingSoonBody,
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: CustomerDetailColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpace.xxl),
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
    );
  }
}
