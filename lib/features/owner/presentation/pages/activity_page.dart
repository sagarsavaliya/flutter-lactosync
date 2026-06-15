import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/owner_models.dart';
import '../providers/owner_provider.dart';
import '../widgets/customer_detail/customer_detail_styles.dart';
import '../widgets/owner_form_theme.dart';
import '../widgets/owner_screen_widgets.dart';
import '../../../../core/widgets/app_snackbar.dart';

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
        AppSnackBar.show(context, AppStrings.activityRestored);
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(farmActivitiesProvider);
    final inkMuted = CustomerDetailColors.labelMuted;

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      appBar: AppBar(
        backgroundColor: CustomerDetailColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CustomerDetailColors.accent),
          onPressed: () => context.pop(),
        ),
        title: Text(
          AppStrings.activityTitle,
          style: AppText.screenTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CustomerDetailColors.accent,
          ),
        ),
      ),
      body: activitiesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CustomerDetailColors.accent),
        ),
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
            color: CustomerDetailColors.accent,
            onRefresh: () async {
              ref.invalidate(farmActivitiesProvider);
              await ref.read(farmActivitiesProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isDelete = item.action == 'deleted';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: ownerWhiteCardDecoration(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDelete
                                ? CustomerDetailColors.dangerBg
                                : CustomerDetailColors.successBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isDelete ? LucideIcons.trash2 : LucideIcons.rotateCcw,
                            size: 18,
                            color: isDelete ? CustomerDetailColors.danger : CustomerDetailColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item.actionLabel} · ${item.entityTypeLabel}',
                                style: AppText.cardTitle.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: CustomerDetailColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(item.entityLabel, style: AppText.body.copyWith(color: CustomerDetailColors.bodyInk)),
                              if (item.createdAt != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(item.createdAt),
                                  style: AppText.meta.copyWith(color: inkMuted),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (item.canRestore) ...[
                          const SizedBox(width: 8),
                          OwnerOutlineButton(
                            label: AppStrings.activityRestore,
                            onPressed: () => _restore(context, ref, item),
                          ),
                        ],
                      ],
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
