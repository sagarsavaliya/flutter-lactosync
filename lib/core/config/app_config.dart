import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// App-wide configuration for lactosync_Flutter App.
abstract final class AppConfig {
  static const displayName = 'lactosync_Flutter App';
  static const apiPrefix = '/api/v1';
  static const productionHost = 'https://flutterapi.lactosync.com';

  /// Override at build time: --dart-define=API_BASE_URL=http://192.168.x.x:8080
  static const _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.endsWith('/')
          ? _envBaseUrl.substring(0, _envBaseUrl.length - 1)
          : _envBaseUrl;
    }

    // Release APK / store builds always hit production unless overridden above.
    if (kReleaseMode) {
      return '$productionHost$apiPrefix';
    }

    if (kIsWeb) return 'http://localhost:8080$apiPrefix';
    // Android emulator: use 127.0.0.1 after `adb reverse tcp:8080 tcp:8080`
    if (Platform.isAndroid) return 'http://127.0.0.1:8080$apiPrefix';
    return 'http://localhost:8080$apiPrefix';
  }
}
