import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_exception.dart';

const _customerTokenKey = 'customer_auth_token';

/// Wraps profile-related API calls for the customer guard.
/// GET /api/customer/v1/profile
/// PUT /api/customer/v1/profile
/// GET /api/customer/v1/farm-contact
class CustomerProfileRepository {
  CustomerProfileRepository(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;

  Options get _authOptions {
    final token = _prefs.getString(_customerTokenKey);
    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
  }

  // ── Profile ─────────────────────────────────────────────────────────────────

  /// GET /api/customer/v1/profile
  /// Returns the `profile` object from the API envelope.
  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/customer/v1/profile',
      options: _authOptions,
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw ApiException('API_ERROR', 'Unexpected profile response.');
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('API_ERROR', 'Invalid profile data format.');
    }

    final profile = data['profile'];
    if (profile is Map<String, dynamic>) {
      return profile;
    }

    // Some API versions return profile fields at the data root.
    if (data.containsKey('first_name') || data.containsKey('contact')) {
      return data;
    }

    throw ApiException('API_ERROR', 'Profile key missing in response.');
  }

  /// PUT /api/customer/v1/profile
  /// Sends only the [fields] that changed.
  /// Returns the updated `profile` object.
  /// Throws [ApiException] on failure (including ADDRESS_RATE_LIMITED).
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> fields) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/customer/v1/profile',
      data: fields,
      options: _authOptions,
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw ApiException('API_ERROR', 'Unexpected update profile response.');
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('API_ERROR', 'Invalid profile update data format.');
    }

    final profile = data['profile'];
    if (profile is! Map<String, dynamic>) {
      return data; // fallback: return the data map
    }

    return profile;
  }

  // ── Farm contact ─────────────────────────────────────────────────────────────

  /// GET /api/customer/v1/farm-contact
  /// Returns the farm contact data map from the API envelope.
  Future<Map<String, dynamic>> fetchFarmContact() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/customer/v1/farm-contact',
      options: _authOptions,
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw ApiException('API_ERROR', 'Unexpected farm contact response.');
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('API_ERROR', 'Invalid farm contact data format.');
    }

    return data;
  }
}
