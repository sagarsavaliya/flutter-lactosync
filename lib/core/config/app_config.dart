import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// App-wide configuration for lactosync_Flutter App.
abstract final class AppConfig {
  static const displayName = 'lactosync_Flutter App';
  static const apiPrefix = '/api/v1';
  static const productionHost = 'https://flutterapi.lactosync.com';

  /// Override owner API base at build time:
  /// `--dart-define=API_BASE_URL=https://flutterapi.lactosync.com/api/v1`
  static const _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Use local Docker (`localhost:8080`) in debug builds only when true:
  /// `--dart-define=USE_LOCAL_API=true`
  static const _useLocalApi = bool.fromEnvironment('USE_LOCAL_API');

  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.endsWith('/')
          ? _envBaseUrl.substring(0, _envBaseUrl.length - 1)
          : _envBaseUrl;
    }

    if (_usesProduction) {
      return '$productionHost$apiPrefix';
    }

    return _localOwnerBase();
  }

  /// Base URL for customer API routes (prefix: /api/customer/v1/...).
  /// The customer routes sit at /api/customer/v1, NOT /api/v1/customer/v1,
  /// so the Dio base must be /api — one level above the owner /api/v1 base.
  static String get apiBaseUrlCustomer {
    if (_envBaseUrl.isNotEmpty) {
      return _apiRootFromOwnerBase(apiBaseUrl);
    }
    if (_usesProduction) return '$productionHost/api';
    return _localApiRoot();
  }

  /// Base URL for delivery boy API routes (prefix: /api/delivery-boy/v1/...).
  static String get apiBaseUrlDeliveryBoy {
    if (_envBaseUrl.isNotEmpty) {
      return _apiRootFromOwnerBase(apiBaseUrl);
    }
    if (_usesProduction) return '$productionHost/api';
    return _localApiRoot();
  }

  static bool get usesProductionApi => _usesProduction;

  static bool get _usesProduction {
    if (kReleaseMode) return true;
    if (_useLocalApi) return false;
    if (_envBaseUrl.isEmpty) return true;
    return !_envBaseUrl.contains('localhost') &&
        !_envBaseUrl.contains('127.0.0.1');
  }

  static String _localOwnerBase() {
    if (kIsWeb) return 'http://localhost:8080$apiPrefix';
    // Android emulator: 127.0.0.1 works after `adb reverse tcp:8080 tcp:8080`
    if (Platform.isAndroid) return 'http://127.0.0.1:8080$apiPrefix';
    return 'http://localhost:8080$apiPrefix';
  }

  static String _localApiRoot() {
    if (kIsWeb) return 'http://localhost:8080/api';
    if (Platform.isAndroid) return 'http://127.0.0.1:8080/api';
    return 'http://localhost:8080/api';
  }

  static String _apiRootFromOwnerBase(String ownerBase) {
    if (ownerBase.endsWith(apiPrefix)) {
      return '${ownerBase.substring(0, ownerBase.length - apiPrefix.length)}/api';
    }
    return ownerBase.replaceAll(RegExp(r'/api/v1$'), '/api');
  }
}
