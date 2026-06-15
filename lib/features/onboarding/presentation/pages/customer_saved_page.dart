import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../../core/constants/app_strings.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/theme/app_typography.dart';

import '../../../../core/theme/redesign_colors.dart';

import '../../../../core/widgets/app_button.dart';

import '../../../../core/widgets/redesign_scaffold.dart';

import '../providers/onboarding_provider.dart';



class CustomerSavedPage extends ConsumerWidget {

  const CustomerSavedPage({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    ref.watch(subscriptionBootstrapProvider);



    return RedesignFormScaffold(

      title: AppStrings.customerSavedTitle,

      scrollable: false,

      bottom: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

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

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          const SizedBox(height: AppSpace.xl),

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

          Text(

            AppStrings.customerSavedSubtitle,

            textAlign: TextAlign.center,

            style: AppText.body.copyWith(color: CustomerDetailColors.onSurfaceVariant),

          ),

        ],

      ),

    );

  }

}


