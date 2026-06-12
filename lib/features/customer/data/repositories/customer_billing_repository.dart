import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';

/// A single payment entry returned by GET /api/customer/v1/payments.
class CustomerPayment {
  const CustomerPayment({
    required this.id,
    required this.amount,
    required this.paymentDate,
    required this.method,
    this.note,
  });

  final int id;
  final double amount;

  /// Raw value from the API, e.g. "2026-06-05".
  final String paymentDate;

  /// One of: "cash", "upi", or any other string (shown as "Other").
  final String method;

  /// Optional note recorded by the farm owner.
  final String? note;

  factory CustomerPayment.fromJson(Map<String, dynamic> json) {
    return CustomerPayment(
      id:          (json['id'] as num).toInt(),
      amount:      (json['amount'] as num).toDouble(),
      paymentDate: json['payment_date'] as String? ?? '',
      method:      json['method'] as String? ?? '',
      note: () {
        final raw = json['note'];
        if (raw == null) return null;
        final s = raw as String;
        return s.isEmpty ? null : s;
      }(),
    );
  }
}

/// A single bill entry returned by GET /api/customer/v1/bills.
class CustomerBill {
  const CustomerBill({
    required this.id,
    required this.billingMonth,
    required this.totalAmount,
    required this.balanceDue,
    required this.status,
  });

  final int id;

  /// Raw value from the API, e.g. "2026-06".
  final String billingMonth;
  final double totalAmount;
  final double balanceDue;

  /// One of: "paid", "partial", "unpaid".
  final String status;

  factory CustomerBill.fromJson(Map<String, dynamic> json) {
    return CustomerBill(
      id: (json['id'] as num).toInt(),
      billingMonth: json['billing_month'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      balanceDue: (json['balance_due'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}

/// Wraps all customer billing API calls.
class CustomerBillingRepository {
  CustomerBillingRepository(this._dio);

  final Dio _dio;

  /// GET /api/customer/v1/bills
  /// Returns the list ordered by billing_month descending (server-side).
  Future<List<CustomerBill>> fetchBills() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/customer/v1/bills',
      );
      final body = response.data;
      if (body == null || body['success'] != true) {
        throw ApiException('API_ERROR', 'Failed to load bills.');
      }
      final data = body['data'] as Map<String, dynamic>;
      final billsJson = data['bills'] as List<dynamic>;
      return billsJson
          .cast<Map<String, dynamic>>()
          .map(CustomerBill.fromJson)
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// GET /api/customer/v1/payments
  /// Returns the customer's payment list ordered by payment_date descending.
  Future<List<CustomerPayment>> fetchPayments() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/customer/v1/payments',
      );
      final body = response.data;
      if (body == null || body['success'] != true) {
        throw ApiException('API_ERROR', 'Failed to load payments.');
      }
      final data = body['data'] as Map<String, dynamic>;
      final paymentsJson = data['payments'] as List<dynamic>;
      return paymentsJson
          .cast<Map<String, dynamic>>()
          .map(CustomerPayment.fromJson)
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// GET /api/customer/v1/bills/{id}/image
  /// Returns the signed URL string for the bill PNG.
  /// Throws [ApiException] with code 'NOT_FOUND' for HTTP 404.
  Future<String> fetchBillImageUrl(int id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/customer/v1/bills/$id/image',
      );
      final body = response.data;
      if (body == null || body['success'] != true) {
        throw ApiException('API_ERROR', 'Failed to load bill image.');
      }
      final data = body['data'] as Map<String, dynamic>;
      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw ApiException('NOT_FOUND', 'Bill image not available.');
      }
      return url;
    } on DioException catch (e) {
      final ex = mapDioError(e);
      if (e.response?.statusCode == 404) {
        throw ApiException('NOT_FOUND', 'Bill image not available.',
            statusCode: 404);
      }
      throw ex;
    }
  }
}
