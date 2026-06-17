import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../providers/delivery_boy_route_provider.dart';
import '../providers/delivery_boy_session_provider.dart';
import '../widgets/delivery_boy_styles.dart';
import '../widgets/delivery_boy_widgets.dart';

/// Screen 4 — Cash collections hand-over.
class DeliveryBoyCashPage extends ConsumerWidget {
  const DeliveryBoyCashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(deliveryBoySessionProvider);
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final async = ref.watch(deliveryBoyCashCollectionsProvider(date));

    return Scaffold(
      backgroundColor: DbBoyColors.background,
      body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Cash collected', style: DbBoyText.screenTitle),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: DbBoyColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DbBoyColors.border),
                    ),
                    child: Text(
                      'Today',
                      style: DbBoyText.meta.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: DbBoyColors.accent),
                ),
                error: (e, _) => Center(child: Text('Error: $e', style: DbBoyText.meta)),
                data: (cash) {
                  return RefreshIndicator(
                    color: DbBoyColors.accent,
                    onRefresh: () async =>
                        ref.invalidate(deliveryBoyCashCollectionsProvider(date)),
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        DbCashSummaryHero(
                          total: cash.total,
                          customerCount: cash.items.length,
                          handedOver: session.cashHandedOver,
                          onHandOver: () {
                            ref
                                .read(deliveryBoySessionProvider.notifier)
                                .handOverCash();
                            AppSnackBar.show(
                              context,
                              'Cash hand-over recorded for today.',
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Text('COLLECTED FROM', style: DbBoyText.sectionLabel),
                        ),
                        if (cash.items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No cash collected yet today.',
                              textAlign: TextAlign.center,
                              style: DbBoyText.meta,
                            ),
                          )
                        else
                          ...cash.items.map(
                            (item) => DbCashCollectionRow(
                              name: item.customerName,
                              amount: item.amount,
                              stopNumber: item.stopNumber,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}
