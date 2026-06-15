import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';



import '../../../../core/constants/app_strings.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/theme/app_typography.dart';

import '../../../../core/theme/redesign_colors.dart';

import '../../../../core/widgets/redesign_scaffold.dart';

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

    return RedesignFormScaffold(

      title: AppStrings.rolePickerTitle,

      subtitle: AppStrings.rolePickerSubtitle,

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

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

    );

  }

}


