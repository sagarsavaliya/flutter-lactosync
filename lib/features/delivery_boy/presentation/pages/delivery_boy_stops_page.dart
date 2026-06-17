import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/delivery_boy_route_provider.dart';
import '../providers/delivery_boy_session_provider.dart';
import '../widgets/delivery_boy_deliver_sheet.dart';
import '../widgets/delivery_boy_styles.dart';
import '../widgets/delivery_boy_widgets.dart';

/// Screen 2 — Route stops in progress.
class DeliveryBoyStopsPage extends ConsumerWidget {
  const DeliveryBoyStopsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(deliveryBoySessionProvider);
    final sheetKey = DbRouteSheetKey.today(session.shift);
    final async = ref.watch(deliveryBoyRouteSheetProvider(sheetKey));

    return Scaffold(
      backgroundColor: DbBoyColors.background,
      body: async.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: DbBoyColors.accent),
          ),
          error: (e, _) => Center(child: Text('Error: $e', style: DbBoyText.meta)),
          data: (data) {
            final route = data.primaryRoute;
            if (route == null) {
              return Center(
                child: Text('No route for this shift', style: DbBoyText.meta),
              );
            }

            final customers = [...route.customers]
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

            final activeIndex = customers.indexWhere(
              (c) => c.isDeliverable && !c.isDelivered && !c.isSkipped,
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DbShiftToggle(
                  shift: session.shift,
                  onChanged: (s) =>
                      ref.read(deliveryBoySessionProvider.notifier).setShift(s),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(route.routeName, style: DbBoyText.screenTitle),
                            Text(
                              '${session.shift == 'morning' ? 'Morning' : 'Evening'} · ${route.customerCount} stops',
                              style: DbBoyText.meta,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.map, color: DbBoyColors.accent),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                DbRouteProgressBar(
                  delivered: route.deliveredCount,
                  skipped: route.skippedCount,
                  remaining: route.remainingCount,
                  total: route.customerCount,
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: DbBoyColors.accent,
                    onRefresh: () async =>
                        ref.invalidate(deliveryBoyRouteSheetProvider(sheetKey)),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      itemCount: customers.length,
                      itemBuilder: (context, i) {
                        final c = customers[i];
                        return DbStopCard(
                          stopNumber: c.sortOrder > 0 ? c.sortOrder : i + 1,
                          customer: c,
                          isActive: i == activeIndex,
                          onDeliver: c.isDeliverable && !c.isDelivered && !c.isSkipped
                              ? () => _openDeliver(context, ref, c, sheetKey.date)
                              : null,
                          onSkip: c.isDeliverable && !c.isDelivered && !c.isSkipped
                              ? () => _skip(context, ref, c, sheetKey.date, sheetKey)
                              : null,
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
    );
  }

  Future<void> _openDeliver(
    BuildContext context,
    WidgetRef ref,
    DbRouteCustomer customer,
    String date,
  ) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeliveryBoyDeliverSheet(customer: customer, date: date),
    );
    if (done == true && context.mounted) {
      ref.invalidate(deliveryBoyRouteSheetProvider(DbRouteSheetKey.today(
        ref.read(deliveryBoySessionProvider).shift,
      )));
      ref.invalidate(deliveryBoyCashCollectionsProvider(date));
    }
  }

  Future<void> _skip(
    BuildContext context,
    WidgetRef ref,
    DbRouteCustomer customer,
    String date,
    DbRouteSheetKey sheetKey,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Skip stop', style: DbBoyText.screenTitle),
        content: Text('Skip delivery for ${customer.name}?', style: DbBoyText.meta),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Skip', style: DbBoyText.meta.copyWith(color: DbBoyColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await deliveryBoySkipDelivery(
        ref: ref,
        customerId: customer.customerId,
        date: date,
      );
      ref.invalidate(deliveryBoyRouteSheetProvider(sheetKey));
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context, mapDioError(e).message);
      }
    }
  }
}
