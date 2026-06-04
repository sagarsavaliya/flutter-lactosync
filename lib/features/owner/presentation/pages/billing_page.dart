import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/action_toast.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
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

class BillingPage extends ConsumerStatefulWidget {
  const BillingPage({super.key});

  @override
  ConsumerState<BillingPage> createState() => _BillingPageState();
}

class _BillingPageState extends ConsumerState<BillingPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _sendingBulk = false;
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

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(invoicesListProvider(_query));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final borderColor = OwnerFormTheme.borderColor;

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
                  BorderedMonthNavigator(
                    month: _month,
                    onPrevious: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1),
                    ),
                    onNext: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  OwnerSearchSortRow(
                    controller: _searchController,
                    hintText: AppStrings.searchCustomerLabel,
                    onChanged: (v) => setState(() => _search = v.trim()),
                    onSort: _showSortMenu,
                  ),
                  const SizedBox(height: AppSpace.md),
                  invoicesAsync.maybeWhen(
                    data: (data) => data.invoices.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.sm),
                            child: AppButton(
                              label: AppStrings.billingSendAll,
                              loading: _sendingBulk,
                              onPressed: _sendingBulk ? null : _sendAllBills,
                            ),
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  invoicesAsync.maybeWhen(
                    data: (data) => DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: borderColor),
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.md),
                        child: ThreeColumnAmountGrid(
                          columns: [
                            AmountGridColumn(
                              label: AppStrings.billingTotalBilled,
                              value: data.summary.totalAmount,
                              valueColor: Theme.of(context).colorScheme.primary,
                            ),
                            AmountGridColumn(
                              label: AppStrings.billingCollected,
                              value: data.summary.collected,
                              valueColor: AppColors.success,
                            ),
                            AmountGridColumn(
                              label: AppStrings.billingOutstanding,
                              value: data.summary.outstanding,
                              valueColor: AppColors.danger,
                            ),
                          ],
                        ),
                      ),
                    ),
                    orElse: () => const SizedBox(height: 88),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Expanded(
              child: invoicesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
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
                    onRefresh: () async {
                      ref.invalidate(invoicesListProvider(_query));
                      await ref.read(invoicesListProvider(_query).future);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, 88),
                      itemCount: invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = invoices[index];
                        return InvoiceListTile(
                          invoice: invoice,
                          onTap: () => context.push('/owner/billing/${invoice.id}'),
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
          right: AppSpace.lg,
          bottom: AppSpace.lg,
          child: OwnerPageFab(
            onPressed: () => OwnerActionSheets.showGenerateBill(context, ref),
          ),
        ),
      ],
    );
  }
}
