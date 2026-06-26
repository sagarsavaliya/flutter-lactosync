import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/owner_models.dart';
import '../../domain/entities/settings_models.dart';
import '../providers/owner_provider.dart';
import '../widgets/customer_list_styles.dart';
import '../widgets/customers_list_tile.dart';
import '../widgets/owner_design_system.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../widgets/owner_action_sheets.dart';
import '../widgets/vacation_sheet.dart';
import '../../../../core/widgets/app_snackbar.dart';

class _ListEntry {
  const _ListEntry.header(this.letter) : customer = null;
  const _ListEntry.customer(this.customer) : letter = null;

  final String? letter;
  final OwnerCustomer? customer;
}

class CustomersListPage extends ConsumerStatefulWidget {
  const CustomersListPage({super.key});

  @override
  ConsumerState<CustomersListPage> createState() => _CustomersListPageState();
}

class _CustomersListPageState extends ConsumerState<CustomersListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _sectionKeys = <String, GlobalKey>{};

  CustomerSort _sort = CustomerSort.nameAsc;
  Timer? _debounce;
  String _search = '';
  int? _productId;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _search = value.trim());
    });
  }

  CustomersQuery get _query => CustomersQuery(
        search: _search,
        sort: _sort,
        productId: _productId,
      );

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
          const SizedBox(height: 12),
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
            AppSnackBar.show(context, e.message);
          }
        }
      },
    );
  }

  List<_ListEntry> _buildEntries(List<OwnerCustomer> customers) {
    final entries = <_ListEntry>[];
    String? currentLetter;

    for (final customer in customers) {
      final letter = customerIndexLetter(customer.fullName);
      if (letter != currentLetter) {
        currentLetter = letter;
        entries.add(_ListEntry.header(letter));
      }
      entries.add(_ListEntry.customer(customer));
    }

    final letters = entries
        .where((e) => e.letter != null)
        .map((e) => e.letter!)
        .toSet();
    _sectionKeys.removeWhere((key, _) => !letters.contains(key));
    for (final letter in letters) {
      _sectionKeys.putIfAbsent(letter, GlobalKey.new);
    }

    return entries;
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return mapDioError(error).message;
  }

  List<String> _sectionLetters(List<_ListEntry> entries) {
    return entries
        .where((e) => e.letter != null)
        .map((e) => e.letter!)
        .toList();
  }

  void _scrollToLetter(String letter) {
    final key = _sectionKeys[letter];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: 0.05,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(customersListProvider(_query));
    final productsAsync = ref.watch(ownerProductsProvider);

    return ColoredBox(
      color: CustomerListColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: CustomersSearchSortRow(
                  controller: _searchController,
                  hintText: 'Search name, mobile...',
                  onChanged: _onSearchChanged,
                  onSort: _showSortMenu,
                ),
              ),
              productsAsync.when(
                loading: () => const SizedBox(height: 40),
                error: (_, __) => const SizedBox.shrink(),
                data: (products) {
                  if (products.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(AppStrings.customersFilterAllProducts),
                            selected: _productId == null,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _productId = null),
                          ),
                        ),
                        for (final OwnerProduct product in products)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                              selected: _productId == product.id,
                              showCheckmark: false,
                              onSelected: (_) => setState(() {
                                _productId = _productId == product.id ? null : product.id;
                              }),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Expanded(
                child: listAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: CustomerListColors.accent,
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 40,
                            color: CustomerListColors.addressMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage(error),
                            style: AppText.body.copyWith(
                              color: CustomerListColors.addressMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: CustomerListColors.accent,
                            ),
                            onPressed: _refreshList,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (data) {
                    if (data.customers.isEmpty) {
                      return Center(
                        child: Text(
                          AppStrings.customersEmpty,
                          style: AppText.body.copyWith(
                            color: CustomerListColors.addressMuted,
                          ),
                        ),
                      );
                    }

                    final entries = _buildEntries(data.customers);
                    final letters = _sectionLetters(entries);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: CustomersShiftSummaryCards(
                            morning: data.morning,
                            evening: data.evening,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: RefreshIndicator(
                                  color: CustomerListColors.accent,
                                  onRefresh: _refreshList,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 96),
                                    itemCount: entries.length,
                                    itemBuilder: (context, index) {
                                      final entry = entries[index];
                                      if (entry.letter != null) {
                                        return KeyedSubtree(
                                          key: _sectionKeys[entry.letter!],
                                          child: CustomersSectionHeader(
                                            letter: entry.letter!,
                                          ),
                                        );
                                      }

                                      final customer = entry.customer!;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: CustomerListMetrics.cardGap,
                                        ),
                                        child: CustomerListTile(
                                          name: customer.fullName,
                                          address: customer.shortAddress,
                                          status: customer.displayStatus,
                                          subscriptionCount: customer.subscriptionCount,
                                          vacationEnd: customer.vacationEnd,
                                          onVacationTap: customer.displayStatus ==
                                                  CustomerDisplayStatus.inactive
                                              ? null
                                              : () => _openVacationSheet(customer),
                                          onTap: () => context.push(
                                            '/owner/customers/${customer.id}',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              CustomersAlphabetIndex(
                                letters: letters,
                                onLetter: _scrollToLetter,
                              ),
                            ],
                          ),
                        ),
                      ],
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
