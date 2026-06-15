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
    final res = await _dio.post<Map<String, dynamic>>(
      'delivery-boy/v1/auth/login',
      data: {'phone': phone.trim(), 'pin': pin.trim()},
    );
    await _saveToken(res.data);
  }

  Future<void> sendForgotPinOtp(String phone) async {
    await _dio.post<Map<String, dynamic>>(
      'delivery-boy/v1/auth/forgot-pin/send-otp',
      data: {'phone': phone.trim()},
    );
  }

  Future<String> verifyForgotPinOtp(String phone, String otp) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'delivery-boy/v1/auth/forgot-pin/verify-otp',
      data: {'phone': phone.trim(), 'otp': otp.trim()},
    );
    final data = Map<String, dynamic>.from(res.data!['data'] as Map);
    return data['reset_token'] as String;
  }

  /// Resets PIN after OTP verification and stores the new session token.
  Future<void> resetForgotPin({
    required String phone,
    required String resetToken,
    required String pin,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      'delivery-boy/v1/auth/forgot-pin/reset',
      data: {
        'phone': phone.trim(),
        'reset_token': resetToken,
        'pin': pin.trim(),
        'pin_confirmation': pin.trim(),
      },
    );
    await _saveToken(res.data);
  }

  Future<void> _saveToken(Map<String, dynamic>? body) async {
    if (body == null || body['success'] != true) {
      throw ApiException('API_ERROR', 'Unexpected server response.');
    }
    final data = body['data'] as Map<String, dynamic>?;
    final token = data?['token'];
    if (token == null || token is! String || token.isEmpty) {
      throw ApiException('API_ERROR', 'No token in server response.');
    }
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
