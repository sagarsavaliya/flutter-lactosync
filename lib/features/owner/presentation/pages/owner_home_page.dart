import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/owner_provider.dart';
import '../widgets/dashboard/dashboard_delivery_section.dart';
import '../widgets/dashboard/dashboard_kpi_card.dart';
import '../widgets/dashboard/dashboard_quick_actions.dart';
import '../widgets/dashboard/dashboard_styles.dart';

class OwnerHomePage extends ConsumerWidget {
  const OwnerHomePage({super.key});

  static String _greeting(String ownerName) {
    final firstName = ownerName.trim().split(RegExp(r'\s+')).first;
    if (firstName.isEmpty) return AppStrings.dashboardNamasteFallback;
    return '${AppStrings.dashboardNamaste}, $firstName';
  }

  static String _subscriptionFooter(int paused) {
    if (paused == 0) return '0 paused · all active';
    return '$paused ${AppStrings.kpiPaused}';
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
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 6, 2, 14),
                  child: Text(
                    _greeting(session.ownerName),
                    style: DashboardText.greeting,
                  ),
                ),
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
                              footerLabel:
                                  '${stats.customers.inactive} ${AppStrings.kpiInactive}',
                              progressColor: DashboardColors.primary,
                              footerDotColor: const Color(0xFFD98A2B),
                              footerTextColor: const Color(0xFFA06A1E),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DashboardKpiCard(
                              icon: Icons.loyalty_outlined,
                              title: AppStrings.kpiSubscriptions,
                              total: stats.subscriptions.total,
                              primaryValue: stats.subscriptions.active,
                              footerLabel: _subscriptionFooter(
                                  stats.subscriptions.paused),
                              progressColor: DashboardColors.primary,
                              footerDotColor: const Color(0xFF84C68E),
                              footerTextColor: stats.subscriptions.paused == 0
                                  ? DashboardColors.primary
                                  : DashboardColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (stats.milkPreparation != null) ...[
                        const SizedBox(height: 18),
                        DashboardDeliverySection(
                          title: AppStrings.milkPrepMorningTitle,
                          isMorning: true,
                          totalLiters:
                              stats.milkPreparation!.morningTotalLiters,
                          statusTag: AppStrings.dashboardToday,
                          cards: stats.milkPreparation!.morning,
                          onProductTap: (product) => context.push(
                            '/owner/milk-prep/customers?shift=morning&product_id=${product.productId}&product_name=${Uri.encodeComponent(product.productName)}',
                          ),
                        ),
                        DashboardDeliverySection(
                          title: AppStrings.milkPrepEveningTitle,
                          isMorning: false,
                          totalLiters:
                              stats.milkPreparation!.eveningTotalLiters,
                          statusTag: AppStrings.dashboardScheduled,
                          cards: stats.milkPreparation!.evening,
                          onProductTap: (product) => context.push(
                            '/owner/milk-prep/customers?shift=evening&product_id=${product.productId}&product_name=${Uri.encodeComponent(product.productName)}',
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      const DashboardQuickActions(),
                    ],
                  ),
                  loading: () => const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                          color: DashboardColors.primary),
                    ),
                  ),
                  error: (_, __) => Text(
                    AppStrings.dashboardLoadError,
                    style: DashboardText.productName
                        .copyWith(color: DashboardColors.error),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: DashboardColors.primary)),
      error: (_, __) =>
          const Center(child: Text(AppStrings.dashboardSessionError)),
    );
  }
}
