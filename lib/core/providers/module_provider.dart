import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';

/// Holds the effective module entitlements for the authenticated owner.
/// Fetched once at app startup (or on demand); keyed by module slug.
class ModuleState {
  const ModuleState({
    this.modules = const {},
    this.loaded = false,
  });

  final Map<String, bool> modules;
  final bool loaded;

  bool isEnabled(String slug) => modules[slug] ?? false;

  ModuleState copyWith({Map<String, bool>? modules, bool? loaded}) {
    return ModuleState(
      modules: modules ?? this.modules,
      loaded: loaded ?? this.loaded,
    );
  }
}

class ModuleNotifier extends StateNotifier<ModuleState> {
  ModuleNotifier(this._dio) : super(const ModuleState());

  final Dio _dio;

  Future<void> fetch() async {
    try {
      final res = await _dio.get('/api/v1/owner/modules');
      final data = res.data['data'] as Map<String, dynamic>? ?? {};
      final modules = data.map((k, v) => MapEntry(k, v == true));
      state = ModuleState(modules: modules, loaded: true);
    } catch (_) {
      // On failure, keep previous state but mark as loaded so UI doesn't block.
      state = state.copyWith(loaded: true);
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
