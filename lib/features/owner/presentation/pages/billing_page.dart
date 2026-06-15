import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/action_toast.dart';
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

class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _sendingBulk = false;
  final _sendingInvoiceIds = <int>{};
  final _searchController = TextEditingController();
  String _search = '';
  CustomerSort _sort = CustomerSort.nameAsc;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OwnerInvoice> _filterAndSort(List<OwnerInvoice> invoices) {
    var list = invoices;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((i) => i.customerName.toLowerCase().contains(q)).toList();
    }
    list = List<OwnerInvoice>.from(list);
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

  InvoicesQuery get _query => InvoicesQuery(billingMonth: _month);

  String get _billingMonthParam =>
      '${_month.year.toString().padLeft(4, '0')}-${_month.month.toString().padLeft(2, '0')}';

  Future<void> _sendAllBills() async {
    setState(() => _sendingBulk = true);
    try {
      final result = await ActionToast.run(
        context,
        preparing: AppStrings.billPreparing,
        success: AppStrings.billingSendAllSuccess,
        onError: AppStrings.billingSendFailed,
        task: () => ref.read(ownerRepositoryProvider).sendInvoicesBulk(_billingMonthParam),
      );
      if (!mounted) return;
      if (result.message.isNotEmpty) {
        ActionToast.show(context, '${AppStrings.billingSendAllSuccess} · ${result.message}');
      }
      ref.invalidate(invoicesListProvider(_query));
    } catch (_) {
      if (!mounted) return;
      ActionToast.show(context, AppStrings.billingSendFailed);
    } finally {
      if (mounted) setState(() => _sendingBulk = false);
    }
  }

  Future<void> _sendBill(OwnerInvoice invoice) async {
    setState(() => _sendingInvoiceIds.add(invoice.id));
    try {
      await ActionToast.run(
        context,
        preparing: AppStrings.billPreparing,
        success: AppStrings.billingSendSuccess,
        onError: AppStrings.billingSendFailed,
        task: () => ref.read(ownerRepositoryProvider).sendInvoice(invoice.id),
      );
      if (!mounted) return;
      ref.invalidate(invoicesListProvider(_query));
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : AppStrings.billingSendFailed;
      ActionToast.show(context, message);
    } finally {
      if (mounted) setState(() => _sendingInvoiceIds.remove(invoice.id));
    }
  }

  int _pendingCount(BillingSummary summary) => summary.unpaid + summary.partial;

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesListProvider(_query));
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
                  BorderedMonthNavigator(
                    month: _month,
                    onPrevious: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    ),
                    onNext: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1),
                    ),
                  ),
                  const SizedBox(height: 11),
                  invoicesAsync.maybeWhen(
                    data: (data) => OwnerGreenSummaryCard(
                      title: 'Outstanding this month',
                      amount: '₹${formatOwnerCurrency(data.summary.outstanding)}',
                      badge: '${_pendingCount(data.summary)} pending',
                      footerTiles: [
                        OwnerSummaryFooterTile(
                          label: AppStrings.billingTotalBilled,
                          value: '₹${formatOwnerCurrency(data.summary.totalAmount)}',
                        ),
                        OwnerSummaryFooterTile(
                          label: AppStrings.billingCollected,
                          value: '₹${formatOwnerCurrency(data.summary.collected)}',
                        ),
                      ],
                    ),
                    orElse: () => const SizedBox(height: 120),
                  ),
                  const SizedBox(height: 11),
                  BillingSearchSendRow(
                    searchChild: OwnerSearchSortRow(
                      controller: _searchController,
                      hintText: AppStrings.searchCustomerLabel,
                      onChanged: (v) => setState(() => _search = v.trim()),
                      onSort: _showSortMenu,
                    ),
                    sendLabel: 'Send all',
                    sending: _sendingBulk,
                    enabled: invoicesAsync.maybeWhen(
                      data: (data) => data.invoices.isNotEmpty,
                      orElse: () => false,
                    ),
                    onSend: _sendAllBills,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: invoicesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: CustomerDetailColors.accent),
                ),
                error: (_, __) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(invoicesListProvider(_query)),
                    child: const Text('Retry'),
                  ),
                ),
                data: (data) {
                  final invoices = _filterAndSort(data.invoices);
                  if (data.invoices.isEmpty) {
                    return Center(
                      child: Text(AppStrings.billingEmpty, style: AppText.body.copyWith(color: inkMuted)),
                    );
                  }
                  if (invoices.isEmpty) {
                    return Center(
                      child: Text(AppStrings.billingEmpty, style: AppText.body.copyWith(color: inkMuted)),
                    );
                  }

                  return RefreshIndicator(
                    color: CustomerDetailColors.accent,
                    onRefresh: () async {
                      ref.invalidate(invoicesListProvider(_query));
                      await ref.read(invoicesListProvider(_query).future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 88),
                      itemCount: invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return InvoiceListTile(
                          invoice: invoice,
                          sending: _sendingInvoiceIds.contains(invoice.id),
                          onTap: () => context.push('/owner/billing/${invoice.id}'),
                          onSend: () => _sendBill(invoice),
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
          right: 16,
          bottom: 16,
          child: OwnerPageFab(
            onPressed: () => OwnerActionSheets.showGenerateBill(context, ref),
          ),
        ),
      ],
    );
  }
}
