import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/entities/auth_session.dart';
import 'providers/auth_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.darkInk : AppColors.ink;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              ref.invalidate(authSessionProvider);
              if (context.mounted) context.go('/sign-in');
            },
            child: Text(AppStrings.signOut, style: AppText.label.copyWith(color: ink)),
          ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, stackTrace) => const SizedBox.shrink(),
        data: (AuthSession? session) {
          if (session == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/sign-in');
            });
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.homeWelcome}, ${session.ownerName}',
                  style: AppText.screenTitle.copyWith(color: ink),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  session.farmName,
                  style: AppText.sectionTitle.copyWith(color: inkMuted),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
