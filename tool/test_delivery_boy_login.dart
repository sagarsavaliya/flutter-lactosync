import 'package:dio/dio.dart';

import '../lib/core/config/app_config.dart';

Future<void> main() async {
  final baseUrl = AppConfig.apiBaseUrlDeliveryBoy;
  print('baseUrl: $baseUrl');
  print('usesProductionApi: ${AppConfig.usesProductionApi}');

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  try {
    final res = await dio.post(
      'delivery-boy/v1/auth/login',
      data: {'phone': '9429040899', 'pin': '1234'},
    );
    print('status: ${res.statusCode}');
    print('data: ${res.data}');
  } on DioException catch (e) {
    print('DioException type: ${e.type}');
    print('status: ${e.response?.statusCode}');
    print('data: ${e.response?.data}');
    print('message: ${e.message}');
  }
}
