import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';

/// Holds the effective module entitlements for the authenticated owner.
/// Fetched once at app startup (or on demand); keyed by module slug.
class ModuleState {
  const ModuleState({
    this.modules = const {},
    this.loaded = false,
    this.hasError = false,
  });

  final Map<String, bool> modules;
  final bool loaded;
  final bool hasError;

  bool isEnabled(String slug) => modules[slug] ?? false;

  ModuleState copyWith({Map<String, bool>? modules, bool? loaded, bool? hasError}) {
    return ModuleState(
      modules: modules ?? this.modules,
      loaded: loaded ?? this.loaded,
      hasError: hasError ?? this.hasError,
    );
  }
}

class ModuleNotifier extends StateNotifier<ModuleState> {
  ModuleNotifier(this._dio) : super(const ModuleState());

  final Dio _dio;

  Future<void> fetch() async {
    try {
      final res = await _dio.get('/owner/modules');
      final data = res.data['data'] as Map<String, dynamic>? ?? {};
      final modules = data.map((k, v) => MapEntry(k, v is bool && v));
      debugPrint('[modules] loaded: $modules');
      state = ModuleState(modules: modules, loaded: true);
    } catch (e) {
      debugPrint('[modules] fetch failed: $e');
      state = state.copyWith(loaded: true, hasError: true);
    }
  }

  void setFromMap(Map<String, dynamic> raw) {
    final modules = raw.map((k, v) => MapEntry(k, v == true));
    state = ModuleState(modules: modules, loaded: true);
  }
}

final moduleProvider =
    StateNotifierProvider<ModuleNotifier, ModuleState>((ref) {
  final dio = ref.watch(dioProvider);
  return ModuleNotifier(dio);
});
