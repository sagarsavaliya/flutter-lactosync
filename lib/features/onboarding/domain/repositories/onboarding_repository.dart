import '../entities/onboarding_models.dart';

abstract class OnboardingRepository {
  Future<OnboardingStatus> fetchStatus();
  Future<OnboardingStatus> updateFarm({
    required String name,
    required String addressLine,
    required String city,
    required String state,
    required String zip,
  });
  Future<List<ProductItem>> fetchProducts();
  Future<OnboardingStatus> saveProductsBatch(List<Map<String, dynamic>> products);
  Future<SaveCustomerResult> saveCustomer(Map<String, dynamic> payload);
  Future<List<CustomerItem>> fetchCustomers({String search = ''});
  Future<OnboardingStatus> saveSubscription({
    required int customerId,
    required List<Map<String, dynamic>> lines,
  });
  Future<OnboardingStatus> skipSubscription();
  Future<void> updateStoredSessionOnboarding(OnboardingStatus status);
}
