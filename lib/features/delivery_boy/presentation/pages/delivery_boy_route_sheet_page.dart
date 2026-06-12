import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/delivery_boy_auth_provider.dart';
import '../providers/delivery_boy_route_provider.dart';

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
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  @override
  Widget build(BuildContext context) {
    final morningKey = DbRouteSheetKey(date: _dateStr, shift: 'morning');
    final eveningKey = DbRouteSheetKey(date: _dateStr, shift: 'evening');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Route Sheet'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) setState(() => _date = picked);
            },
            icon: const Icon(Icons.calendar_today_outlined,
                size: 16, color: Colors.white),
            label: Text(
              DateFormat('d MMM').format(_date),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Morning'),
            Tab(text: 'Evening'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ShiftView(sheetKey: morningKey),
          _ShiftView(sheetKey: eveningKey),
        ],
      ),
    );
  }
}

// ── Shift view (one tab) ──────────────────────────────────────────────────────

class _ShiftView extends ConsumerWidget {
  const _ShiftView({required this.sheetKey});
  final DbRouteSheetKey sheetKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(deliveryBoyRouteSheetProvider(sheetKey));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (routes) {
        if (routes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.route_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No routes assigned for this shift',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(deliveryBoyRouteSheetProvider(sheetKey)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            itemBuilder: (ctx, i) => _RouteCard(
              entry: routes[i],
              sheetKey: sheetKey,
            ),
          ),
        );
      },
    );
  }
}

// ── Route card (milk prep + customer list) ────────────────────────────────────

class _RouteCard extends ConsumerWidget {
  const _RouteCard({required this.entry, required this.sheetKey});
  final DbRouteEntry entry;
  final DbRouteSheetKey sheetKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalQty = entry.customers
        .where((c) => !c.isSkipped)
        .fold<double>(0, (s, c) => s + (c.qty ?? 0));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Milk prep card header ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_drink_outlined,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.routeName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          '${entry.customers.where((c) => !c.isSkipped).length} customers',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // Total milk to prepare
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${totalQty.toStringAsFixed(1)} L',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const Text('to prepare',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Customer list (no phone) ────────────────────────────────────
            ...entry.customers.asMap().entries.map((e) {
              final idx = e.key;
              final c = e.value;
              return _CustomerRow(
                customer: c,
                index: idx + 1,
                sheetKey: sheetKey,
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Customer row ──────────────────────────────────────────────────────────────

class _CustomerRow extends ConsumerWidget {
  const _CustomerRow({
    required this.customer,
    required this.index,
    required this.sheetKey,
  });

  final DbRouteCustomer customer;
  final int index;
  final DbRouteSheetKey sheetKey;

  Future<void> _skip(BuildContext context, WidgetRef ref) async {
    if (customer.orderId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip Delivery'),
        content: Text(
            'Skip delivery for ${customer.name} today?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Skip',
                style: TextStyle(color: Colors.orange)),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stop number
          SizedBox(
            width: 28,
            child: Text(
              '$index.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: customer.isSkipped ? Colors.grey : AppColors.primary,
              ),
            ),
          ),
          // Name + address (NO phone)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: customer.isSkipped
                        ? TextDecoration.lineThrough
                        : null,
                    color: customer.isSkipped ? Colors.grey : null,
                  ),
                ),
                if (customer.address.isNotEmpty)
                  Text(customer.address,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          // Quantity
          if (customer.qty != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                '${customer.qty!.toStringAsFixed(1)} L',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: customer.isSkipped
                      ? Colors.grey
                      : AppColors.primary,
                ),
              ),
            ),
          // Skip / skipped indicator
          if (customer.isSkipped)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Skipped',
                  style: TextStyle(fontSize: 10, color: Colors.orange)),
            )
          else
            GestureDetector(
              onTap: () => _skip(context, ref),
              child: const Tooltip(
                message: 'Skip delivery',
                child: Icon(Icons.block_outlined,
                    size: 20, color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }
}
