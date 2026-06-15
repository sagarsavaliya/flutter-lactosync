import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/customer_billing_repository.dart';
import '../providers/customer_billing_provider.dart';
import '../providers/customer_dashboard_provider.dart';
import '../widgets/customer_dashboard_styles.dart';
import '../widgets/customer_payments_widgets.dart';
import '../widgets/customer_subscription_adapter.dart';

class CustomerPaymentsPage extends ConsumerWidget {
  const CustomerPaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(customerDashboardProvider);
    final billsAsync = ref.watch(customerBillsProvider);
    final paymentsAsync = ref.watch(customerPaymentsProvider);
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: CusDashColors.background,
      body: RefreshIndicator(
        color: CusDashColors.accent,
        onRefresh: () async {
          ref.invalidate(customerDashboardProvider);
          ref.invalidate(customerBillsProvider);
          ref.invalidate(customerPaymentsProvider);
          await Future.wait([
            ref.read(customerDashboardProvider.future).catchError((_) => <String, dynamic>{}),
            ref.read(customerBillsProvider.future).catchError((_) => <CustomerBill>[]),
            ref.read(customerPaymentsProvider.future).catchError((_) => <CustomerPayment>[]),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: CusPaymentsHeader()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: CusDashMetrics.horizontalPad),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  dashAsync.when(
                    data: (data) {
                      final balance =
                          (data['outstanding_balance'] as num?)?.toDouble() ?? 0.0;
                      final upiVpa = data['upi_vpa'] as String?;
                      final upiPayeeName = data['upi_payee_name'] as String?;
                      final hero = cusBillHeroLabels(billsAsync.valueOrNull, now);

                      if (balance <= 0) return const SizedBox.shrink();

                      return Column(
                        children: [
                          CusPaymentsPendingHero(
                            balance: balance,
                            billLabel: hero.billLabel,
                            dueLabel: hero.dueLabel,
                            upiVpa: upiVpa,
                            upiPayeeName: upiPayeeName,
                          ),
                          const SizedBox(height: 14),
                          CusPaymentsQuickActions(
                            balance: balance,
                            upiVpa: upiVpa,
                            upiPayeeName: upiPayeeName,
                          ),
                          const SizedBox(height: CusDashMetrics.sectionGap),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const CusPaymentsSectionLabel(title: 'BILLS'),
                  billsAsync.when(
                    data: (bills) {
                      if (bills.isEmpty) {
                        return const CusPaymentsEmptyCard(message: 'No bills yet.');
                      }

                      final consumption = dashAsync.valueOrNull?['consumption']
                          as Map<String, dynamic>?;
                      final rows = customerConsumptionRowsFromJson(consumption);
                      final currentLiters =
                          rows.fold<double>(0, (sum, r) => sum + r.totalQuantity);

                      return Column(
                        children: [
                          for (final bill in bills)
                            CusPaymentsBillRow(
                              bill: bill,
                              isCurrent: bill.billingMonth == monthKey,
                              subtitle: cusBillSubtitle(
                                bill: bill,
                                isCurrent: bill.billingMonth == monthKey,
                                currentLiters: currentLiters,
                              ),
                            ),
                        ],
                      );
                    },
                    loading: () => const CusPaymentsLoadingCard(),
                    error: (_, __) => const CusPaymentsEmptyCard(
                      message: 'Could not load bills.',
                    ),
                  ),
                  const CusPaymentsSectionLabel(title: 'PAYMENT HISTORY'),
                  paymentsAsync.when(
                    data: (payments) {
                      if (payments.isEmpty) {
                        return const CusPaymentsEmptyCard(
                          message: 'No payments recorded yet.',
                        );
                      }
                      return Column(
                        children: [
                          for (final payment in payments)
                            CusPaymentsHistoryRow(payment: payment),
                        ],
                      );
                    },
                    loading: () => const CusPaymentsLoadingCard(),
                    error: (_, __) => const CusPaymentsEmptyCard(
                      message: 'Could not load payment history.',
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
