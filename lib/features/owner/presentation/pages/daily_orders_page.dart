import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/owner_models.dart';
import '../providers/owner_provider.dart';
import '../widgets/customer_detail/customer_detail_styles.dart';
import '../widgets/owner_action_sheets.dart';
import '../widgets/owner_design_system.dart';
import '../widgets/owner_form_theme.dart';
import '../widgets/owner_page_fab.dart';
import '../widgets/owner_screen_widgets.dart';
import '../widgets/owner_shared_widgets.dart';
import '../widgets/owner_widgets.dart';
import '../../../../core/widgets/app_snackbar.dart';

class DailyOrdersPage extends ConsumerStatefulWidget {
  const DailyOrdersPage({super.key});

  @override
  ConsumerState<DailyOrdersPage> createState() => _DailyOrdersPageState();
}

class _DailyOrdersPageState extends ConsumerState<DailyOrdersPage> {
  DateTime _date = DateTime.now();
  DeliveryShiftFilter _shift = DeliveryShiftFilter.all;
  final _searchController = TextEditingController();
  String _search = '';
  CustomerSort _sort = CustomerSort.nameAsc;

  DailyOrdersQuery get _query => DailyOrdersQuery(
        date: DateTime(_date.year, _date.month, _date.day),
        shift: _shift,
      );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _reloadOrders() async {
    ref.invalidate(dailyOrdersProvider(_query));
    await ref.read(dailyOrdersProvider(_query).future);
  }

  Future<void> _updateQty(int id, double qty) async {
    try {
      await ref.read(ownerRepositoryProvider).updateDailyOrder(id, quantity: qty);
      await _reloadOrders();
    } on ApiException catch (e) {
      if (mounted) {
        AppSnackBar.show(context, e.message);
      }
    }
  }

  Future<void> _skipOrder(int id) async {
    try {
      await ref.read(ownerRepositoryProvider).updateDailyOrder(
            id,
            status: 'skipped',
            quantity: 0,
          );
      await _reloadOrders();
    } on ApiException catch (e) {
      if (mounted) {
        AppSnackBar.show(context, e.message);
      }
    }
  }

  Future<void> _undoSkip(DailyOrder order) async {
    try {
      await ref.read(ownerRepositoryProvider).updateDailyOrder(
            order.id,
            status: 'pending',
            quantity: order.subscribedQuantity,
          );
      await _reloadOrders();
    } on ApiException catch (e) {
      if (mounted) {
        AppSnackBar.show(context, e.message);
      }
    }
  }

  double _litresToDeliver(List<DailyOrder> orders) {
    return orders
        .where((o) => o.status != 'skipped')
        .fold<double>(0, (sum, o) => sum + o.quantity);
  }

  List<DailyOrder> _filterAndSortOrders(List<DailyOrder> orders) {
    var list = orders;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((o) => o.customerName.toLowerCase().contains(q)).toList();
    }
    list = List<DailyOrder>.from(list);
    list.sort((a, b) {
      final cmp = a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase());
      return switch (_sort) {
        CustomerSort.nameDesc => -cmp,
        _ => cmp,
      };
    });
    return list;
  }

  void _showSortMenu() {
    showOwnerBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerSheetHeader(title: AppStrings.sortLabel, icon: LucideIcons.arrowUpDown),
          const SizedBox(height: AppSpace.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.sortNameAsc, style: AppText.body),
            onTap: () {
              setState(() => _sort = CustomerSort.nameAsc);
              Navigator.pop(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.sortNameDesc, style: AppText.body),
            onTap: () {
              setState(() => _sort = CustomerSort.nameDesc);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return mapDioError(error).message;
  }

  Widget _buildOrdersBody(
    AsyncValue<DailyOrdersResult> ordersAsync,
  ) {
    final inkMuted = CustomerDetailColors.labelMuted;

    if (ordersAsync.isLoading && !ordersAsync.hasValue) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: CustomerDetailColors.accent),
            const SizedBox(height: AppSpace.md),
            Text('Loading orders…', style: AppText.body.copyWith(color: inkMuted)),
          ],
        ),
      );
    }

    if (ordersAsync.hasError && !ordersAsync.hasValue) {
      final error = ordersAsync.error!;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 40, color: inkMuted),
              const SizedBox(height: AppSpace.sm),
              Text(
                _errorMessage(error),
                style: AppText.body.copyWith(color: inkMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpace.sm),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: CustomerDetailColors.accent),
                onPressed: _reloadOrders,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = ordersAsync.value;
    if (data == null) {
      return Center(
        child: Text('Unable to load orders.', style: AppText.body.copyWith(color: inkMuted)),
      );
    }

    final orders = _filterAndSortOrders(data.orders);
    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: inkMuted),
              const SizedBox(height: AppSpace.sm),
              Text(AppStrings.ordersEmpty, style: AppText.body.copyWith(color: inkMuted)),
              if (data.summary.total > 0 && _search.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.xs),
                  child: Text(
                    'Try clearing the search filter.',
                    style: AppText.meta.copyWith(color: inkMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (data.summary.total == 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.xs),
                  child: Text(
                    'Try another date using the arrows above.',
                    style: AppText.meta.copyWith(color: inkMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: CustomerDetailColors.accent,
      onRefresh: _reloadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 88),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final isSkipped = order.status == 'skipped';
          return OrderListTile(
            customerName: order.customerName,
            productName: order.productName,
            shiftLabel: order.shiftLabel,
            address: order.shortAddress,
            quantity: order.quantity,
            unitRate: order.unitRate,
            isSkipped: isSkipped,
            onQtyChanged: (qty) => _updateQty(order.id, qty),
            onSkip: () => _skipOrder(order.id),
            onUndo: isSkipped ? () => _undoSkip(order) : null,
          );
        },
      ),
    );
  }

  int _shiftIndex() => switch (_shift) {
        DeliveryShiftFilter.morning => 1,
        DeliveryShiftFilter.evening => 2,
        _ => 0,
      };

  void _setShiftIndex(int index) {
    setState(() {
      _shift = switch (index) {
        1 => DeliveryShiftFilter.morning,
        2 => DeliveryShiftFilter.evening,
        _ => DeliveryShiftFilter.all,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(dailyOrdersProvider(_query));
    final summary = ordersAsync.value?.summary;
    final allOrders = ordersAsync.value?.orders ?? const <DailyOrder>[];

    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  BorderedDateNavigator(
                    date: _date,
                    onPrevious: () => setState(() => _date = _date.subtract(const Duration(days: 1))),
                    onNext: () => setState(() => _date = _date.add(const Duration(days: 1))),
                    onPickDate: _pickDate,
                  ),
                  const SizedBox(height: 11),
                  OwnerShiftTabs(
                    selected: _shiftIndex(),
                    onSelected: _setShiftIndex,
                    labels: const [
                      AppStrings.ordersAllShifts,
                      AppStrings.morningShift,
                      AppStrings.eveningShift,
                    ],
                  ),
                  const SizedBox(height: 11),
                  if (summary != null)
                    OrdersSummaryChips(
                      litres: summary.litresToDeliver ?? _litresToDeliver(allOrders),
                      orderCount: summary.total,
                      skippedCount: summary.skipped,
                    ),
                  const SizedBox(height: 11),
                  OwnerSearchSortRow(
                    controller: _searchController,
                    hintText: AppStrings.ordersSearchHint,
                    onChanged: (v) => setState(() => _search = v.trim()),
                    onSort: _showSortMenu,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildOrdersBody(ordersAsync)),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: OwnerPageFab(
            onPressed: () => OwnerActionSheets.showGenerateOrders(context, ref),
          ),
        ),
      ],
    );
  }
}
