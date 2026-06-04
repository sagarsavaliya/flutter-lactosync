import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/role_option_card.dart';

class RolePickerPage extends StatelessWidget {
  const RolePickerPage({
    super.key,
    required this.mobile,
    required this.signupToken,
  });

  final String mobile;
  final String signupToken;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.rolePickerTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.rolePickerSubtitle,
                style: AppText.body.copyWith(color: inkMuted),
              ),
              const SizedBox(height: AppSpace.lg),
              RoleOptionCard(
                icon: Icons.storefront_outlined,
                title: AppStrings.roleFarmOwnerTitle,
                subtitle: AppStrings.roleFarmOwnerSubtitle,
                onTap: () => context.push(
                  '/signup/set-pin',
                  extra: {
                    'mobile': mobile,
                    'signup_token': signupToken,
                    'role': 'farm_owner',
                  },
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              RoleOptionCard(
                icon: Icons.local_drink_outlined,
                title: AppStrings.roleCustomerTitle,
                subtitle: AppStrings.roleCustomerSubtitle,
                onTap: () => context.push(
                  '/customer/coming-soon',
                  extra: {'from': 'signup'},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
