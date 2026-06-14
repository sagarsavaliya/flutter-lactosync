import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/delivery_provider.dart';

class OwnerRouteSheetPage extends ConsumerStatefulWidget {
  const OwnerRouteSheetPage({super.key});

  @override
  ConsumerState<OwnerRouteSheetPage> createState() =>
      _OwnerRouteSheetPageState();
}

class _OwnerRouteSheetPageState extends ConsumerState<OwnerRouteSheetPage>
    with SingleTickerProviderStateMixin {
  DateTime _date = DateTime.now();
  late final TabController _tabs;

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final morningQuery = RouteSheetQuery(date: _dateStr, shift: 'morning');
    final eveningQuery = RouteSheetQuery(date: _dateStr, shift: 'evening');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Route Sheet'),
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined, size: 16),
            label: Text(DateFormat('d MMM').format(_date)),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.inkMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Morning'),
            Tab(text: 'Evening'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ShiftSheet(query: morningQuery),
          _ShiftSheet(query: eveningQuery),
        ],
      ),
    );
  }
}

class _ShiftSheet extends ConsumerWidget {
  const _ShiftSheet({required this.query});
  final RouteSheetQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetAsync = ref.watch(ownerRouteSheetProvider(query));

    return sheetAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.route_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No routes for this shift',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(ownerRouteSheetProvider(query)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, i) => _RouteCard(entry: entries[i], ref: ref, query: query),
          ),
        );
      },
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.entry, required this.ref, required this.query});
  final RouteSheetEntry entry;
  final WidgetRef ref;
  final RouteSheetQuery query;

  Future<void> _skip(BuildContext context, int? orderId, int assignmentId) async {
    if (orderId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip Delivery'),
        content: const Text('Mark this delivery as skipped for today?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Skip', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final dio = ref.read(dioProvider);
    try {
      await dio.post('/owner/skip-delivery', data: {
        'order_id': orderId,
        'date': query.date,
      });
      ref.invalidate(ownerRouteSheetProvider(query));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalQty = entry.customers.fold<double>(0, (s, c) => s + (c.qty ?? 0));
    final activeCount = entry.customers.where((c) => !c.isSkipped).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.routeName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      if (entry.deliveryBoyName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(children: [
                            const Icon(Icons.person_pin_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(entry.deliveryBoyName!,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ]),
                        ),
                    ],
                  ),
                ),
                // Summary badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${totalQty.toStringAsFixed(1)} L',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    Text('$activeCount customers',
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            // Customer rows
            ...entry.customers.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                decoration: c.isSkipped
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: c.isSkipped ? Colors.grey : null,
                              ),
                            ),
                            if (c.address.isNotEmpty)
                              Text(c.address,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (c.qty != null)
                        Text(
                          '${c.qty!.toStringAsFixed(1)} L',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: c.isSkipped ? Colors.grey : AppColors.primary,
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (c.isSkipped)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Skipped',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.orange)),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.block_outlined,
                              size: 18, color: Colors.orange),
                          tooltip: 'Skip delivery',
                          onPressed: () =>
                              _skip(context, c.orderId, c.assignmentId),
                        ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
