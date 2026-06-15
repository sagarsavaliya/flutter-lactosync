import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../../domain/entities/onboarding_models.dart';

class SetupDashboardPage extends StatelessWidget {
  const SetupDashboardPage({
    super.key,
    required this.status,
    this.showSkipSubscription = false,
    this.onSkipSubscription,
  });

  final OnboardingStatus status;
  final bool showSkipSubscription;
  final VoidCallback? onSkipSubscription;

  @override
  Widget build(BuildContext context) {
    final checklist = status.checklist;

    return RedesignFormScaffold(
      title: AppStrings.setupTitle,
      subtitle: AppStrings.setupSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SetupTile(
            title: AppStrings.setupFarmDone,
            done: checklist['farm_profile'] == true,
            onTap: checklist['farm_profile'] == true
                ? null
                : () => context.push('/onboarding/farm'),
          ),
          const SizedBox(height: AppSpace.sm),
          _SetupTile(
            title: AppStrings.setupProducts,
            done: checklist['products_setup'] == true,
            onTap: checklist['products_setup'] == true
                ? null
                : () => context.push('/onboarding/products'),
          ),
          const SizedBox(height: AppSpace.sm),
          _SetupTile(
            title: AppStrings.setupCustomer,
            done: checklist['first_customer'] == true,
            onTap: checklist['first_customer'] == true
                ? null
                : () => context.push('/onboarding/customer'),
          ),
          const SizedBox(height: AppSpace.sm),
          _SetupTile(
            title: AppStrings.setupSubscription,
            done: checklist['first_subscription'] == true,
            onTap: checklist['first_subscription'] == true
                ? null
                : () => context.push('/onboarding/subscription'),
          ),
          if (showSkipSubscription && checklist['first_subscription'] != true) ...[
            const SizedBox(height: AppSpace.lg),
            TextButton(
              onPressed: onSkipSubscription,
              child: const Text(AppStrings.skipForNow),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetupTile extends StatelessWidget {
  const _SetupTile({
    required this.title,
    required this.done,
    this.onTap,
  });

  final String title;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RedesignSurfaceCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: done ? CustomerDetailColors.success : CustomerDetailColors.iconMuted,
            size: 22,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              title,
              style: AppText.cardTitle.copyWith(
                fontWeight: FontWeight.w700,
                color: done
                    ? CustomerDetailColors.onSurfaceVariant
                    : CustomerDetailColors.onSurface,
              ),
            ),
          ),
          if (done)
            AppChip(label: AppStrings.setupDone, status: AppChipStatus.success)
          else if (onTap != null)
            Icon(Icons.chevron_right, color: CustomerDetailColors.iconMuted, size: 20),
        ],
      ),
    );
  }
}
