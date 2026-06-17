import 'package:dio/dio.dart';

import '../../../auth/domain/entities/auth_session.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/session_storage.dart';
import '../../domain/entities/onboarding_models.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._dio, this._sessionStorage);

  final Dio _dio;
  final SessionStorage _sessionStorage;

  Map<String, dynamic> _readData(Map<String, dynamic>? body) {
    if (body == null || body['success'] != true) {
      throw ApiException('API_ERROR', 'Unexpected server response.');
    }
    return Map<String, dynamic>.from(body['data'] as Map);
  }

  OnboardingStatus _statusFromBody(Map<String, dynamic> data) {
    if (data.containsKey('onboarding')) {
      return OnboardingStatus.fromJson(
        Map<String, dynamic>.from(data['onboarding'] as Map),
      );
    }
    return OnboardingStatus.fromJson(data);
  }

  @override
  Future<OnboardingStatus> fetchStatus() async {
    final response = await _dio.get<Map<String, dynamic>>('/onboarding/status');
    final status = _statusFromBody(_readData(response.data));
    await updateStoredSessionOnboarding(status);
    return status;
  }

  @override
  Future<OnboardingStatus> updateFarm({
    required String name,
    required String addressLine,
    required String city,
    required String state,
    required String zip,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/onboarding/farm',
      data: {
        'name': name,
        'address_line': addressLine,
        'city': city,
        'state': state,
        'zip': zip,
      },
    );
    final status = _statusFromBody(_readData(response.data));
    await updateStoredSessionOnboarding(status);
    return status;
  }

  @override
  Future<List<ProductItem>> fetchProducts() async {
    final response = await _dio.get<Map<String, dynamic>>('/onboarding/products');
    final data = _readData(response.data);
    final list = data['products'] as List<dynamic>? ?? [];
    return list
        .map((e) => ProductItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<OnboardingStatus> saveProductsBatch(
    List<Map<String, dynamic>> products,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/onboarding/products/batch',
      data: {'products': products},
    );
    final status = _statusFromBody(_readData(response.data));
    await updateStoredSessionOnboarding(status);
    return status;
  }

  @override
  Future<SaveCustomerResult> saveCustomer(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/onboarding/customers',
      data: payload,
    );
    final data = _readData(response.data);
    final status = _statusFromBody(data);
    final customer = CustomerItem.fromJson(
      Map<String, dynamic>.from(data['customer'] as Map),
    );
    await updateStoredSessionOnboarding(status);
    return SaveCustomerResult(status: status, customer: customer);
  }

  @override
  Future<List<CustomerItem>> fetchCustomers({String search = ''}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/onboarding/customers',
      queryParameters: search.isEmpty ? null : {'search': search},
    );
    final data = _readData(response.data);
    final list = data['customers'] as List<dynamic>? ?? [];
    return list
        .map((e) => CustomerItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<OnboardingStatus> saveSubscription({
    required int customerId,
    required List<Map<String, dynamic>> lines,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/onboarding/subscriptions',
      data: {'customer_id': customerId, 'lines': lines},
    );
    final status = _statusFromBody(_readData(response.data));
    await updateStoredSessionOnboarding(status);
    return status;
  }

  @override
  Future<OnboardingStatus> skipSubscription() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/onboarding/subscriptions/skip',
    );
    final status = _statusFromBody(_readData(response.data));
    await updateStoredSessionOnboarding(status);
    return status;
  }

  @override
  Future<void> updateStoredSessionOnboarding(OnboardingStatus status) async {
    final session = await _sessionStorage.readSession();
    if (session == null) return;

    final route = _routeForStep(status.currentStep, status.isCompleted);
    final updated = AuthSession(
      token: session.token,
      ownerName: session.ownerName,
      firstName: session.firstName,
      lastName: session.lastName,
      mobile: session.mobile,
      farmId: session.farmId,
      farmName: status.farm.name ?? session.farmName,
      onboarding: OnboardingState(
        currentStep: status.currentStep,
        route: route,
        isCompleted: status.isCompleted,
        checklist: status.checklist,
      ),
    );
    await _sessionStorage.saveSession(updated);
  }

  String _routeForStep(String step, bool completed) {
    if (completed) return '/owner/home';
    return switch (step) {
      'farm_profile' => '/onboarding/farm',
      'products_setup' => '/onboarding/products',
      'first_customer' => '/onboarding/customer',
      'first_subscription' => '/onboarding/dashboard',
      _ => '/dashboard',
    };
  }
}
