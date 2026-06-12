import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/customer_order_repository.dart';
import 'customer_auth_provider.dart';

// ── Repository provider ──────────────────────────────────────────────────────

final customerOrderRepositoryProvider =
    Provider<CustomerOrderRepository>((ref) {
  return CustomerOrderRepository(
    ref.watch(customerDioProvider),
    ref.watch(customerSharedPrefsProvider),
  );
});

// ── Orders provider (family by YYYY-MM string) ───────────────────────────────

/// Fetches GET /api/customer/v1/orders?month={month}.
/// Returns the parsed `data` map: `{ month: String, days: List }`.
/// Keyed by the month string "YYYY-MM" so navigation between months works.
final customerOrdersProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, month) async {
  final repo = ref.watch(customerOrderRepositoryProvider);
  return repo.fetchOrders(month);
});
