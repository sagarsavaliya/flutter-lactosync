import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/models/subscription_status.dart';
import 'core/network/dio_provider.dart';
import 'core/providers/subscription_status_provider.dart';
import 'core/router/app_router.dart';
import 'core/storage/session_storage.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/customer/presentation/providers/customer_auth_provider.dart';
import 'features/subscription/presentation/pages/subscription_suspended_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final tokenStorage = TokenStorage(prefs);
  final sessionStorage = SessionStorage(prefs);

  runApp(
    ProviderScope(
      overrides: [
        tokenStorageProvider.overrideWithValue(tokenStorage),
        sessionStorageProvider.overrideWithValue(sessionStorage),
        // Customer feature uses its own SharedPreferences instance for token
        // storage under a separate key (customer_auth_token) to avoid
        // colliding with the owner app's 'auth_token'.
        customerSharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const LactoSyncApp(),
    ),
  );
}

class LactoSyncApp extends ConsumerStatefulWidget {
  const LactoSyncApp({super.key});

  @override
  ConsumerState<LactoSyncApp> createState() => _LactoSyncAppState();
}

class _LactoSyncAppState extends ConsumerState<LactoSyncApp> {
  @override
  void initState() {
    super.initState();
    // Push the suspended screen whenever the subscription transitions to
    // suspended. The SubscriptionSuspendedPage itself pops when the state
    // returns to active (via its own ref.listenManual).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(subscriptionStatusProvider, (previous, next) {
        if (next.status == SubscriptionStatus.suspended &&
            previous?.status != SubscriptionStatus.suspended) {
          rootNavigatorKey.currentState?.push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => const SubscriptionSuspendedPage(),
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.displayName,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
