import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/customer_billing_repository.dart';
import 'customer_auth_provider.dart';

// ── Repository provider ──────────────────────────────────────────────────────

final customerBillingRepositoryProvider =
    Provider<CustomerBillingRepository>((ref) {
  return CustomerBillingRepository(ref.watch(customerDioProvider));
});

// ── Bills list provider ──────────────────────────────────────────────────────

/// Fetches the customer's bill list from GET /api/customer/v1/bills.
/// Ordered by billing_month descending (server-side).
final customerBillsProvider =
    FutureProvider<List<CustomerBill>>((ref) async {
  final repo = ref.watch(customerBillingRepositoryProvider);
  return repo.fetchBills();
});

// ── Payments list provider ───────────────────────────────────────────────────

/// Fetches the customer's payment list from GET /api/customer/v1/payments.
/// Ordered by payment_date descending (server-side).
final customerPaymentsProvider =
    FutureProvider<List<CustomerPayment>>((ref) async {
  final repo = ref.watch(customerBillingRepositoryProvider);
  return repo.fetchPayments();
});
