import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/delivery_boy_route_provider.dart';
import '../providers/delivery_boy_session_provider.dart';
import '../widgets/delivery_boy_styles.dart';
import '../widgets/delivery_boy_widgets.dart';

/// Screen 1 — Pickup manifest before starting the route.
class DeliveryBoyPickupPage extends ConsumerWidget {
  const DeliveryBoyPickupPage({super.key});

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
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load route: $e', style: DbBoyText.meta),
            ),
          ),
          data: (data) {
            final route = data.primaryRoute;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DbBoyGreetingHeader(
                  name: data.deliveryBoyName,
                  trailing: IconButton(
                    icon: const Icon(LucideIcons.bell, color: DbBoyColors.ink),
                    onPressed: () {},
                  ),
                ),
                DbShiftToggle(
                  shift: session.shift,
                  onChanged: (s) =>
                      ref.read(deliveryBoySessionProvider.notifier).setShift(s),
                ),
                Expanded(
                  child: route == null
                      ? Center(
                          child: Text(
                            'No route assigned for this shift',
                            style: DbBoyText.meta,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 24),
                          children: [
                            const SizedBox(height: 8),
                            DbRouteHeroCard(
                              routeName: route.routeName,
                              shiftLabel:
                                  session.shift == 'morning' ? 'Morning route' : 'Evening route',
                              stopCount: route.customerCount,
                            ),
                            const SizedBox(height: 12),
                            DbLoadSummaryCard(
                              totalLiters: route.totalLiters,
                              bottles: route.bottleCount,
                              bags: route.bagCount,
                            ),
                            const SizedBox(height: 12),
                            DbPickupManifestCard(
                              cards: route.milkPreparation,
                              customerCount: route.customerCount,
                              totalLiters: route.totalLiters,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: CheckboxListTile(
                                value: session.cartChecked,
                                onChanged: (v) => ref
                                    .read(deliveryBoySessionProvider.notifier)
                                    .toggleCartChecked(v ?? false),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: DbBoyColors.accent,
                                title: Text(
                                  'Cart loaded & checked',
                                  style: DbBoyText.cardTitle.copyWith(fontSize: 15),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              child: DbPrimaryButton(
                                label: 'Start route',
                                icon: LucideIcons.arrowRight,
                                enabled: session.cartChecked,
                                onPressed: () {
                                  ref
                                      .read(deliveryBoySessionProvider.notifier)
                                      .startRoute();
                                  context.go('/delivery-boy/stops');
                                },
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
    );
  }
}
