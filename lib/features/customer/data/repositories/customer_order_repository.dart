import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_exception.dart';

const _customerTokenKey = 'customer_auth_token';

/// Wraps all order-related API calls for the customer guard.
///
/// All methods inject `Authorization: Bearer {customer_auth_token}`.
/// Throws [ApiException] on any failure (network, 4xx, 5xx).
class CustomerOrderRepository {
  CustomerOrderRepository(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Options get _authOptions {
    final token = _prefs.getString(_customerTokenKey);
    return Options(
      headers: {
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    );
  }

  Map<String, dynamic> _readData(Map<String, dynamic>? body) {
    if (body == null || body['success'] != true) {
      throw ApiException('API_ERROR', 'Unexpected server response.');
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('API_ERROR', 'Invalid response format.');
    }
    return data;
  }

  // ── API methods ─────────────────────────────────────────────────────────────

  /// GET /api/customer/v1/orders?month={YYYY-MM}
  ///
  /// Returns the parsed `data` map which contains `month` and `days` array.
  Future<Map<String, dynamic>> fetchOrders(String month) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/customer/v1/orders',
      queryParameters: {'month': month},
      options: _authOptions,
    );
    return _readData(response.data);
  }

  /// PUT /api/customer/v1/orders/{date}/qty
  ///
  /// Updates quantity for one subscription line on the given date.
  /// [date] format: YYYY-MM-DD.
  /// Throws [ApiException] with the API message on HTTP 422.
  Future<void> updateQty(
    String date,
    int subscriptionLineId,
    int qty,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/customer/v1/orders/$date/qty',
      data: {
        'subscription_line_id': subscriptionLineId,
        'qty': qty,
      },
      options: _authOptions,
    );
    _readData(response.data);
  }

  /// POST /api/customer/v1/orders/{date}/skip
  ///
  /// Skips all subscription lines for the given date.
  /// [date] format: YYYY-MM-DD.
  /// Throws [ApiException] with the API message on HTTP 422 (past date,
  /// vacation overlap, or more than 7 days ahead).
  Future<void> skipDay(String date) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/customer/v1/orders/$date/skip',
      options: _authOptions,
    );
    _readData(response.data);
  }
}
