import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
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

class PaymentsPage extends ConsumerStatefulWidget {
  const PaymentsPage({super.key});

  @override
  ConsumerState<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends ConsumerState<PaymentsPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  PaymentMethodFilter _method = PaymentMethodFilter.all;
  final _searchController = TextEditingController();
  String _search = '';
  CustomerSort _sort = CustomerSort.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OwnerPayment> _filterAndSort(List<OwnerPayment> payments) {
    var list = payments;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) => p.customerName.toLowerCase().contains(q)).toList();
    }
    list = List<OwnerPayment>.from(list);
    list.sort((a, b) {
      final cmp = a.customerName.toLowerCase().compareTo(b.customerName.toLowerCase());
      return switch (_sort) {
        CustomerSort.nameDesc => -cmp,
        CustomerSort.updatedDesc => b.id.compareTo(a.id),
        CustomerSort.updatedAsc => a.id.compareTo(b.id),
        _ => cmp,
      };
    });
    return list;
  }

  ({double cash, double upi}) _methodTotals(List<OwnerPayment> payments) {
    var cash = 0.0;
    var upi = 0.0;
    for (final payment in payments) {
      if (payment.paymentMethod == 'cash') {
        cash += payment.amount;
      } else if (payment.paymentMethod == 'upi') {
        upi += payment.amount;
      }
    }
    return (cash: cash, upi: upi);
  }

  void _showSortMenu() {
    showOwnerBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OwnerSheetHeader(title: AppStrings.sortLabel, icon: LucideIcons.arrowUpDown),
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

  PaymentsQuery get _query => PaymentsQuery(
        billingMonth: _month,
        paymentMethod: _method,
      );

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsListProvider(_query));
    final inkMuted = CustomerDetailColors.labelMuted;

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
                  Row(
                    children: [
                      Expanded(
                        flex: 13,
                        child: BorderedMonthNavigator(
                          month: _month,
                          compact: true,
                          onPrevious: () => setState(
                            () => _month = DateTime(_month.year, _month.month - 1),
                          ),
                          onNext: () => setState(
                            () => _month = DateTime(_month.year, _month.month + 1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 10,
                        child: BorderedFilterDropdown<PaymentMethodFilter>(
                          value: _method,
                          items: const [
                            DropdownMenuItem(value: PaymentMethodFilter.all, child: Text(AppStrings.paymentsFilterAll)),
                            DropdownMenuItem(value: PaymentMethodFilter.cash, child: Text(AppStrings.paymentsFilterCash)),
                            DropdownMenuItem(value: PaymentMethodFilter.upi, child: Text(AppStrings.paymentsFilterUpi)),
                            DropdownMenuItem(
                              value: PaymentMethodFilter.bankTransfer,
                              child: Text(AppStrings.paymentsFilterBank),
                            ),
                            DropdownMenuItem(value: PaymentMethodFilter.other, child: Text(AppStrings.paymentsFilterOther)),
                          ],
                          onChanged: (value) {
                            if (value != null) setState(() => _method = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  paymentsAsync.maybeWhen(
                    data: (data) {
                      final totals = _methodTotals(data.payments);
                      return OwnerGreenSummaryCard(
                        title: AppStrings.paymentsCollected,
                        amount: '₹${formatOwnerCurrency(data.totalCollected)}',
                        badge: '${data.payments.length} payments',
                        footerTiles: [
                          OwnerSummaryFooterTile(
                            label: AppStrings.paymentsFilterCash,
                            value: '₹${formatOwnerCurrency(totals.cash)}',
                            inline: true,
                          ),
                          OwnerSummaryFooterTile(
                            label: AppStrings.paymentsFilterUpi,
                            value: '₹${formatOwnerCurrency(totals.upi)}',
                            inline: true,
                          ),
                        ],
                      );
                    },
                    orElse: () => const SizedBox(height: 120),
                  ),
                  const SizedBox(height: 11),
                  OwnerSearchSortRow(
                    controller: _searchController,
                    hintText: AppStrings.searchCustomerLabel,
                    onChanged: (v) => setState(() => _search = v.trim()),
                    onSort: _showSortMenu,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: paymentsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: CustomerDetailColors.accent),
                ),
                error: (_, __) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(paymentsListProvider(_query)),
                    child: const Text('Retry'),
                  ),
                ),
                data: (data) {
                  if (data.payments.isEmpty) {
                    return Center(
                      child: Text(AppStrings.paymentsEmpty, style: AppText.body.copyWith(color: inkMuted)),
                    );
                  }
                  final payments = _filterAndSort(data.payments);
                  if (payments.isEmpty) {
                    return Center(
                      child: Text(AppStrings.paymentsEmpty, style: AppText.body.copyWith(color: inkMuted)),
                    );
                  }

                  return RefreshIndicator(
                    color: CustomerDetailColors.accent,
                    onRefresh: () async {
                      ref.invalidate(paymentsListProvider(_query));
                      await ref.read(paymentsListProvider(_query).future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 88),
                      itemCount: payments.length,
                      itemBuilder: (context, index) => PaymentListTile(payment: payments[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: OwnerPageFab(
            onPressed: () => OwnerActionSheets.showCollectPayment(context, ref),
          ),
        ),
      ],
    );
  }
}
