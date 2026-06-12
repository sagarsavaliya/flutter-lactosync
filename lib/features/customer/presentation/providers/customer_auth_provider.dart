import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/repositories/customer_auth_repository.dart';

// ── Shared-prefs provider (initialised in main) ─────────────────────────────

final customerSharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override customerSharedPrefsProvider in main()');
});

// ── Customer Dio (injects customer_auth_token) ───────────────────────────────

/// A separate Dio instance for all authenticated customer API calls.
/// It reads the `customer_auth_token` from SharedPreferences and attaches it
/// as a Bearer token — completely independent of the owner app's dioProvider.
final customerDioProvider = Provider<Dio>((ref) {
  final prefs = ref.watch(customerSharedPrefsProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrlCustomer,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = prefs.getString('customer_auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final data = error.response?.data;
        if (data is Map<String, dynamic> && data['success'] == false) {
          final err = data['error'];
          if (err is Map<String, dynamic>) {
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: error.type,
                error: ApiException(
                  err['code']?.toString() ?? 'API_ERROR',
                  err['message']?.toString() ?? 'Something went wrong.',
                  statusCode: error.response?.statusCode,
                ),
              ),
            );
            return;
          }
        }

        final status = error.response?.statusCode;
        if (status == 429) {
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: ApiException(
                'RATE_LIMITED',
                'Too many attempts. Please wait a few minutes and try again.',
                statusCode: 429,
              ),
            ),
          );
          return;
        }

        handler.next(error);
      },
    ),
  );

  return dio;
});

// ── Repository provider ──────────────────────────────────────────────────────

final customerAuthRepositoryProvider = Provider<CustomerAuthRepository>((ref) {
  return CustomerAuthRepository(
    ref.watch(customerDioProvider),
    ref.watch(customerSharedPrefsProvider),
  );
});

// ── Auth state ───────────────────────────────────────────────────────────────

/// Simple async check: is there a stored customer_auth_token?
final customerIsLoggedInProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(customerAuthRepositoryProvider);
  return repo.isLoggedIn;
});
