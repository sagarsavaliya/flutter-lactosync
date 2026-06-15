import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/action_toast.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/owner_models.dart';
import '../providers/owner_provider.dart';
import 'customer_detail/customer_detail_styles.dart';
import 'customer_list_styles.dart';
import 'owner_design_system.dart';
import 'owner_form_theme.dart';
import 'owner_screen_widgets.dart';
import 'owner_shared_widgets.dart';

class OwnerActionSheets {
  OwnerActionSheets._();

  static String _currentShift() {
    final hour = DateTime.now().hour;
    return hour < 15 ? 'morning' : 'evening';
  }

  static Future<void> showGenerateOrders(BuildContext context, WidgetRef ref) async {
    var date = DateTime.now();
    var shift = _currentShift();
    var loading = false;

    await showOwnerBottomSheet<void>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OwnerSheetTitle(AppStrings.generateOrdersTitle),
              const SizedBox(height: AppSpace.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppStrings.orderDateLabel, style: AppText.label),
                    subtitle: Text(DateFormat('d MMM yyyy').format(date)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setModalState(() => date = picked);
                    },
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'morning', label: Text(AppStrings.morningShift)),
                      ButtonSegment(value: 'evening', label: Text(AppStrings.eveningShift)),
                    ],
                    selected: {shift},
                    onSelectionChanged: (s) => setModalState(() => shift = s.first),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AppButton(
                    label: AppStrings.generateOrdersButton,
                    loading: loading,
                    onPressed: loading
                        ? null
                        : () async {
                            setModalState(() => loading = true);
                            try {
                              final result = await ref.read(ownerRepositoryProvider).generateDailyOrders(
                                    date: date,
                                    shift: shift,
                                  );
                              ref.invalidate(dailyOrdersProvider);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${AppStrings.generateOrdersSuccess} (${result.created})',
                                    ),
                                  ),
                                );
                              }
                            } on ApiException catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.message)),
                                );
                              }
                            } finally {
                              if (context.mounted) setModalState(() => loading = false);
                            }
                          },
                  ),
                ],
              );
        },
      ),
    );
  }

  static Future<void> showGenerateBill(BuildContext context, WidgetRef ref) async {
    final searchController = TextEditingController();
    var customers = <OwnerCustomer>[];
    OwnerCustomer? selected;
    var sendWhatsApp = false;
    var loading = false;
    var billingMonth = DateTime(DateTime.now().year, DateTime.now().month);
    var initialLoadDone = false;

    await showOwnerBottomSheet<void>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setModalState) {
            Future<void> search(String q) async {
              final result = await ref.read(ownerRepositoryProvider).fetchCustomers(
                    CustomersQuery(search: q, sort: CustomerSort.nameAsc),
                  );
              setModalState(() {
                customers = result.customers.take(20).toList();
                selected = customers.isNotEmpty ? customers.first : null;
              });
            }

            if (!initialLoadDone) {
              initialLoadDone = true;
              WidgetsBinding.instance.addPostFrameCallback((_) => search(''));
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const OwnerSheetHeader(
                    title: AppStrings.generateBillTitle,
                    icon: LucideIcons.fileText,
                  ),
                  const SizedBox(height: AppSpace.md),
                  const OwnerSheetFieldLabel('Billing month'),
                  BorderedMonthNavigator(
                    compact: true,
                    month: billingMonth,
                    onPrevious: () => setModalState(
                      () => billingMonth = DateTime(billingMonth.year, billingMonth.month - 1),
                    ),
                    onNext: () => setModalState(
                      () => billingMonth = DateTime(billingMonth.year, billingMonth.month + 1),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  const OwnerSheetFieldLabel('Customer'),
                  TextField(
                    controller: searchController,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                    decoration: OwnerFormTheme.searchDecoration(hintText: AppStrings.searchCustomerLabel),
                    onSubmitted: search,
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: CustomerDetailColors.rateChipBg,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: CustomerDetailColors.rateChipBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: CustomerDetailColors.avatarBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              customerInitials(selected!.fullName),
                              style: AppText.cardTitle.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: CustomerDetailColors.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              selected!.fullName,
                              style: AppText.cardTitle.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: CustomerDetailColors.onSurface,
                              ),
                            ),
                          ),
                          const Icon(LucideIcons.check, size: 20, color: CustomerDetailColors.accent),
                        ],
                      ),
                    ),
                  ] else if (customers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.sm),
                      child: Text(
                        AppStrings.billingEmpty,
                        style: AppText.meta.copyWith(color: CustomerDetailColors.labelMuted),
                      ),
                    )
                  else ...[
                    const SizedBox(height: AppSpace.sm),
                    DropdownButtonFormField<OwnerCustomer>(
                      value: selected,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.selectCustomerLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      items: customers
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.fullName)))
                          .toList(),
                      onChanged: (v) => setModalState(() => selected = v),
                    ),
                  ],
                  const SizedBox(height: AppSpace.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: CustomerDetailColors.surface,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: CustomerDetailColors.border),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppStrings.sendBillOnWhatsApp, style: AppText.cardTitle.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700)),
                      value: sendWhatsApp,
                      activeTrackColor: CustomerDetailColors.accent,
                      onChanged: (v) => setModalState(() => sendWhatsApp = v),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AppButton(
                    label: AppStrings.generateBillButton,
                    loading: loading,
                    onPressed: (selected == null || loading)
                        ? null
                        : () async {
                            setModalState(() => loading = true);
                            try {
                              if (sendWhatsApp && context.mounted) {
                                ActionToast.show(context, AppStrings.billPreparing);
                              }
                              await ref.read(ownerRepositoryProvider).generateInvoice(
                                    customerId: selected!.id,
                                    billingMonth:
                                        '${billingMonth.year.toString().padLeft(4, '0')}-${billingMonth.month.toString().padLeft(2, '0')}',
                                    send: sendWhatsApp,
                                  );
                              ref.invalidate(invoicesListProvider(
                                InvoicesQuery(billingMonth: billingMonth),
                              ));
                              if (context.mounted) {
                                Navigator.pop(context);
                                ActionToast.show(
                                  context,
                                  sendWhatsApp
                                      ? AppStrings.billingSendSuccess
                                      : AppStrings.generateBillSuccess,
                                );
                              }
                            } on ApiException catch (e) {
                              if (context.mounted) ActionToast.show(context, e.message);
                            } finally {
                              if (context.mounted) setModalState(() => loading = false);
                            }
                          },
                  ),
                ],
              ),
            );
        },
      ),
    );
    searchController.dispose();
  }

  static Future<void> showGenerateBillForCustomer(
    BuildContext context,
    WidgetRef ref, {
    required int customerId,
    required String customerName,
    DateTime? initialMonth,
  }) async {
    var billingMonth = initialMonth ?? DateTime(DateTime.now().year, DateTime.now().month);
    var sendWhatsApp = false;
    var loading = false;

    await showOwnerBottomSheet<void>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OwnerSheetTitle(AppStrings.recalculateBillTitle, subtitle: customerName),
              const SizedBox(height: AppSpace.sm),
              BorderedMonthNavigator(
                month: billingMonth,
                onPrevious: () => setModalState(
                  () => billingMonth = DateTime(billingMonth.year, billingMonth.month - 1),
                ),
                onNext: () => setModalState(
                  () => billingMonth = DateTime(billingMonth.year, billingMonth.month + 1),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.sendBillOnWhatsApp, style: AppText.body),
                value: sendWhatsApp,
                onChanged: (v) => setModalState(() => sendWhatsApp = v),
              ),
              const SizedBox(height: AppSpace.lg),
              AppButton(
                label: AppStrings.recalculateBillButton,
                loading: loading,
                onPressed: loading
                    ? null
                    : () async {
                        setModalState(() => loading = true);
                        try {
                          if (sendWhatsApp && context.mounted) {
                            ActionToast.show(context, AppStrings.billPreparing);
                          }
                          await ref.read(ownerRepositoryProvider).generateInvoice(
                                customerId: customerId,
                                billingMonth:
                                    '${billingMonth.year.toString().padLeft(4, '0')}-${billingMonth.month.toString().padLeft(2, '0')}',
                                send: sendWhatsApp,
                              );
                          ref.invalidate(invoicesListProvider(
                            InvoicesQuery(billingMonth: billingMonth),
                          ));
                          ref.invalidate(customerDetailProvider(
                            CustomerDetailQuery(
                              customerId: customerId,
                              billingMonth: billingMonth,
                            ),
                          ));
                          if (context.mounted) {
                            Navigator.pop(context);
                            ActionToast.show(
                              context,
                              sendWhatsApp
                                  ? AppStrings.billingSendSuccess
                                  : AppStrings.recalculateBillSuccess,
                            );
                          }
                        } on ApiException catch (e) {
                          if (context.mounted) ActionToast.show(context, e.message);
                        } finally {
                          if (context.mounted) setModalState(() => loading = false);
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  static Future<void> showCollectPayment(BuildContext context, WidgetRef ref) async {
    final searchController = TextEditingController();
    var customers = <OwnerCustomer>[];
    OwnerCustomer? selected;
    List<OwnerInvoice> pending = [];
    OwnerInvoice? selectedBill;
    final amountController = TextEditingController();
    var method = 'cash';
    var loading = false;

    await showOwnerBottomSheet<void>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setModalState) {
            Future<void> loadPending(OwnerCustomer customer) async {
              final month = DateTime.now();
              final detail = await ref.read(ownerRepositoryProvider).fetchCustomerDetail(
                    CustomerDetailQuery(customerId: customer.id, billingMonth: month),
                  );
              setModalState(() {
                pending = detail.billingHistory
                    .where((b) => b.balanceDue > 0)
                    .toList();
                selectedBill = pending.isNotEmpty ? pending.first : null;
                if (selectedBill != null) {
                  amountController.text = selectedBill!.balanceDue.toStringAsFixed(0);
                }
              });
            }

            Future<void> search(String q) async {
              final result = await ref.read(ownerRepositoryProvider).fetchCustomers(
                    CustomersQuery(search: q, sort: CustomerSort.nameAsc),
                  );
              setModalState(() {
                customers = result.customers.take(8).toList();
                selected = customers.isNotEmpty ? customers.first : null;
              });
              if (selected != null) await loadPending(selected!);
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const OwnerSheetHeader(
                    title: AppStrings.collectPaymentTitle,
                    icon: LucideIcons.creditCard,
                  ),
                  const SizedBox(height: AppSpace.md),
                  const OwnerSheetFieldLabel('Customer'),
                  TextField(
                    controller: searchController,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                    decoration: OwnerFormTheme.searchDecoration(hintText: AppStrings.searchCustomerLabel),
                    onSubmitted: search,
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: CustomerDetailColors.rateChipBg,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: CustomerDetailColors.rateChipBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: CustomerDetailColors.avatarBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              customerInitials(selected!.fullName),
                              style: AppText.cardTitle.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: CustomerDetailColors.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selected!.fullName,
                                  style: AppText.cardTitle.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: CustomerDetailColors.onSurface,
                                  ),
                                ),
                                if (selected!.shortAddress.isNotEmpty)
                                  Text(
                                    selected!.shortAddress,
                                    style: AppText.meta.copyWith(color: CustomerDetailColors.bodyInk),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronDown, size: 20, color: CustomerDetailColors.iconMuted),
                        ],
                      ),
                    ),
                  ] else if (customers.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.sm),
                    DropdownButtonFormField<OwnerCustomer>(
                      value: selected,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: AppStrings.selectCustomerLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                      items: customers
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.fullName)))
                          .toList(),
                      onChanged: (v) async {
                        setModalState(() => selected = v);
                        if (v != null) await loadPending(v);
                      },
                    ),
                  ],
                  if (pending.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.md),
                    const OwnerSheetFieldLabel('Pending bill'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                      decoration: BoxDecoration(
                        color: CustomerDetailColors.statBg,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: CustomerListColors.searchBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.fileText, size: 18, color: CustomerDetailColors.danger),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              selectedBill?.billingMonth ?? '',
                              style: AppText.body.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '₹${formatOwnerCurrency(selectedBill?.balanceDue ?? 0)} due',
                            style: AppText.cardTitle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: CustomerDetailColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pending.length > 1) ...[
                      const SizedBox(height: AppSpace.sm),
                      DropdownButtonFormField<OwnerInvoice>(
                        value: selectedBill,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: AppStrings.selectPendingBill),
                        items: pending
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Text('${b.billingMonth} · ₹${b.balanceDue.toStringAsFixed(0)} due'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setModalState(() {
                            selectedBill = v;
                            if (v != null) {
                              amountController.text = v.balanceDue.toStringAsFixed(0);
                            }
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpace.md),
                    const OwnerSheetFieldLabel('Amount'),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      style: AppText.screenTitle.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: AppText.screenTitle.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: CustomerDetailColors.accent,
                        ),
                        suffix: TextButton(
                          onPressed: selectedBill != null
                              ? () => setModalState(() {
                                    amountController.text =
                                        selectedBill!.balanceDue.toStringAsFixed(0);
                                  })
                              : null,
                          style: TextButton.styleFrom(
                            foregroundColor: CustomerDetailColors.accent,
                            backgroundColor: CustomerDetailColors.accentLight,
                            side: const BorderSide(color: CustomerDetailColors.accentBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: AppText.label.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                          child: const Text('Full'),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: const BorderSide(color: CustomerDetailColors.accent, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final preset in [500, 1000])
                          ActionChip(
                            label: Text('₹$preset'),
                            onPressed: () => setModalState(() {
                              amountController.text = '$preset';
                            }),
                            backgroundColor: CustomerDetailColors.statBg,
                            side: const BorderSide(color: CustomerDetailColors.border),
                            labelStyle: AppText.label.copyWith(
                              fontWeight: FontWeight.w700,
                              color: CustomerDetailColors.onSurface,
                            ),
                          ),
                        if (selectedBill != null)
                          ActionChip(
                            label: Text('₹${formatOwnerCurrency(selectedBill!.balanceDue)}'),
                            onPressed: () => setModalState(() {
                              amountController.text =
                                  selectedBill!.balanceDue.toStringAsFixed(0);
                            }),
                            backgroundColor: CustomerDetailColors.statBg,
                            side: const BorderSide(color: CustomerDetailColors.border),
                            labelStyle: AppText.label.copyWith(
                              fontWeight: FontWeight.w700,
                              color: CustomerDetailColors.onSurface,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    const OwnerSheetFieldLabel('Payment method'),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentMethodChip(
                            label: AppStrings.paymentsFilterCash,
                            icon: LucideIcons.banknote,
                            selected: method == 'cash',
                            onTap: () => setModalState(() => method = 'cash'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PaymentMethodChip(
                            label: 'UPI / QR',
                            icon: LucideIcons.qrCode,
                            selected: method == 'upi',
                            onTap: () => setModalState(() => method = 'upi'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PaymentMethodChip(
                            label: AppStrings.paymentsFilterBank,
                            icon: LucideIcons.landmark,
                            selected: method == 'bank_transfer',
                            onTap: () => setModalState(() => method = 'bank_transfer'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpace.lg),
                  AppButton(
                    label: amountController.text.isNotEmpty
                        ? 'Record ₹${amountController.text}'
                        : AppStrings.recordPaymentButton,
                    loading: loading,
                    onPressed: (selectedBill == null || loading)
                        ? null
                        : () async {
                              setModalState(() => loading = true);
                              try {
                                String? receiptWarning;
                                await ActionToast.run(
                                  context,
                                  preparing: AppStrings.paymentReceiptSending,
                                  success: AppStrings.recordPaymentSuccess,
                                  task: () async {
                                    receiptWarning = await ref.read(ownerRepositoryProvider).recordPayment(
                                          invoiceId: selectedBill!.id,
                                          amount: double.parse(amountController.text.trim()),
                                          paymentMethod: method,
                                        );
                                  },
                                );
                                ref.invalidate(paymentsListProvider);
                                if (context.mounted) {
                                  if (receiptWarning != null && receiptWarning!.isNotEmpty) {
                                    ActionToast.show(context, receiptWarning!);
                                  }
                                  Navigator.pop(context);
                                }
                              } on ApiException catch (e) {
                                if (context.mounted) ActionToast.show(context, e.message);
                              } finally {
                                if (context.mounted) setModalState(() => loading = false);
                              }
                            },
                    ),
                  ],
                ),
              );
        },
      ),
    );
    searchController.dispose();
    amountController.dispose();
  }

  static Future<void> showCollectPaymentForCustomer(
    BuildContext context,
    WidgetRef ref, {
    required int customerId,
    required String customerName,
    required List<OwnerInvoice> pendingBills,
    VoidCallback? onSuccess,
  }) async {
    if (pendingBills.isEmpty) return;

    OwnerInvoice? selectedBill = pendingBills.first;
    final amountController = TextEditingController(
      text: selectedBill.balanceDue.toStringAsFixed(0),
    );
    var method = 'cash';
    var loading = false;

    await showOwnerBottomSheet<void>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OwnerSheetTitle(AppStrings.collectPaymentTitle, subtitle: customerName),
                const SizedBox(height: AppSpace.sm),
                if (pendingBills.length > 1) ...[
                  DropdownButtonFormField<OwnerInvoice>(
                    value: selectedBill,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: AppStrings.selectPendingBill),
                    items: pendingBills
                        .map(
                          (b) => DropdownMenuItem(
                            value: b,
                            child: Text('${b.billingMonth} · ₹${b.balanceDue.toStringAsFixed(0)} due'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      setModalState(() {
                        selectedBill = v;
                        if (v != null) amountController.text = v.balanceDue.toStringAsFixed(0);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: AppStrings.paymentAmountLabel),
                ),
                const SizedBox(height: AppSpace.sm),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: InputDecoration(labelText: AppStrings.paymentMethodLabel),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text(AppStrings.paymentsFilterCash)),
                    DropdownMenuItem(value: 'upi', child: Text(AppStrings.paymentsFilterUpi)),
                    DropdownMenuItem(value: 'bank_transfer', child: Text(AppStrings.paymentsFilterBank)),
                  ],
                  onChanged: (v) => setModalState(() => method = v ?? method),
                ),
                const SizedBox(height: AppSpace.lg),
                AppButton(
                  label: AppStrings.recordPaymentButton,
                  loading: loading,
                  onPressed: (selectedBill == null || loading)
                      ? null
                      : () async {
                          setModalState(() => loading = true);
                          try {
                            String? receiptWarning;
                            await ActionToast.run(
                              context,
                              preparing: AppStrings.paymentReceiptSending,
                              success: AppStrings.recordPaymentSuccess,
                              task: () async {
                                receiptWarning = await ref
                                    .read(ownerRepositoryProvider)
                                    .recordPayment(
                                      invoiceId: selectedBill!.id,
                                      amount: double.parse(amountController.text.trim()),
                                      paymentMethod: method,
                                    );
                              },
                            );
                            ref.invalidate(paymentsListProvider);
                            ref.invalidate(customerDetailProvider(
                              CustomerDetailQuery(
                                customerId: customerId,
                                billingMonth: DateTime.now(),
                              ),
                            ));
                            if (context.mounted) {
                              if (receiptWarning != null && receiptWarning!.isNotEmpty) {
                                ActionToast.show(context, receiptWarning!);
                              }
                              Navigator.pop(context);
                              onSuccess?.call();
                            }
                          } on ApiException catch (e) {
                            if (context.mounted) ActionToast.show(context, e.message);
                          } finally {
                            if (context.mounted) setModalState(() => loading = false);
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
    amountController.dispose();
  }

  static void openAddCustomer(BuildContext context) {
    context.push('/onboarding/customer');
  }

  static Future<void> showFindCustomer(BuildContext context, WidgetRef ref) async {
    final searchController = TextEditingController();
    var customers = <OwnerCustomer>[];
    var loading = false;

    await showOwnerBottomSheet<void>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> search(String q) async {
            setModalState(() => loading = true);
            try {
              final result = await ref.read(ownerRepositoryProvider).fetchCustomers(
                    CustomersQuery(search: q, sort: CustomerSort.nameAsc),
                  );
              setModalState(() => customers = result.customers.take(20).toList());
            } finally {
              if (context.mounted) setModalState(() => loading = false);
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OwnerSheetTitle(AppStrings.dashboardFindCustomerTitle),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: AppStrings.searchCustomerLabel,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () => search(searchController.text.trim()),
                  ),
                ),
                onSubmitted: search,
              ),
              const SizedBox(height: AppSpace.sm),
              if (loading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(AppSpace.lg),
                  child: CircularProgressIndicator(),
                ))
              else if (customers.isEmpty)
                Text(
                  AppStrings.customersEmpty,
                  style: AppText.meta.copyWith(color: Theme.of(context).hintColor),
                )
              else
                ...customers.map(
                  (customer) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(customer.fullName, style: AppText.label),
                    subtitle: Text(customer.shortAddress, style: AppText.meta),
                    trailing: customer.subscriptionCount > 0
                        ? Text(
                            '${customer.subscriptionCount}',
                            style: AppText.label.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/owner/customers/${customer.id}');
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
    searchController.dispose();
  }

  static Future<void> showFarmUpiQr(BuildContext context, WidgetRef ref) async {
    final settings = await ref.read(ownerSettingsProvider.future);
    final farm = settings.farm;
    final vpa = farm.upiVpa?.trim() ?? '';

    if (vpa.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.upiNotConfigured)),
        );
      }
      return;
    }

    final payee = Uri.encodeComponent(farm.upiPayeeName ?? farm.name ?? 'Milk payment');
    final upiData = 'upi://pay?pa=$vpa&pn=$payee&cu=INR';

    final searchController = TextEditingController();
    var customers = <OwnerCustomer>[];
    OwnerCustomer? selected;
    var sharing = false;

    await showOwnerBottomSheet<void>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> search(String q) async {
            final result = await ref.read(ownerRepositoryProvider).fetchCustomers(
                  CustomersQuery(search: q, sort: CustomerSort.nameAsc),
                );
            setModalState(() {
              customers = result.customers.take(12).toList();
              selected = customers.isNotEmpty ? customers.first : null;
            });
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OwnerSheetTitle(AppStrings.dashboardViewQrTitle, subtitle: farm.name),
              const SizedBox(height: AppSpace.md),
              Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: OwnerFormTheme.borderColor),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: QrImageView(
                      data: upiData,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'UPI: $vpa',
                textAlign: TextAlign.center,
                style: AppText.meta.copyWith(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: AppStrings.selectCustomerLabel,
                  prefixIcon: const Icon(Icons.person_search_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => search(searchController.text.trim()),
                  ),
                ),
                onSubmitted: search,
              ),
              if (customers.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                DropdownButtonFormField<OwnerCustomer>(
                  value: selected,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: AppStrings.selectCustomerLabel),
                  items: customers
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.fullName)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selected = v),
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              OwnerSheetActions(
                primaryLabel: AppStrings.shareQrToCustomer,
                loading: sharing,
                onPrimary: (sharing)
                    ? null
                    : () async {
                        if (selected == null) {
                          ActionToast.show(context, AppStrings.selectCustomerForQr);
                          return;
                        }
                        setModalState(() => sharing = true);
                        try {
                          await ActionToast.run(
                            context,
                            preparing: AppStrings.qrPreparing,
                            success: AppStrings.qrSentToCustomer,
                            task: () => ref.read(ownerRepositoryProvider).shareUpiQr(
                                  customerId: selected!.id,
                                ),
                          );
                          if (context.mounted) Navigator.pop(context);
                        } on ApiException catch (e) {
                          if (context.mounted) ActionToast.show(context, e.message);
                        } finally {
                          if (context.mounted) setModalState(() => sharing = false);
                        }
                      },
                secondaryLabel: AppStrings.cancelLabel,
                onSecondary: sharing ? null : () => Navigator.pop(context),
              ),
            ],
          );
        },
      ),
    );
    searchController.dispose();
  }
}

class _PaymentMethodChip extends StatelessWidget {
  const _PaymentMethodChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? CustomerDetailColors.accent : CustomerDetailColors.statBg,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? CustomerDetailColors.accent : CustomerListColors.searchBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? Colors.white : CustomerDetailColors.labelMuted),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.cardTitle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : CustomerDetailColors.labelMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
