import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/customer_profile_repository.dart';
import 'customer_auth_provider.dart';

// ── Repository provider ──────────────────────────────────────────────────────

final customerProfileRepositoryProvider =
    Provider<CustomerProfileRepository>((ref) {
  return CustomerProfileRepository(
    ref.watch(customerDioProvider),
    ref.watch(customerSharedPrefsProvider),
  );
});

// ── Profile data ─────────────────────────────────────────────────────────────

/// Holds the combined result of fetchProfile() + fetchFarmContact().
class CustomerProfileData {
  const CustomerProfileData({
    required this.profile,
    required this.farmContact,
  });

  /// Raw profile map: first_name, last_name, contact, address fields,
  /// whatsapp_enabled, active_subscriptions.
  final Map<String, dynamic> profile;

  /// Raw farm contact map: farm_name, owner_first_name, owner_last_name,
  /// owner_mobile.
  final Map<String, dynamic>? farmContact;
}

/// AsyncNotifier that loads and updates the customer's profile.
/// Invalidate via [ref.invalidate(customerProfileProvider)] to force a reload.
class CustomerProfileNotifier
    extends AsyncNotifier<CustomerProfileData> {
  @override
  Future<CustomerProfileData> build() => _load();

  Future<CustomerProfileData> _load() async {
    final repo = ref.read(customerProfileRepositoryProvider);

    // Fetch profile and farm contact concurrently.
    final results = await Future.wait([
      repo.fetchProfile(),
      repo.fetchFarmContact().catchError((_) => <String, dynamic>{}),
    ]);

    final profile = results[0] as Map<String, dynamic>;
    final contact = results[1] as Map<String, dynamic>;

    return CustomerProfileData(
      profile: profile,
      farmContact: contact.isEmpty ? null : contact,
    );
  }

  /// Reloads profile + farm contact from the API.
  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  /// Sends only [fields] to PUT /api/customer/v1/profile.
  /// On success, merges the returned profile into the current state.
  /// Throws [ApiException] on failure — callers must handle.
  Future<void> saveProfile(Map<String, dynamic> fields) async {
    final repo = ref.read(customerProfileRepositoryProvider);
    final updated = await repo.updateProfile(fields);

    // Merge the updated fields into the existing state.
    final current = state.valueOrNull;
    if (current != null) {
      final merged = {...current.profile, ...updated};
      state = AsyncData(CustomerProfileData(
        profile: merged,
        farmContact: current.farmContact,
      ));
    } else {
      // Reload from scratch if there was no prior state.
      await load();
    }
  }
}

final customerProfileProvider =
    AsyncNotifierProvider<CustomerProfileNotifier, CustomerProfileData>(
  CustomerProfileNotifier.new,
);
