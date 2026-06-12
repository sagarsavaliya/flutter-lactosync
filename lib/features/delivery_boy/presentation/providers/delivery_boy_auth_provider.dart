import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_exception.dart';

const _kTokenKey = 'delivery_boy_auth_token';

// ── SharedPrefs override (initialised in main) ───────────────────────────────

final deliveryBoySharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override deliveryBoySharedPrefsProvider in main()');
});

// ── Delivery Boy Dio ──────────────────────────────────────────────────────────

final deliveryBoyDioProvider = Provider<Dio>((ref) {
  final prefs = ref.watch(deliveryBoySharedPrefsProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrlDeliveryBoy,
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
        final token = prefs.getString(_kTokenKey);
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
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: ApiException(
                err['code']?.toString() ?? 'API_ERROR',
                err['message']?.toString() ?? 'Something went wrong.',
                statusCode: error.response?.statusCode,
              ),
            ));
            return;
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

// ── Auth repository ───────────────────────────────────────────────────────────

class DeliveryBoyAuthRepository {
  const DeliveryBoyAuthRepository(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;

  Future<void> login(String phone, String pin) async {
    final res = await _dio.post('delivery-boy/v1/auth/login', data: {
      'phone': phone.trim(),
      'pin': pin.trim(),
    });
    final token = res.data['data']['token'] as String;
    await _prefs.setString(_kTokenKey, token);
  }

  Future<void> changePin(String currentPin, String newPin) async {
    await _dio.post('delivery-boy/v1/auth/change-pin', data: {
      'current_pin': currentPin.trim(),
      'new_pin': newPin.trim(),
    });
  }

  Future<void> logout() async {
    try {
      await _dio.post('delivery-boy/v1/auth/logout');
    } finally {
      await _prefs.remove(_kTokenKey);
    }
  }

  bool get isLoggedIn {
    final token = _prefs.getString(_kTokenKey);
    return token != null && token.isNotEmpty;
  }
}

final deliveryBoyAuthRepositoryProvider =
    Provider<DeliveryBoyAuthRepository>((ref) {
  return DeliveryBoyAuthRepository(
    ref.watch(deliveryBoyDioProvider),
    ref.watch(deliveryBoySharedPrefsProvider),
  );
});

final deliveryBoyIsLoggedInProvider = Provider<bool>((ref) {
  final repo = ref.watch(deliveryBoyAuthRepositoryProvider);
  return repo.isLoggedIn;
});
