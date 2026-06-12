import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_exception.dart';

/// Token storage key for the customer guard.
/// Must NOT collide with the owner app's 'auth_token' key.
const _customerTokenKey = 'customer_auth_token';

/// Wraps all unauthenticated customer auth API calls and customer token storage.
/// Does not share any state with the owner auth repository.
class CustomerAuthRepository {
  CustomerAuthRepository(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;

  // ── Token helpers ───────────────────────────────────────────────────────────

  Future<String?> getToken() async => _prefs.getString(_customerTokenKey);

  Future<void> _saveToken(String token) async {
    await _prefs.setString(_customerTokenKey, token);
  }

  Future<void> logout() async {
    await _prefs.remove(_customerTokenKey);
  }

  Future<bool> get isLoggedIn async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Auth API calls ──────────────────────────────────────────────────────────

  /// POST /api/customer/v1/auth/send-otp
  /// Sends a 6-digit OTP to the customer's WhatsApp.
  /// Throws [ApiException] on failure.
  Future<void> sendOtp(String contact) async {
    await _dio.post<Map<String, dynamic>>(
      '/customer/v1/auth/send-otp',
      data: {'contact': contact},
    );
  }

  /// POST /api/customer/v1/auth/verify-otp
  /// Verifies the OTP entered by the customer.
  /// Throws [ApiException] on invalid/expired OTP.
  Future<void> verifyOtp(String contact, String otp) async {
    await _dio.post<Map<String, dynamic>>(
      '/customer/v1/auth/verify-otp',
      data: {'contact': contact, 'otp': otp},
    );
  }

  /// POST /api/customer/v1/auth/set-pin
  /// Sets the customer's 4-digit PIN after OTP verification.
  /// Stores the returned Sanctum token under [_customerTokenKey].
  Future<void> setPin(String contact, String pin) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/customer/v1/auth/set-pin',
      data: {'contact': contact, 'pin': pin},
    );
    final token = _extractToken(response.data);
    await _saveToken(token);
  }

  /// POST /api/customer/v1/auth/login
  /// Authenticates with contact + PIN and stores the Sanctum token.
  Future<void> login(String contact, String pin) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/customer/v1/auth/login',
      data: {'contact': contact, 'pin': pin},
    );
    final token = _extractToken(response.data);
    await _saveToken(token);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _extractToken(Map<String, dynamic>? body) {
    if (body == null || body['success'] != true) {
      throw ApiException('API_ERROR', 'Unexpected server response.');
    }
    final data = Map<String, dynamic>.from(body['data'] as Map);
    final token = data['token'];
    if (token == null || token is! String || token.isEmpty) {
      throw ApiException('API_ERROR', 'No token in server response.');
    }
    return token;
  }
}
