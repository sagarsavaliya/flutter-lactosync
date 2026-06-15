import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../providers/delivery_boy_auth_provider.dart';
import '../providers/delivery_boy_route_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';

class DeliveryBoyRouteSheetPage extends ConsumerStatefulWidget {
  const DeliveryBoyRouteSheetPage({super.key});

  @override
  ConsumerState<DeliveryBoyRouteSheetPage> createState() =>
      _DeliveryBoyRouteSheetPageState();
}

class _DeliveryBoyRouteSheetPageState
    extends ConsumerState<DeliveryBoyRouteSheetPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);
  bool get _isMorning => _tabs.index == 0;

  @override
  Widget build(BuildContext context) {
    final morningKey = DbRouteSheetKey(date: _dateStr, shift: 'morning');
    final eveningKey = DbRouteSheetKey(date: _dateStr, shift: 'evening');
    final sheetKey = _isMorning ? morningKey : eveningKey;

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Route Sheet',
                      style: AppText.screenTitle.copyWith(
                        fontSize: 22,
                        color: CustomerDetailColors.accent,
                      ),
                    ),
                  ),
                  Material(
                    color: CustomerDetailColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 7)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 1)),
                        );
                        if (picked != null) setState(() => _date = picked);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: CustomerDetailColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: CustomerDetailColors.accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('d MMM').format(_date),
                              style: AppText.label.copyWith(
                                fontWeight: FontWeight.w700,
                                color: CustomerDetailColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                controller: _tabs,
                indicatorColor: CustomerDetailColors.accent,
                indicatorWeight: 3,
                labelColor: CustomerDetailColors.accent,
                unselectedLabelColor: CustomerDetailColors.iconMuted,
                labelStyle: AppText.cardTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppText.cardTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CustomerDetailColors.iconMuted,
                ),
                dividerColor: CustomerDetailColors.border,
                tabs: const [
                  Tab(text: 'Morning'),
                  Tab(text: 'Evening'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _ShiftView(sheetKey: sheetKey, isMorning: _isMorning),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftView extends ConsumerWidget {
  const _ShiftView({required this.sheetKey, required this.isMorning});
  final DbRouteSheetKey sheetKey;
  final bool isMorning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(deliveryBoyRouteSheetProvider(sheetKey));
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: CustomerDetailColors.accent),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: AppText.body.copyWith(color: CustomerDetailColors.danger),
        ),
      ),
      data: (routes) {
        if (routes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.route_outlined,
                  size: 64,
                  color: CustomerDetailColors.iconMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  'No routes assigned for this shift',
                  style: AppText.body.copyWith(
                    color: CustomerDetailColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: CustomerDetailColors.accent,
          onRefresh: () async =>
              ref.invalidate(deliveryBoyRouteSheetProvider(sheetKey)),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: routes.length,
            itemBuilder: (ctx, i) => _RouteCard(
              entry: routes[i],
              sheetKey: sheetKey,
              isMorning: isMorning,
            ),
          ),
        );
      },
    );
  }
}

class _RouteCard extends ConsumerWidget {
  const _RouteCard({
    required this.entry,
    required this.sheetKey,
    required this.isMorning,
  });
  final DbRouteEntry entry;
  final DbRouteSheetKey sheetKey;
  final bool isMorning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCustomers =
        entry.customers.where((c) => !c.isSkipped).toList();
    final totalQty = activeCustomers.fold<double>(
      0,
      (s, c) => s + (c.qty ?? 0),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: RedesignSurfaceCard(
        radius: 20,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isMorning
                          ? CustomerDetailColors.morningChipBg
                          : const Color(0xFFE0E4F5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isMorning
                          ? Icons.wb_sunny_rounded
                          : Icons.nights_stay_rounded,
                      color: isMorning
                          ? CustomerDetailColors.morningChipInk
                          : const Color(0xFF5C6BC0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.routeName,
                          style: AppText.cardTitle.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: CustomerDetailColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${activeCustomers.length} customers',
                          style: AppText.meta.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: CustomerDetailColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CustomerDetailColors.accentLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CustomerDetailColors.accentBorder),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${totalQty.toStringAsFixed(1)} L',
                          style: AppText.cardTitle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: CustomerDetailColors.calHalfInk,
                          ),
                        ),
                        Text(
                          'to prepare',
                          style: AppText.meta.copyWith(
                            fontSize: 9,
                            color: CustomerDetailColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: CustomerDetailColors.divider),
            ...entry.customers.asMap().entries.map((e) {
              final idx = e.key;
              final c = e.value;
              final isLast = idx == entry.customers.length - 1;
              return _CustomerRow(
                customer: c,
                index: idx + 1,
                sheetKey: sheetKey,
                showDivider: !isLast,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CustomerRow extends ConsumerWidget {
  const _CustomerRow({
    required this.customer,
    required this.index,
    required this.sheetKey,
    required this.showDivider,
  });

  final DbRouteCustomer customer;
  final int index;
  final DbRouteSheetKey sheetKey;
  final bool showDivider;

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    if (customer.orderId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CustomerDetailColors.surface,
        title: Text('Skip Delivery', style: AppText.screenTitle),
        content: Text(
          'Skip delivery for ${customer.name} today?',
          style: AppText.body.copyWith(color: CustomerDetailColors.bodyInk),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Skip',
              style: AppText.label.copyWith(color: CustomerDetailColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final dio = ref.read(deliveryBoyDioProvider);
    try {
      await dio.post('delivery-boy/v1/skip-delivery', data: {
        'order_id': customer.orderId,
        'date': sheetKey.date,
      });
      ref.invalidate(deliveryBoyRouteSheetProvider(sheetKey));
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.show(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faded = customer.isSkipped;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          child: Opacity(
            opacity: faded ? 0.62 : 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 27,
                  height: 27,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CustomerDetailColors.accentLight,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '$index',
                    style: AppText.meta.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: CustomerDetailColors.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 7,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            customer.name.toUpperCase(),
                            style: AppText.cardTitle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: faded
                                  ? CustomerDetailColors.onSurfaceVariant
                                  : CustomerDetailColors.onSurface,
                              decoration: faded
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (customer.isSkipped)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: CustomerDetailColors.morningChipBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'SKIPPED',
                                style: AppText.meta.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: CustomerDetailColors.morningChipInk,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (customer.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          customer.address,
                          style: AppText.meta.copyWith(
                            fontSize: 12,
                            color: CustomerDetailColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (customer.qty != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: CustomerDetailColors.rateChipBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CustomerDetailColors.rateChipBorder),
                    ),
                    child: Text(
                      '${customer.qty!.toStringAsFixed(1)} L',
                      style: AppText.meta.copyWith(
                        fontWeight: FontWeight.w800,
                        color: CustomerDetailColors.rateChipInk,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                if (!customer.isSkipped)
                  GestureDetector(
                    onTap: () => _skip(context, ref),
                    child: const Tooltip(
                      message: 'Skip delivery',
                      child: Icon(
                        Icons.block_outlined,
                        size: 20,
                        color: CustomerDetailColors.dangerMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 51, color: CustomerDetailColors.divider),
      ],
    );
  }
}
