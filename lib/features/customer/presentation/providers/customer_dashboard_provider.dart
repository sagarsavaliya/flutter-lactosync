import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/customer_dashboard_repository.dart';
import 'customer_auth_provider.dart';

// ── Repository provider ──────────────────────────────────────────────────────

final customerDashboardRepositoryProvider =
    Provider<CustomerDashboardRepository>((ref) {
  return CustomerDashboardRepository(
    ref.watch(customerDioProvider),
    ref.watch(customerSharedPrefsProvider),
  );
});

// ── Dashboard data provider ──────────────────────────────────────────────────

/// Fetches GET /api/customer/v1/dashboard.
/// Returns the parsed `data` map from the API envelope.
final customerDashboardProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(customerDashboardRepositoryProvider);
  return repo.fetchDashboard();
});
