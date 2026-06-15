import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/action_toast.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/owner_models.dart';
import '../providers/owner_provider.dart';
import '../widgets/customer_edit_sheets.dart';
import '../widgets/customer_detail/customer_detail_styles.dart';
import '../widgets/customer_detail/customer_detail_widgets.dart';
import '../widgets/owner_design_system.dart';
import '../widgets/owner_action_sheets.dart';
import '../widgets/vacation_sheet.dart';
import '../../../../core/widgets/app_snackbar.dart';

class _SubscriptionLineView {
  const _SubscriptionLineView({
    required this.index,
    required this.subscription,
    required this.line,
  });

  final int index;
  final CustomerSubscriptionDetail subscription;
  final SubscriptionLineDetail line;
}

List<_SubscriptionLineView> _flattenSubscriptionLines(List<CustomerSubscriptionDetail> subscriptions) {
  final items = <_SubscriptionLineView>[];
  var index = 0;
  for (final subscription in subscriptions) {
    for (final line in subscription.lines) {
      index++;
      items.add(_SubscriptionLineView(index: index, subscription: subscription, line: line));
    }
  }
  return items;
}

class CustomerDetailPage extends ConsumerStatefulWidget {
  const CustomerDetailPage({super.key, required this.customerId});

  final int customerId;

  @override
  ConsumerState<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends ConsumerState<CustomerDetailPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _showAllBills = false;

  CustomerDetailQuery get _query => CustomerDetailQuery(
        customerId: widget.customerId,
        billingMonth: _month,
      );

  String _billingMonthParam(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

  SubscriptionLineDetail _lineForCalendar(_SubscriptionLineView item) => item.line;

  DateTime? _parseVacationDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Future<void> _deleteCustomer(int id) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: AppStrings.deleteCustomerTitle,
      message: AppStrings.deleteCustomerConfirm,
      confirmLabel: AppStrings.deleteLabel,
      cancelLabel: AppStrings.cancelLabel,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(ownerRepositoryProvider).deleteCustomer(id);
      if (mounted) {
        ref.invalidate(customersListProvider);
        AppSnackBar.show(context, AppStrings.deleteCustomerDone);
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        final message = e.code == 'CUSTOMER_HAS_UNPAID_BILLS' || e.code == 'CUSTOMER_HAS_HISTORY'
            ? AppStrings.deleteCustomerBlocked
            : e.message;
        AppSnackBar.show(context, message);
      }
    }
  }

  Future<void> _openVacationSheet(CustomerDetailInfo customer) async {
    await VacationSheet.show(
      context,
      customerName: customer.fullName,
      initialStart: _parseVacationDate(customer.vacationStart),
      initialEnd: _parseVacationDate(customer.vacationEnd),
      onUpdate: (start, end) async {
        try {
          await ref.read(ownerRepositoryProvider).updateCustomer(
                customer.id,
                end == null && start == null
                    ? const CustomerUpdateRequest(clearVacation: true)
                    : CustomerUpdateRequest(vacationStart: start, vacationEnd: end),
              );
          if (mounted) ref.invalidate(customerDetailProvider(_query));
        } on ApiException catch (e) {
          if (mounted) {
            AppSnackBar.show(context, e.message);
          }
        }
      },
    );
  }

  Future<void> _sendMilkLog({
    required CustomerDetailResult data,
    required SubscriptionLineDetail line,
  }) async {
    if (!data.customer.whatsappEnabled) {
      if (mounted) {
        AppSnackBar.show(context, AppStrings.whatsappNo);
      }
      return;
    }

    try {
      await ActionToast.run(
        context,
        preparing: AppStrings.milkLogPreparing,
        success: AppStrings.milkLogSent,
        onError: AppStrings.milkLogSendFailed,
        task: () => ref.read(ownerRepositoryProvider).sendMilkLog(
              customerId: data.customer.id,
              billingMonth: _billingMonthParam(_month),
              subscriptionLineId: line.id,
            ),
      );
    } on ApiException catch (e) {
      if (mounted) ActionToast.show(context, e.message);
    }
  }

  Future<void> _showMilkLogActions({
    required CustomerDetailResult data,
    required SubscriptionLineDetail line,
  }) async {
    await showOwnerBottomSheet<void>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerSheetTitle(AppStrings.milkLogActionsTitle, subtitle: line.productName),
          const SizedBox(height: 16),
          OwnerSheetActions(
            primaryLabel: AppStrings.sendToCustomer,
            onPrimary: () async {
              Navigator.pop(context);
              await _sendMilkLog(data: data, line: line);
            },
            secondaryLabel: AppStrings.updateOrderLog,
            onSecondary: () async {
              Navigator.pop(context);
              await UpdateOrderLogSheet.show(
                context,
                customerId: data.customer.id,
                billingMonth: _billingMonthParam(_month),
                lineId: line.id,
                productName: line.productName,
              );
              if (mounted) ref.invalidate(customerDetailProvider(_query));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _remindCustomer(CustomerDetailInfo customer, double pending) async {
    if (!customer.whatsappEnabled) {
      if (mounted) {
        AppSnackBar.show(context, AppStrings.whatsappNo);
      }
      return;
    }

    final digits = customer.contact.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return;
    final amount = NumberFormat('#,##0', 'en_IN').format(pending.round());
    final message = Uri.encodeComponent(
      'Namaste ${customer.firstName}, your pending milk bill balance is ₹$amount. Please arrange payment at your convenience. – LactoSync',
    );
    final uri = Uri.parse('https://wa.me/91$digits?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<OwnerInvoice> _billsThroughMonth(List<OwnerInvoice> bills, String selectedMonth) {
    final normalizedSelected = normalizeBillingMonth(selectedMonth);
    return bills
        .where(
          (bill) =>
              normalizeBillingMonth(bill.billingMonth).compareTo(normalizedSelected) <= 0,
        )
        .toList()
      ..sort(
        (a, b) => normalizeBillingMonth(b.billingMonth)
            .compareTo(normalizeBillingMonth(a.billingMonth)),
      );
  }

  String _formatAmount(double value) {
    return NumberFormat('#,##0', 'en_IN').format(value.round());
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(customerDetailProvider(_query));

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            detailAsync.maybeWhen(
              data: (data) => CustomerDetailHeader(
                onBack: () => context.pop(),
                onDelete: () => _deleteCustomer(data.customer.id),
                onEdit: () => context.push('/owner/customers/${widget.customerId}/edit'),
              ),
              orElse: () => CustomerDetailHeader(onBack: () => context.pop()),
            ),
            Expanded(
              child: detailAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: CustomerDetailColors.accent),
                ),
                error: (_, __) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(customerDetailProvider(_query)),
                    child: const Text('Retry'),
                  ),
                ),
                data: (data) {
                  final customer = data.customer;
                  final subscriptionLines = _flattenSubscriptionLines(data.subscriptions);
                  final selectedBillingMonth = _billingMonthParam(_month);
                  final monthBills =
                      _billsThroughMonth(data.billingHistory, selectedBillingMonth);
                  final visibleBills = _showAllBills
                      ? monthBills
                      : monthBills.take(3).toList();
                  final (_, aggregatePending) = billingHistoryAggregateTotals(monthBills);
                  final pendingBills = data.billingHistory
                      .where((b) => b.status != 'paid' && billingChipAmount(b) > 0)
                      .toList();
                  final cumulativePending = billingHistoryAggregateTotals(data.billingHistory).$2;
                  final cumulativePaid = data.billingHistory
                      .fold<double>(0, (sum, b) => sum + b.amountPaid);
                  final isOnVacation = customer.displayStatus == CustomerDisplayStatus.vacation;

                  return RefreshIndicator(
                    color: CustomerDetailColors.accent,
                    onRefresh: () async {
                      ref.invalidate(customerDetailProvider(_query));
                      await ref.read(customerDetailProvider(_query).future);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                      children: [
                        CustomerDetailHeroCard(
                          customer: customer,
                          monthTotal: data.consumption.grandTotal,
                          pendingTotal: aggregatePending,
                          subscriptionCount: subscriptionLines.length,
                        ),
                        const SizedBox(height: 16),
                        CustomerDetailVacationCard(
                          isOnVacation: isOnVacation,
                          onPauseTap: () => _openVacationSheet(customer),
                        ),
                        const SizedBox(height: 12),
                        CustomerDetailMonthNav(
                          month: _month,
                          onPrevious: () => setState(() {
                            _month = DateTime(_month.year, _month.month - 1);
                            _showAllBills = false;
                          }),
                          onNext: () => setState(() {
                            _month = DateTime(_month.year, _month.month + 1);
                            _showAllBills = false;
                          }),
                        ),
                        CustomerDetailSectionLabel(
                          title: AppStrings.subscriptionsTitle.toUpperCase(),
                          trailing: CustomerDetailAddChip(
                            label: 'Add',
                            onTap: () async {
                              final settings = await ref.read(ownerSettingsProvider.future);
                              if (!context.mounted) return;
                              await CreateSubscriptionSheet.show(
                                context,
                                customerId: widget.customerId,
                                products: settings.products,
                              );
                              if (mounted) ref.invalidate(customerDetailProvider(_query));
                            },
                          ),
                        ),
                        if (subscriptionLines.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              AppStrings.noSubscriptions,
                              style: AppText.body.copyWith(
                                color: CustomerDetailColors.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          ...subscriptionLines.asMap().entries.map((entry) {
                            final item = entry.value;
                            final line = _lineForCalendar(item);
                            return CustomerDetailSubscriptionCard(
                              index: item.index,
                              line: line,
                              month: _month,
                              initiallyExpanded: entry.key == subscriptionLines.length - 1,
                              onEdit: () async {
                                final settings = await ref.read(ownerSettingsProvider.future);
                                if (!context.mounted) return;
                                await EditSubscriptionSheet.show(
                                  context,
                                  subscription: item.subscription,
                                  line: item.line,
                                  products: settings.products,
                                );
                                if (mounted) ref.invalidate(customerDetailProvider(_query));
                              },
                              onDelete: () async {
                                final confirmed = await showAppConfirmDialog(
                                  context: context,
                                  title: AppStrings.deleteSubscriptionTitle,
                                  message: AppStrings.deleteSubscriptionConfirm,
                                  confirmLabel: AppStrings.deleteLabel,
                                  cancelLabel: AppStrings.cancelLabel,
                                  destructive: true,
                                );
                                if (confirmed != true || !mounted) return;

                                try {
                                  await ref.read(ownerRepositoryProvider).deleteSubscription(
                                        item.subscription.id,
                                      );
                                  if (mounted) {
                                    ref.invalidate(customerDetailProvider(_query));
                                    AppSnackBar.show(context, AppStrings.deleteSubscriptionDone);
                                  }
                                } on ApiException catch (e) {
                                  if (mounted) {
                                    final message = switch (e.code) {
                                      'CUSTOMER_HAS_UNPAID_BILLS' =>
                                        AppStrings.deleteSubscriptionBlockedUnpaid,
                                      'SUBSCRIPTION_IN_USE' => AppStrings.deleteSubscriptionBlocked,
                                      _ => e.message,
                                    };
                                    AppSnackBar.show(context, message);
                                  }
                                }
                              },
                              onLongPressCalendar: () => _showMilkLogActions(
                                data: data,
                                line: item.line,
                              ),
                            );
                          }),
                        CustomerDetailSectionLabel(title: AppStrings.consumptionTitle.toUpperCase()),
                        if (data.consumption.rows.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              AppStrings.noConsumptionRecorded,
                              style: AppText.body.copyWith(
                                color: CustomerDetailColors.onSurfaceVariant,
                              ),
                            ),
                          )
                        else
                          CustomerDetailConsumptionCard(
                            rows: data.consumption.rows,
                            grandTotal: data.consumption.grandTotal,
                          ),
                        CustomerDetailSectionLabel(title: 'DUES & BILLING'),
                        CustomerDetailDuesCard(
                          pending: cumulativePending,
                          paid: cumulativePaid,
                          onRecordPayment: pendingBills.isEmpty
                              ? null
                              : () async {
                                  await OwnerActionSheets.showCollectPaymentForCustomer(
                                    context,
                                    ref,
                                    customerId: customer.id,
                                    customerName: customer.fullName,
                                    pendingBills: pendingBills,
                                    onSuccess: () {
                                      if (mounted) ref.invalidate(customerDetailProvider(_query));
                                    },
                                  );
                                },
                          onRemind: cumulativePending > 0
                              ? () => _remindCustomer(customer, cumulativePending)
                              : null,
                        ),
                        CustomerDetailBillingHistorySection(
                          bills: monthBills,
                          visibleBills: visibleBills,
                          showAllBills: _showAllBills,
                          onGenerateBill: () async {
                            await OwnerActionSheets.showGenerateBillForCustomer(
                              context,
                              ref,
                              customerId: customer.id,
                              customerName: customer.fullName,
                              initialMonth: _month,
                            );
                            if (mounted) ref.invalidate(customerDetailProvider(_query));
                          },
                          onBillTap: (invoice) =>
                              context.push('/owner/billing/${invoice.id}'),
                          onToggleShowAll: monthBills.length > 3
                              ? () => setState(() => _showAllBills = !_showAllBills)
                              : null,
                          emptyMessage: AppStrings.noBillsGenerated,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  AppStrings.paymentsLogTitle,
                                  style: AppText.cardTitle.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: CustomerDetailColors.onSurface,
                                  ),
                                ),
                              ),
                              if (pendingBills.isNotEmpty)
                                CustomerDetailIconAction(
                                  icon: Icons.add_card_outlined,
                                  onTap: () async {
                                    await OwnerActionSheets.showCollectPaymentForCustomer(
                                      context,
                                      ref,
                                      customerId: customer.id,
                                      customerName: customer.fullName,
                                      pendingBills: pendingBills,
                                      onSuccess: () {
                                        if (mounted) ref.invalidate(customerDetailProvider(_query));
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        if (data.payments.isEmpty)
                          Text(
                            AppStrings.noPaymentsThisMonth,
                            style: AppText.body.copyWith(
                              color: CustomerDetailColors.onSurfaceVariant,
                            ),
                          )
                        else
                          for (final payment in data.payments)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: CustomerDetailPaymentRow(
                                invoiceRef: payment.invoiceNumber ?? 'Payment',
                                dateLabel: payment.paymentDate,
                                method: payment.paymentMethodLabel,
                                amount: _formatAmount(payment.amount),
                              ),
                            ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
