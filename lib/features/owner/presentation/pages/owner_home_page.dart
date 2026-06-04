import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../../core/constants/app_strings.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

import '../providers/owner_provider.dart';

import '../widgets/dashboard/dashboard_kpi_card.dart';

import '../widgets/dashboard/dashboard_quick_actions.dart';

import '../widgets/dashboard/dashboard_styles.dart';

import '../widgets/milk_preparation_panel.dart';



class OwnerHomePage extends ConsumerWidget {

  const OwnerHomePage({super.key});



  static String _greeting(String ownerName) {

    final firstName = ownerName.trim().split(RegExp(r'\s+')).first;

    if (firstName.isEmpty) return AppStrings.dashboardNamasteFallback;

    return '${AppStrings.dashboardNamaste}, $firstName';

  }



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final sessionAsync = ref.watch(authSessionProvider);

    final statsAsync = ref.watch(ownerDashboardProvider);



    return sessionAsync.when(

      data: (session) {

        if (session == null) {

          WidgetsBinding.instance.addPostFrameCallback((_) {

            if (context.mounted) context.go('/sign-in');

          });

          return const SizedBox.shrink();

        }



        return ColoredBox(

          color: DashboardColors.background,

          child: RefreshIndicator(

            color: DashboardColors.primary,

            onRefresh: () async {

              ref.invalidate(ownerDashboardProvider);

              await ref.read(ownerDashboardProvider.future);

            },

            child: ListView(

              padding: const EdgeInsets.fromLTRB(

                DashboardSpace.page,

                DashboardSpace.sm,

                DashboardSpace.page,

                120,

              ),

              children: [

                Text(_greeting(session.ownerName), style: DashboardText.greeting),

                const SizedBox(height: DashboardSpace.section),

                statsAsync.when(

                  data: (stats) => Column(

                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [

                      Row(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Expanded(

                            child: DashboardKpiCard(

                              icon: Icons.group_outlined,

                              title: AppStrings.kpiCustomers,

                              total: stats.customers.total,

                              primaryValue: stats.customers.active,

                              footerLabel: '${stats.customers.inactive} ${AppStrings.kpiInactive}',

                              progressColor: DashboardColors.primary,

                              footerColor: DashboardColors.error,

                            ),

                          ),

                          const SizedBox(width: DashboardSpace.sm),

                          Expanded(

                            child: DashboardKpiCard(

                              icon: Icons.loyalty_outlined,

                              title: AppStrings.kpiSubscriptions,

                              total: stats.subscriptions.total,

                              primaryValue: stats.subscriptions.active,

                              footerLabel: '${stats.subscriptions.paused} ${AppStrings.kpiPaused}',

                              progressColor: DashboardColors.secondary,

                              footerColor: DashboardColors.onSurfaceVariant.withValues(alpha: 0.6),

                            ),

                          ),

                        ],

                      ),

                      if (stats.milkPreparation != null) ...[

                        const SizedBox(height: DashboardSpace.section),

                        MilkPreparationPanel(summary: stats.milkPreparation!),

                      ],

                      const SizedBox(height: DashboardSpace.section),

                      const DashboardQuickActions(),

                    ],

                  ),

                  loading: () => const SizedBox(

                    height: 160,

                    child: Center(child: CircularProgressIndicator(color: DashboardColors.primary)),

                  ),

                  error: (_, __) => Text(

                    AppStrings.dashboardLoadError,

                    style: DashboardText.productName.copyWith(color: DashboardColors.error),

                  ),

                ),

              ],

            ),

          ),

        );

      },

      loading: () => const Center(child: CircularProgressIndicator(color: DashboardColors.primary)),

      error: (_, __) => const Center(child: Text(AppStrings.dashboardSessionError)),

    );

  }

}


