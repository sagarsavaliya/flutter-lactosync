import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/owner_models.dart';
import '../providers/owner_provider.dart';
import '../widgets/customer_list_styles.dart';
import '../widgets/owner_form_theme.dart';
import '../widgets/owner_design_system.dart';
import '../widgets/owner_widgets.dart';
import '../widgets/owner_action_sheets.dart';
import '../widgets/vacation_sheet.dart';

class CustomersListPage extends ConsumerStatefulWidget {
  const CustomersListPage({super.key});

  @override
  ConsumerState<CustomersListPage> createState() => _CustomersListPageState();
}

class _CustomersListPageState extends ConsumerState<CustomersListPage> {
  final _searchController = TextEditingController();
  CustomerSort _sort = CustomerSort.nameAsc;
  Timer? _debounce;
  String _search = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _search = value.trim());
    });
  }

  CustomersQuery get _query => CustomersQuery(search: _search, sort: _sort);

  Future<void> _refreshList() async {
    ref.invalidate(customersListProvider(_query));
    await ref.read(customersListProvider(_query).future);
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.sortRecent, style: AppText.body),
            onTap: () {
              setState(() => _sort = CustomerSort.updatedDesc);
              Navigator.pop(context);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.sortOldest, style: AppText.body),
            onTap: () {
              setState(() => _sort = CustomerSort.updatedAsc);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openVacationSheet(OwnerCustomer customer) async {
    await VacationSheet.show(
      context,
      customerName: customer.fullName,
      initialStart: customer.vacationStart,
      initialEnd: customer.vacationEnd,
      onUpdate: (start, end) async {
        try {
          await ref.read(ownerRepositoryProvider).updateCustomer(
                customer.id,
                end == null && start == null
                    ? const CustomerUpdateRequest(clearVacation: true)
                    : CustomerUpdateRequest(vacationStart: start, vacationEnd: end),
              );
          await _refreshList();
        } on ApiException catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(customersListProvider(_query));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return ColoredBox(
      color: CustomerListColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: OwnerSearchSortRow(
                    controller: _searchController,
                    hintText: AppStrings.searchCustomersHint,
                    onChanged: _onSearchChanged,
                    onSort: _showSortMenu,
                  ),
                ),
              ),
              Expanded(
                child: listAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Center(
                    child: TextButton(onPressed: _refreshList, child: const Text('Retry')),
                  ),
                  data: (data) {
                    if (data.customers.isEmpty) {
                      return Center(
                        child: Text(
                          AppStrings.customersEmpty,
                          style: AppText.body.copyWith(color: inkMuted),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refreshList,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: data.customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: CustomerListMetrics.cardGap),
                        itemBuilder: (context, index) {
                          final customer = data.customers[index];
                          return CustomerListTile(
                            name: customer.fullName,
                            address: customer.shortAddress,
                            status: customer.displayStatus,
                            subscriptionCount: customer.subscriptionCount,
                            onVacationTap: () => _openVacationSheet(customer),
                            onTap: () => context.push('/owner/customers/${customer.id}'),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: CustomerListFab(
              onPressed: () => OwnerActionSheets.openAddCustomer(context),
            ),
          ),
        ],
      ),
    );
  }
}
