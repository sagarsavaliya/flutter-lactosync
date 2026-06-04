import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/owner_models.dart';
import '../providers/owner_provider.dart';
import '../widgets/customer_list_styles.dart';
import '../widgets/owner_design_system.dart';
import '../widgets/owner_form_theme.dart';
import '../widgets/owner_shared_widgets.dart';
import '../widgets/owner_widgets.dart';
import '../widgets/owner_action_sheets.dart';
import '../widgets/owner_page_fab.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
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
          const OwnerSheetTitle(AppStrings.sortLabel),
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
    Color inkMuted,
  ) {
    if (ordersAsync.isLoading && !ordersAsync.hasValue) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
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
      onRefresh: _reloadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final isSkipped = order.status == 'skipped';
          return OrderListTile(
            customerName: order.customerName,
            productName: order.productName,
            shiftLabel: order.shiftLabel,
            quantity: order.quantity,
            isSkipped: isSkipped,
            onQtyChanged: (qty) => _updateQty(order.id, qty),
            onSkip: () => _skipOrder(order.id),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(dailyOrdersProvider(_query));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
              child: Column(
                children: [
                  BorderedDateNavigator(
                    date: _date,
                    onPrevious: () => setState(() => _date = _date.subtract(const Duration(days: 1))),
                    onNext: () => setState(() => _date = _date.add(const Duration(days: 1))),
                    onPickDate: _pickDate,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  OwnerSearchSortRow(
                    controller: _searchController,
                    hintText: AppStrings.ordersSearchHint,
                    onChanged: (v) => setState(() => _search = v.trim()),
                    onSort: _showSortMenu,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      _Chip(
                        label: AppStrings.ordersAllShifts,
                        selected: _shift == DeliveryShiftFilter.all,
                        onTap: () => setState(() => _shift = DeliveryShiftFilter.all),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      _Chip(
                        label: AppStrings.morningShift,
                        selected: _shift == DeliveryShiftFilter.morning,
                        onTap: () => setState(() => _shift = DeliveryShiftFilter.morning),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      _Chip(
                        label: AppStrings.eveningShift,
                        selected: _shift == DeliveryShiftFilter.evening,
                        onTap: () => setState(() => _shift = DeliveryShiftFilter.evening),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Expanded(child: _buildOrdersBody(ordersAsync, inkMuted)),
          ],
        ),
        Positioned(
          right: AppSpace.lg,
          bottom: AppSpace.lg,
          child: OwnerPageFab(
            onPressed: () => OwnerActionSheets.showGenerateOrders(context, ref),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? primary : OwnerFormTheme.borderColor),
            color: selected ? primary.withValues(alpha: 0.08) : null,
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppText.meta, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
