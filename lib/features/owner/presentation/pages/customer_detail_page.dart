import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/action_toast.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../domain/entities/owner_models.dart';
import '../providers/owner_provider.dart';
import '../widgets/customer_edit_sheets.dart';
import '../widgets/owner_design_system.dart';
import '../widgets/owner_shared_widgets.dart';
import '../widgets/owner_action_sheets.dart';
import '../widgets/owner_form_theme.dart';
import '../widgets/owner_widgets.dart';

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

  String _formatBillingMonth(String value) {
    final parsed = DateTime.tryParse('$value-01');
    if (parsed == null) return value;
    return DateFormat('MMMM yyyy').format(parsed);
  }

  String _nextBillLabel() {
    final nextMonth = DateTime(_month.year, _month.month + 1, 1);
    return '${AppStrings.nextBillOnPrefix} ${DateFormat('MMMM').format(nextMonth)}';
  }

  String _billStatusLabel(String status) {
    return switch (status) {
      'paid' => AppStrings.billStatusPaid,
      'partial' => AppStrings.billStatusPartial,
      _ => AppStrings.billStatusPending,
    };
  }

  Color _billStatusColor(String status, BuildContext context) {
    return switch (status) {
      'paid' => AppColors.success,
      'partial' => Theme.of(context).colorScheme.primary,
      _ => AppColors.danger,
    };
  }

  Color _customerStatusColor(CustomerDisplayStatus status) {
    return switch (status) {
      CustomerDisplayStatus.active => AppColors.success,
      CustomerDisplayStatus.inactive => AppColors.danger,
      CustomerDisplayStatus.vacation => AppColors.inkMuted,
    };
  }

  String _customerStatusLabel(CustomerDisplayStatus status) {
    return switch (status) {
      CustomerDisplayStatus.active => AppStrings.kpiActive,
      CustomerDisplayStatus.inactive => AppStrings.kpiInactive,
      CustomerDisplayStatus.vacation => AppStrings.onVacationLabel,
    };
  }

  String _formatDayLog(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    return DateFormat('dd, EEEE').format(parsed);
  }

  String _billingMonthParam(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.deleteCustomerDone)),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        final message = e.code == 'CUSTOMER_HAS_UNPAID_BILLS' || e.code == 'CUSTOMER_HAS_HISTORY'
            ? AppStrings.deleteCustomerBlocked
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  Future<void> _sendMilkLog({
    required CustomerDetailResult data,
    required SubscriptionLineDetail line,
  }) async {
    if (!data.customer.whatsappEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.whatsappNo)),
        );
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
          const SizedBox(height: AppSpace.lg),
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

  String _qtyCell(double? value) {
    if (value == null || value <= 0) return '—';
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  (double paid, double pending) _billingTotals(List<OwnerInvoice> bills) {
    var paid = 0.0;
    var pending = 0.0;
    for (final bill in bills) {
      paid += bill.amountPaid;
      pending += bill.balanceDue;
    }
    return (paid, pending);
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(customerDetailProvider(_query));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return Scaffold(
      backgroundColor: OwnerTheme.background,
      appBar: ownerDetailAppBar(
        title: AppStrings.customerDetailTitle,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.lg),
            child: detailAsync.maybeWhen(
              data: (data) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OwnerAddButton(
                    tooltip: AppStrings.deleteCustomerTitle,
                    icon: Icons.delete_outline,
                    iconColor: AppColors.danger,
                    onPressed: () => _deleteCustomer(data.customer.id),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  OwnerAddButton(
                    tooltip: AppStrings.editCustomerTitle,
                    icon: Icons.edit_outlined,
                    onPressed: () async {
                      await EditCustomerSheet.show(context, data.customer);
                      if (mounted) ref.invalidate(customerDetailProvider(_query));
                    },
                  ),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(customerDetailProvider(_query)),
            child: const Text('Retry'),
          ),
        ),
        data: (data) {
          final customer = data.customer;
          final subscriptionLines = _flattenSubscriptionLines(data.subscriptions);
          final visibleBills = _showAllBills
              ? data.billingHistory
              : data.billingHistory.take(3).toList();
          final (totalPaid, totalPending) = _billingTotals(data.billingHistory);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(customerDetailProvider(_query));
              await ref.read(customerDetailProvider(_query).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              customer.fullName,
                              style: AppText.screenTitle.copyWith(
                                fontSize: 22,
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          OwnerStatusBadge(
                            label: _customerStatusLabel(customer.displayStatus),
                            color: _customerStatusColor(customer.displayStatus),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      OwnerContactRow(
                        icon: Icons.phone_outlined,
                        text: customer.contact,
                      ),
                      const SizedBox(height: AppSpace.sm),
                      OwnerContactRow(
                        icon: Icons.location_on_outlined,
                        text: customer.fullAddress,
                      ),
                      if (customer.displayStatus == CustomerDisplayStatus.vacation &&
                          customer.vacationStart != null &&
                          customer.vacationEnd != null) ...[
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          '${AppStrings.vacationStartLabel}: ${customer.vacationStart} · ${AppStrings.vacationEndLabel}: ${customer.vacationEnd}',
                          style: AppText.meta.copyWith(color: inkMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                const OwnerSectionHeader(title: AppStrings.monthActivityTitle),
                const SizedBox(height: AppSpace.sm),
                BorderedMonthNavigator(
                  month: _month,
                  onPrevious: () => setState(
                    () => _month = DateTime(_month.year, _month.month - 1),
                  ),
                  onNext: () => setState(
                    () => _month = DateTime(_month.year, _month.month + 1),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                OwnerSectionHeader(
                  title: AppStrings.subscriptionsTitle,
                  uppercase: true,
                  trailing: OwnerAddButton(
                    tooltip: AppStrings.addSubscriptionTitle,
                    onPressed: () async {
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
                const SizedBox(height: AppSpace.sm),
                if (subscriptionLines.isEmpty)
                  OwnerEmptyRowCard(
                    icon: Icons.inventory_2_outlined,
                    message: AppStrings.noSubscriptions,
                    iconBackground: OwnerTheme.chipFill,
                    iconColor: OwnerTheme.primary,
                  )
                else
                  ...subscriptionLines.map(
                    (item) => _SubscriptionLineCard(
                      index: item.index,
                      line: item.line,
                      subscription: item.subscription,
                      formatDay: _formatDayLog,
                      qtyCell: _qtyCell,
                      inkMuted: inkMuted,
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text(AppStrings.deleteSubscriptionDone)),
                            );
                          }
                        } on ApiException catch (e) {
                          if (mounted) {
                            final message = switch (e.code) {
                              'CUSTOMER_HAS_UNPAID_BILLS' => AppStrings.deleteSubscriptionBlockedUnpaid,
                              'SUBSCRIPTION_IN_USE' => AppStrings.deleteSubscriptionBlocked,
                              _ => e.message,
                            };
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          }
                        }
                      },
                      onLongPressTable: () => _showMilkLogActions(
                        data: data,
                        line: item.line,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpace.lg),
                OwnerSectionHeader(title: AppStrings.consumptionTitle),
                const SizedBox(height: AppSpace.sm),
                if (data.consumption.rows.isEmpty)
                  OwnerDashedEmptyCard(
                    icon: Icons.local_shipping_outlined,
                    message: AppStrings.noConsumptionRecorded,
                  )
                else
                  AppCard(
                    child: Column(
                      children: [
                        _ConsumptionHeader(inkMuted: inkMuted),
                        ...data.consumption.rows.map(
                          (row) => _ConsumptionRow(row: row, inkMuted: inkMuted),
                        ),
                        const Divider(height: AppSpace.lg),
                        _ConsumptionGrandTotal(grandTotal: data.consumption.grandTotal),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpace.lg),
                OwnerSectionHeader(
                  title: AppStrings.billingHistoryTitle,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data.billingHistory.isNotEmpty) ...[
                        OwnerMetricBadge(
                          label: '${AppStrings.billingPaidShort} ₹${totalPaid.toStringAsFixed(0)}',
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSpace.sm),
                        OwnerMetricBadge(
                          label: '${AppStrings.billingPendingShort} ₹${totalPending.toStringAsFixed(0)}',
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: AppSpace.sm),
                      ],
                      OwnerAddButton(
                        tooltip: AppStrings.recalculateBillTooltip,
                        icon: Icons.receipt_long_outlined,
                        onPressed: () async {
                          await OwnerActionSheets.showGenerateBillForCustomer(
                            context,
                            ref,
                            customerId: customer.id,
                            customerName: customer.fullName,
                            initialMonth: _month,
                          );
                          if (mounted) ref.invalidate(customerDetailProvider(_query));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                if (data.billingHistory.isEmpty)
                  OwnerEmptyRowCard(
                    icon: Icons.receipt_long_outlined,
                    message: AppStrings.noBillsGenerated,
                    subtitle: _nextBillLabel(),
                    iconBackground: AppColors.dangerFaint,
                    iconColor: AppColors.danger,
                  )
                else ...[
                  ...visibleBills.map(
                    (invoice) => _BillingHistoryRow(
                      invoice: invoice,
                      monthLabel: _formatBillingMonth(invoice.billingMonth),
                      statusLabel: _billStatusLabel(invoice.status),
                      statusColor: _billStatusColor(invoice.status, context),
                      onTap: () => context.push('/owner/billing/${invoice.id}'),
                    ),
                  ),
                  if (data.billingHistory.length > 3)
                    TextButton(
                      onPressed: () => setState(() => _showAllBills = !_showAllBills),
                      child: Text(_showAllBills ? AppStrings.showLessBills : AppStrings.showMoreBills),
                    ),
                ],
                const SizedBox(height: AppSpace.lg),
                OwnerSectionHeader(
                  title: AppStrings.paymentsLogTitle,
                  trailing: () {
                    final pendingBills = data.billingHistory
                        .where((b) => b.balanceDue > 0)
                        .toList();
                    if (pendingBills.isEmpty) return null;
                    return OwnerAddButton(
                      tooltip: AppStrings.recordPaymentButton,
                      icon: Icons.add_card_outlined,
                      onPressed: () async {
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
                    );
                  }(),
                ),
                const SizedBox(height: AppSpace.sm),
                if (data.payments.isEmpty)
                  OwnerEmptyRowCard(
                    icon: Icons.account_balance_wallet_outlined,
                    message: AppStrings.noPaymentsThisMonth,
                  )
                else
                  ...data.payments.map(
                    (payment) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.sm),
                      child: PaymentListTile(payment: payment, compact: true),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SubscriptionLineCard extends StatefulWidget {
  const _SubscriptionLineCard({
    required this.index,
    required this.line,
    required this.subscription,
    required this.formatDay,
    required this.qtyCell,
    required this.inkMuted,
    this.onEdit,
    this.onDelete,
    this.onLongPressTable,
  });

  final int index;
  final SubscriptionLineDetail line;
  final CustomerSubscriptionDetail subscription;
  final String Function(String) formatDay;
  final String Function(double?) qtyCell;
  final Color inkMuted;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPressTable;

  @override
  State<_SubscriptionLineCard> createState() => _SubscriptionLineCardState();
}

class _SubscriptionLineCardState extends State<_SubscriptionLineCard> {
  bool _expanded = false;

  List<SubscriptionDayOrder> get _lineDailyOrders {
    if (widget.line.dailyOrders.isNotEmpty) return widget.line.dailyOrders;
    return widget.subscription.dailyOrders;
  }

  List<SubscriptionDayOrder> get _visibleDailyOrders {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return _lineDailyOrders.where((day) {
      final parsed = DateTime.tryParse(day.date);
      if (parsed == null) return true;
      final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
      return !dateOnly.isAfter(today);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = OwnerFormTheme.borderColor;
    final line = widget.line;
    final rate = line.couponAmount > 0 ? line.effectiveRate : line.unitRate;
    final shiftIcon = line.shift == 'evening' ? Icons.nightlight_round : Icons.wb_sunny_outlined;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grayRow = isDark ? AppColors.darkBorder.withValues(alpha: 0.35) : const Color(0xFFF3F4F6);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppStrings.subscriptionIdLabel} #${widget.index}',
                        style: AppText.meta.copyWith(color: widget.inkMuted),
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        line.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cardTitle.copyWith(
                          fontSize: 15,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Row(
                        children: [
                          OwnerMintChip(
                            icon: Icons.payments_outlined,
                            label: '₹${rate.toStringAsFixed(0)}${AppStrings.perLtr}',
                          ),
                          const SizedBox(width: AppSpace.xs),
                          OwnerMintChip(
                            icon: shiftIcon,
                            label: line.shiftLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (widget.onDelete != null || widget.onEdit != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onDelete != null) ...[
                            OwnerCircleActionButton(
                              icon: Icons.delete_outline,
                              onPressed: widget.onDelete,
                            ),
                            const SizedBox(width: AppSpace.sm),
                          ],
                          if (widget.onEdit != null)
                            OwnerCircleActionButton(
                              icon: Icons.edit_outlined,
                              onPressed: widget.onEdit,
                            ),
                        ],
                      ),
                    const SizedBox(height: AppSpace.xs),
                    OwnerCircleActionButton(
                      icon: _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      onPressed: () => setState(() => _expanded = !_expanded),
                    ),
                  ],
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: AppSpace.md),
              if (_visibleDailyOrders.isEmpty)
                Text(AppStrings.noConsumptionRecorded, style: AppText.meta.copyWith(color: widget.inkMuted))
              else
                GestureDetector(
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    widget.onLongPressTable?.call();
                  },
                  child: Table(
                    border: TableBorder.all(color: borderColor.withValues(alpha: 0.7)),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: borderColor.withValues(alpha: 0.12)),
                        children: [
                          _GridCell(AppStrings.tableDate, widget.inkMuted, align: TextAlign.left),
                          _GridCell(AppStrings.tableMorning, widget.inkMuted),
                          _GridCell(AppStrings.tableEvening, widget.inkMuted),
                        ],
                      ),
                      ..._visibleDailyOrders.map(
                        (day) => TableRow(
                          decoration: day.hasDelivery
                              ? null
                              : BoxDecoration(color: grayRow),
                          children: [
                            _GridCell(
                              widget.formatDay(day.date),
                              widget.inkMuted,
                              align: TextAlign.left,
                              bold: true,
                              muted: !day.hasDelivery,
                            ),
                            _GridCell(
                              widget.qtyCell(day.morning),
                              widget.inkMuted,
                              muted: !day.hasDelivery,
                            ),
                            _GridCell(
                              widget.qtyCell(day.evening),
                              widget.inkMuted,
                              muted: !day.hasDelivery,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell(
    this.text,
    this.inkMuted, {
    this.align = TextAlign.center,
    this.bold = false,
    this.muted = false,
  });

  final String text;
  final Color inkMuted;
  final TextAlign align;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final horizontal = align == TextAlign.left ? AppSpace.md : AppSpace.sm;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: AppSpace.xs),
      child: Text(
        text,
        textAlign: align,
        style: (bold ? AppText.label : AppText.meta).copyWith(
          color: muted ? inkMuted : (bold ? null : inkMuted),
          fontWeight: bold ? FontWeight.w600 : null,
        ),
      ),
    );
  }
}

abstract final class _ConsumptionColumns {
  static const productFlex = 3;
  static const valueFlex = 1;
}

class _ConsumptionHeader extends StatelessWidget {
  const _ConsumptionHeader({required this.inkMuted});

  final Color inkMuted;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppText.meta.copyWith(color: inkMuted);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Row(
        children: [
          Expanded(flex: _ConsumptionColumns.productFlex, child: Text('Product', style: labelStyle)),
          Expanded(
            flex: _ConsumptionColumns.valueFlex,
            child: Text('Rate', textAlign: TextAlign.right, style: labelStyle),
          ),
          Expanded(
            flex: _ConsumptionColumns.valueFlex,
            child: Text('Qty', textAlign: TextAlign.right, style: labelStyle),
          ),
          Expanded(
            flex: _ConsumptionColumns.valueFlex,
            child: Text('Amount', textAlign: TextAlign.right, style: labelStyle),
          ),
        ],
      ),
    );
  }
}

class _ConsumptionRow extends StatelessWidget {
  const _ConsumptionRow({required this.row, required this.inkMuted});

  final ConsumptionRow row;
  final Color inkMuted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: _ConsumptionColumns.productFlex, child: Text(row.productName, style: AppText.label)),
          Expanded(
            flex: _ConsumptionColumns.valueFlex,
            child: Text(
              '₹${row.unitRate.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: AppText.meta,
            ),
          ),
          Expanded(
            flex: _ConsumptionColumns.valueFlex,
            child: Text(
              '${row.totalQuantity} ltr',
              textAlign: TextAlign.right,
              style: AppText.meta,
            ),
          ),
          Expanded(
            flex: _ConsumptionColumns.valueFlex,
            child: Text(
              '₹${row.lineTotal.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: AppText.label,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsumptionGrandTotal extends StatelessWidget {
  const _ConsumptionGrandTotal({required this.grandTotal});

  final double grandTotal;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: _ConsumptionColumns.productFlex,
          child: Text(AppStrings.grandTotal, style: AppText.label),
        ),
        const Expanded(flex: _ConsumptionColumns.valueFlex, child: SizedBox.shrink()),
        const Expanded(flex: _ConsumptionColumns.valueFlex, child: SizedBox.shrink()),
        Expanded(
          flex: _ConsumptionColumns.valueFlex,
          child: Text(
            '₹${grandTotal.toStringAsFixed(0)}',
            textAlign: TextAlign.right,
            style: AppText.label.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _BillingHistoryRow extends StatelessWidget {
  const _BillingHistoryRow({
    required this.invoice,
    required this.monthLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  final OwnerInvoice invoice;
  final String monthLabel;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Material(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
            child: Row(
              children: [
                Expanded(child: Text(monthLabel, style: AppText.label)),
                Text(
                  statusLabel,
                  style: AppText.label.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: AppSpace.sm),
                Text(
                  '₹${invoice.totalAmount.toStringAsFixed(0)}',
                  style: AppText.label.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
