import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../owner/presentation/widgets/owner_design_system.dart';
import '../../domain/entities/onboarding_models.dart';

enum CustomerSavedAction { setupSubscription, addAnother }

Future<CustomerSavedAction?> showCustomerSavedSheet(
  BuildContext context, {
  required CustomerItem customer,
}) {
  return showOwnerBottomSheet<CustomerSavedAction>(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CustomerDetailColors.successBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: CustomerDetailColors.accentBorder),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 40,
              color: CustomerDetailColors.success,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        OwnerSheetTitle(
          AppStrings.customerSavedTitle,
          subtitle: '${customer.fullName} · ${customer.contact}',
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          AppStrings.customerSavedSubtitle,
          style: AppText.body.copyWith(color: CustomerDetailColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpace.lg),
        AppButton(
          label: AppStrings.createSubscription,
          onPressed: () => Navigator.pop(context, CustomerSavedAction.setupSubscription),
        ),
        const SizedBox(height: AppSpace.sm),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, CustomerSavedAction.addAnother),
          child: const Text(AppStrings.addAnotherCustomer),
        ),
      ],
    ),
  );
}

void openSubscriptionForCustomer(BuildContext context, CustomerItem customer) {
  context.go(
    '/onboarding/subscription',
    extra: {
      'lockedCustomerId': customer.id,
      'prefilledCustomer': customer,
    },
  );
}
