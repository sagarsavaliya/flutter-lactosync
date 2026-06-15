import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../providers/delivery_provider.dart';

class OwnerRouteSheetPage extends ConsumerStatefulWidget {
  const OwnerRouteSheetPage({super.key});

  @override
  ConsumerState<OwnerRouteSheetPage> createState() => _OwnerRouteSheetPageState();
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
      backgroundColor: CustomerDetailColors.background,
      appBar: AppBar(
        title: Text(
          'Route sheet',
          style: AppText.screenTitle.copyWith(
            fontSize: 17,
            color: CustomerDetailColors.accent,
          ),
        ),
        backgroundColor: CustomerDetailColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: Icon(LucideIcons.calendar, size: 16, color: CustomerDetailColors.accent),
            label: Text(
              DateFormat('d MMM').format(_date),
              style: AppText.label.copyWith(color: CustomerDetailColors.accent),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: CustomerDetailColors.accent,
          unselectedLabelColor: CustomerDetailColors.onSurfaceVariant,
          indicatorColor: CustomerDetailColors.accent,
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
      loading: () => const Center(
        child: CircularProgressIndicator(color: CustomerDetailColors.accent),
      ),
      error: (e, _) => Center(
        child: Text('Could not load route sheet', style: AppText.body),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.map, size: 56, color: CustomerDetailColors.iconMuted),
                const SizedBox(height: 12),
                Text(
                  'No routes for this shift',
                  style: AppText.body.copyWith(color: CustomerDetailColors.onSurfaceVariant),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: CustomerDetailColors.accent,
          onRefresh: () async => ref.invalidate(ownerRouteSheetProvider(query)),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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

  Future<void> _skip(BuildContext context, RouteSheetCustomer customer) async {
    if (customer.customerId == 0) return;
    final ok = await showAppConfirmDialog(
      context: context,
      title: 'Skip delivery',
      message: 'Mark ${customer.name}\'s delivery as skipped for today?',
      confirmLabel: 'Skip',
      cancelLabel: 'Cancel',
    );
    if (ok != true || !context.mounted) return;
    final dio = ref.read(dioProvider);
    try {
      await dio.post('/owner/skip-delivery', data: {
        'customer_id': customer.customerId,
        'date': query.date,
      });
      ref.invalidate(ownerRouteSheetProvider(query));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapDioError(e).message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalQty = entry.customers.fold<double>(0, (s, c) => s + (c.qty ?? 0));
    final activeCount = entry.customers.where((c) => !c.isSkipped).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RedesignSurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.routeName,
                        style: AppText.cardTitle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: CustomerDetailColors.onSurface,
                        ),
                      ),
                      if (entry.deliveryBoyName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.user,
                                size: 14,
                                color: CustomerDetailColors.iconMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.deliveryBoyName!,
                                style: AppText.meta.copyWith(
                                  color: CustomerDetailColors.iconMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${totalQty.toStringAsFixed(1)} L',
                      style: AppText.cardTitle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CustomerDetailColors.accent,
                      ),
                    ),
                    Text(
                      '$activeCount customers',
                      style: AppText.meta.copyWith(color: CustomerDetailColors.iconMuted),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 20, color: CustomerDetailColors.divider),
            ...entry.customers.map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name,
                            style: AppText.cardTitle.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              decoration: c.isSkipped ? TextDecoration.lineThrough : null,
                              color: c.isSkipped
                                  ? CustomerDetailColors.iconMuted
                                  : CustomerDetailColors.onSurface,
                            ),
                          ),
                          if (c.address.isNotEmpty)
                            Text(
                              c.address,
                              style: AppText.meta.copyWith(color: CustomerDetailColors.iconMuted),
                            ),
                        ],
                      ),
                    ),
                    if (c.qty != null)
                      Text(
                        '${c.qty!.toStringAsFixed(1)} L',
                        style: AppText.cardTitle.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: c.isSkipped
                              ? CustomerDetailColors.iconMuted
                              : CustomerDetailColors.accent,
                        ),
                      ),
                    const SizedBox(width: 8),
                    if (c.isSkipped)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: CustomerDetailColors.morningChipBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: CustomerDetailColors.morningChipBorder),
                        ),
                        child: Text(
                          'Skipped',
                          style: AppText.meta.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: CustomerDetailColors.morningChipInk,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          LucideIcons.ban,
                          size: 18,
                          color: CustomerDetailColors.morningChipInk,
                        ),
                        tooltip: 'Skip delivery',
                        onPressed: () => _skip(context, c),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
