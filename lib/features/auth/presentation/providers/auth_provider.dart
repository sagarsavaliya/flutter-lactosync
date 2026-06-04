import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/session_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  throw UnimplementedError('Override in main()');
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
    ref.watch(sessionStorageProvider),
  );
});

final authSessionProvider = FutureProvider<AuthSession?>((ref) async {
  return ref.watch(authRepositoryProvider).readStoredSession();
});
