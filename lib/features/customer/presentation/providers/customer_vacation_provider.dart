import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/customer_vacation_repository.dart';
import 'customer_auth_provider.dart';

// ── Repository provider ───────────────────────────────────────────────────────

final customerVacationRepositoryProvider =
    Provider<CustomerVacationRepository>((ref) {
  return CustomerVacationRepository(ref.watch(customerDioProvider));
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class CustomerVacationNotifier extends AsyncNotifier<VacationData?> {
  @override
  Future<VacationData?> build() => _fetch();

  CustomerVacationRepository get _repo =>
      ref.read(customerVacationRepositoryProvider);

  Future<VacationData?> _fetch() async {
    final data = await _repo.fetchVacation();
    return data;
  }

  /// Re-loads vacation state from the API.
  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Sets a vacation by posting to the API, then refreshes state.
  /// Returns `null` on success or an error [String] to display to the user.
  Future<String?> setVacation(String start, String end) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.setVacation(start, end);
      state = AsyncData(result);
      return null;
    } catch (e) {
      // Restore the previous state (no vacation) so the form is still shown.
      state = const AsyncData(VacationData(start: null, end: null));
      return e.toString();
    }
  }

  /// Cancels the active vacation, then refreshes state.
  /// Returns `null` on success or an error [String] to display to the user.
  Future<String?> cancel() async {
    state = const AsyncLoading();
    try {
      await _repo.cancelVacation();
      state = const AsyncData(VacationData(start: null, end: null));
      return null;
    } catch (e) {
      // Reload to get the actual server state.
      state = await AsyncValue.guard(_fetch);
      return e.toString();
    }
  }
}

/// Provider for the vacation notifier. Watch this on the vacation page.
final customerVacationProvider =
    AsyncNotifierProvider<CustomerVacationNotifier, VacationData?>(
  CustomerVacationNotifier.new,
);
