import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/onboarding_repository_impl.dart';
import '../../domain/entities/onboarding_models.dart';
import '../../domain/repositories/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(sessionStorageProvider),
  );
});

typedef SubscriptionBootstrap = ({
  List<CustomerItem> customers,
  List<ProductItem> products,
});

/// Loads customers and products in parallel for the subscription screen.
final subscriptionBootstrapProvider = FutureProvider<SubscriptionBootstrap>((ref) async {
  final repo = ref.watch(onboardingRepositoryProvider);
  final results = await Future.wait([
    repo.fetchCustomers(),
    repo.fetchProducts(),
  ]);
  return (
    customers: results[0] as List<CustomerItem>,
    products: results[1] as List<ProductItem>,
  );
});
