import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/owner_models.dart';
import '../providers/owner_provider.dart';
import '../widgets/customer_list_styles.dart';
import '../widgets/owner_form_theme.dart';

class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    return DateFormat('d MMM yyyy, h:mm a').format(parsed.toLocal());
  }

  Future<void> _restore(BuildContext context, WidgetRef ref, FarmActivity item) async {
    try {
      await ref.read(ownerRepositoryProvider).restoreActivity(item.id);
      ref.invalidate(farmActivitiesProvider);
      ref.invalidate(customersListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.activityRestored)),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(farmActivitiesProvider);
    final inkMuted = Theme.of(context).hintColor;

    return Scaffold(
      backgroundColor: CustomerListColors.background,
      appBar: AppBar(
        backgroundColor: CustomerListColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(AppStrings.activityTitle, style: AppText.screenTitle),
      ),
      body: activitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(farmActivitiesProvider),
            child: const Text('Retry'),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(AppStrings.activityEmpty, style: AppText.body.copyWith(color: inkMuted)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(farmActivitiesProvider);
              await ref.read(farmActivitiesProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpace.lg),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isDelete = item.action == 'deleted';

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isDelete ? Icons.delete_outline : Icons.restore,
                            size: 18,
                            color: isDelete ? AppColors.danger : AppColors.success,
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.actionLabel} · ${item.entityTypeLabel}',
                                  style: AppText.cardTitle,
                                ),
                                const SizedBox(height: AppSpace.xs),
                                Text(item.entityLabel, style: AppText.body),
                                if (item.createdAt != null) ...[
                                  const SizedBox(height: AppSpace.xs),
                                  Text(
                                    _formatTime(item.createdAt),
                                    style: AppText.meta.copyWith(color: inkMuted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (item.canRestore) ...[
                            const SizedBox(width: AppSpace.sm),
                            OwnerOutlineButton(
                              label: AppStrings.activityRestore,
                              onPressed: () => _restore(context, ref, item),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
