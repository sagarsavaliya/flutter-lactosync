import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/owner_models.dart';
import '../providers/owner_provider.dart';
import '../widgets/customer_detail/customer_detail_styles.dart';
import '../widgets/owner_design_system.dart';
import '../widgets/owner_form_theme.dart';
import '../widgets/owner_screen_widgets.dart';
import '../widgets/packing_groups_panel.dart';

enum MilkPrepCustomerSort { nameAsc, nameDesc, qtyDesc, qtyAsc }

class MilkPrepCustomersPage extends ConsumerStatefulWidget {
  const MilkPrepCustomersPage({
    super.key,
    required this.shift,
    required this.productId,
    required this.productName,
  });

  final String shift;
  final int productId;
  final String productName;

  @override
  ConsumerState<MilkPrepCustomersPage> createState() => _MilkPrepCustomersPageState();
}

class _MilkPrepCustomersPageState extends ConsumerState<MilkPrepCustomersPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _search = '';
  MilkPrepCustomerSort _sort = MilkPrepCustomerSort.nameAsc;

  DeliveryShiftFilter get _shiftFilter => widget.shift == 'evening'
      ? DeliveryShiftFilter.evening
      : DeliveryShiftFilter.morning;

  DailyOrdersQuery get _query => DailyOrdersQuery(
        date: DateTime.now(),
        shift: _shiftFilter,
        productId: widget.productId,
      );

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _search = value.trim().toLowerCase());
    });
  }

  String get _shiftTitle => widget.shift == 'evening'
      ? AppStrings.milkPrepEveningTitle
      : AppStrings.milkPrepMorningTitle;

  List<DailyOrder> _visibleOrders(List<DailyOrder> orders) {
    var list = orders
        .where((o) => o.status != 'skipped' && o.status != 'cancelled' && o.quantity > 0)
        .toList();

    if (_search.isNotEmpty) {
      list = list
          .where((o) =>
              o.customerName.toLowerCase().contains(_search) ||
              o.shortAddress.toLowerCase().contains(_search))
          .toList();
    }

    list.sort((a, b) {
      final nameCmp = a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase());
      final qtyCmp = a.quantity.compareTo(b.quantity);
      return switch (_sort) {
        MilkPrepCustomerSort.nameDesc => -nameCmp,
        MilkPrepCustomerSort.qtyDesc => -qtyCmp,
        MilkPrepCustomerSort.qtyAsc => qtyCmp,
        MilkPrepCustomerSort.nameAsc => nameCmp,
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
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.sortNameAsc, style: AppText.body),
            onTap: () {
              setState(() => _sort = MilkPrepCustomerSort.nameAsc);
              Navigator.pop(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.sortNameDesc, style: AppText.body),
            onTap: () {
              setState(() => _sort = MilkPrepCustomerSort.nameDesc);
              Navigator.pop(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.milkPrepQtySortHigh, style: AppText.body),
            onTap: () {
              setState(() => _sort = MilkPrepCustomerSort.qtyDesc);
              Navigator.pop(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.milkPrepQtySortLow, style: AppText.body),
            onTap: () {
              setState(() => _sort = MilkPrepCustomerSort.qtyAsc);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(dailyOrdersProvider(_query));
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.screenTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CustomerDetailColors.accent,
              ),
            ),
            Text(
              _shiftTitle,
              style: AppText.meta.copyWith(color: inkMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OwnerSearchSortRow(
              controller: _searchController,
              hintText: AppStrings.searchCustomersHint,
              onChanged: _onSearchChanged,
              onSort: _showSortMenu,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: CustomerDetailColors.accent),
              ),
              error: (_, __) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(dailyOrdersProvider(_query)),
                  child: const Text('Retry'),
                ),
              ),
              data: (result) {
                final orders = _visibleOrders(result.orders);
                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.milkPrepCustomersEmpty,
                      style: AppText.body.copyWith(color: inkMuted),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: CustomerDetailColors.accent,
                  onRefresh: () async {
                    ref.invalidate(dailyOrdersProvider(_query));
                    await ref.read(dailyOrdersProvider(_query).future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push('/owner/customers/${order.customerId}'),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: ownerWhiteCardDecoration(),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.customerName,
                                          style: AppText.cardTitle.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: CustomerDetailColors.onSurface,
                                          ),
                                        ),
                                        if (order.shortAddress.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            order.shortAddress,
                                            style: AppText.body.copyWith(
                                              color: CustomerDetailColors.bodyInk,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCDE9CF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      formatRouteQtyLiters(order.quantity),
                                      style: AppText.meta.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1E5233),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
