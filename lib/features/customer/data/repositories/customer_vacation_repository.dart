import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';

/// Shape of the vacation data returned by the API.
class VacationData {
  const VacationData({required this.start, required this.end});

  /// Both are null when no vacation is set.
  final String? start; // "YYYY-MM-DD"
  final String? end;   // "YYYY-MM-DD"

  bool get hasVacation => start != null && end != null;

  factory VacationData.fromJson(Map<String, dynamic> json) {
    return VacationData(
      start: json['vacation_start'] as String?,
      end:   json['vacation_end']   as String?,
    );
  }
}

/// Handles all /api/customer/v1/vacation calls.
/// [_dio] must already inject the customer Authorization header.
class CustomerVacationRepository {
  const CustomerVacationRepository(this._dio);

  final Dio _dio;

  // ── GET /api/customer/v1/vacation ──────────────────────────────────────────

  Future<VacationData> fetchVacation() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/customer/v1/vacation',
    );
    return VacationData.fromJson(_extractData(response.data));
  }

  // ── POST /api/customer/v1/vacation ────────────────────────────────────────

  Future<VacationData> setVacation(String start, String end) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/customer/v1/vacation',
      data: {
        'vacation_start': start,
        'vacation_end':   end,
      },
    );
    return VacationData.fromJson(_extractData(response.data));
  }

  // ── DELETE /api/customer/v1/vacation ─────────────────────────────────────

  Future<void> cancelVacation() async {
    await _dio.delete<Map<String, dynamic>>('/customer/v1/vacation');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _extractData(Map<String, dynamic>? body) {
    if (body == null || body['success'] != true) {
      throw ApiException('API_ERROR', 'Unexpected server response.');
    }
    return Map<String, dynamic>.from(body['data'] as Map);
  }
}
