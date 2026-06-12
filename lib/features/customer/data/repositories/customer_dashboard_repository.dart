import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_exception.dart';

const _customerTokenKey = 'customer_auth_token';

/// Wraps the GET /api/customer/v1/dashboard Dio call.
/// Injects the customer_auth_token as an Authorization: Bearer header.
class CustomerDashboardRepository {
  CustomerDashboardRepository(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;

  /// Fetches the authenticated customer's dashboard data.
  /// Returns the parsed [data] map from the API envelope `{success, data}`.
  /// Throws [ApiException] on failure.
  Future<Map<String, dynamic>> fetchDashboard() async {
    final token = _prefs.getString(_customerTokenKey);

    final response = await _dio.get<Map<String, dynamic>>(
      '/customer/v1/dashboard',
      options: Options(
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      ),
    );

    final body = response.data;
    if (body == null || body['success'] != true) {
      throw ApiException('API_ERROR', 'Unexpected dashboard response.');
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('API_ERROR', 'Invalid dashboard data format.');
    }
    return data;
  }
}
