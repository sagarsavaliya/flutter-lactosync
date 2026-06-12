import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'subscription_interceptor.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError('Override in main()');
});

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  // Subscription interceptor must be added before the error handler so that
  // 403 SUBSCRIPTION_SUSPENDED errors are classified before generic handling.
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  // Subscription gate: classifies 402/403 middleware signals.
  dio.interceptors.add(SubscriptionInterceptor(ref));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.readToken();
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

ApiException mapDioError(Object error) {
  if (error is DioException && error.error is ApiException) {
    return error.error as ApiException;
  }
  if (error is ApiException) return error;
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 429) {
      return ApiException(
        'RATE_LIMITED',
        'Too many attempts. Please wait a few minutes and try again.',
        statusCode: 429,
      );
    }
    if (status != null && status >= 400) {
      return ApiException(
        'API_ERROR',
        'Server returned an error ($status). Please try again.',
        statusCode: status,
      );
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'TIMEOUT',
          kReleaseMode
              ? 'Server is slow to respond. Please try again.'
              : 'Server is slow to respond. Check Docker is running, then try again.',
        );
      case DioExceptionType.connectionError:
        return ApiException(
          'NETWORK_ERROR',
          kReleaseMode
              ? 'Cannot reach LactoSync. Check your internet connection and try again.'
              : 'Cannot reach the API at ${AppConfig.apiBaseUrl}. Is Docker running on port 8080?',
        );
      default:
        break;
    }
  }
  return ApiException('NETWORK_ERROR', 'Could not reach the server. Check your connection.');
}
