import 'package:flutter/material.dart';



import '../theme/app_spacing.dart';

import '../theme/app_typography.dart';

import '../theme/redesign_colors.dart';

import 'redesign_scaffold.dart';



/// Large tappable card for role selection (farm owner vs customer).

class RoleOptionCard extends StatelessWidget {

  const RoleOptionCard({

    super.key,

    required this.icon,

    required this.title,

    required this.subtitle,

    required this.onTap,

  });



  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return RedesignSurfaceCard(

      onTap: onTap,

      child: Row(

        children: [

          Container(

            width: 44,

            height: 44,

            decoration: BoxDecoration(

              color: CustomerDetailColors.accentLight,

              borderRadius: BorderRadius.circular(12),

              border: Border.all(color: CustomerDetailColors.accentBorder),

            ),

            child: Icon(icon, color: CustomerDetailColors.accent, size: 24),

          ),

          const SizedBox(width: AppSpace.md),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  title,

                  style: AppText.cardTitle.copyWith(

                    fontWeight: FontWeight.w700,

                    color: CustomerDetailColors.onSurface,

                  ),

                ),

                const SizedBox(height: AppSpace.xxs),

                Text(

                  subtitle,

                  style: AppText.meta.copyWith(

                    color: CustomerDetailColors.onSurfaceVariant,

                  ),

                ),

              ],

            ),

          ),

          Icon(Icons.chevron_right, color: CustomerDetailColors.iconMuted, size: 20),

        ],

      ),

    );

  }

}


