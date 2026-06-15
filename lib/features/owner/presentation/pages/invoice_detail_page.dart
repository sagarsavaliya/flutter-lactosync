import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/action_toast.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/owner_models.dart';
import '../providers/owner_provider.dart';
import '../widgets/customer_detail/customer_detail_styles.dart';
import '../widgets/customer_list_styles.dart';
import '../widgets/owner_action_sheets.dart';
import '../widgets/owner_design_system.dart';
import '../widgets/owner_screen_widgets.dart';

class InvoiceDetailPage extends ConsumerStatefulWidget {
  const InvoiceDetailPage({super.key, required this.invoiceId});

  final int invoiceId;

  @override
  ConsumerState<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends ConsumerState<InvoiceDetailPage> {
  bool _sending = false;

  ({Color bg, Color fg, Color border}) _statusStyle(String status) {
    return switch (status) {
      'paid' => (
          bg: CustomerDetailColors.successBg,
          fg: CustomerDetailColors.successInk,
          border: CustomerDetailColors.rateChipBorder,
        ),
      'partial' => (
          bg: CustomerDetailColors.morningChipBg,
          fg: CustomerDetailColors.morningChipInk,
          border: CustomerDetailColors.morningChipBorder,
        ),
      _ => (
          bg: CustomerDetailColors.dangerBg,
          fg: CustomerDetailColors.danger,
          border: CustomerDetailColors.dangerBorder,
        ),
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'paid' => AppStrings.billStatusPaid,
      'partial' => AppStrings.billStatusPartial,
      _ => AppStrings.billStatusPending,
    };
  }

  Future<void> _sendBill() async {
    setState(() => _sending = true);
    try {
      await ActionToast.run(
        context,
        preparing: AppStrings.billPreparing,
        success: AppStrings.billingSendSuccess,
        onError: AppStrings.billingSendFailed,
        task: () => ref.read(ownerRepositoryProvider).sendInvoice(widget.invoiceId),
      );
      if (!mounted) return;
      ref.invalidate(invoiceDetailProvider(widget.invoiceId));
      ref.invalidate(invoicesListProvider);
    } catch (e) {
      if (!mounted) return;
      final message = e is ApiException ? e.message : AppStrings.billingSendFailed;
      ActionToast.show(context, message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  String _billingPeriod(OwnerInvoice invoice) {
    if (invoice.billingMonth.isNotEmpty) {
      final parsed = DateTime.tryParse('${invoice.billingMonth}-01');
      if (parsed != null) {
        final lastDay = DateTime(parsed.year, parsed.month + 1, 0).day;
        return '1–$lastDay ${DateFormat('MMMM yyyy').format(parsed)}';
      }
    }
    return invoice.billingMonth;
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(invoiceDetailProvider(widget.invoiceId));

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      appBar: ownerDetailAppBar(title: AppStrings.billingDetailTitle),
      body: detailAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CustomerDetailColors.accent),
        ),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(invoiceDetailProvider(widget.invoiceId)),
            child: const Text('Retry'),
          ),
        ),
        data: (data) {
          final invoice = data.invoice;
          final statusStyle = _statusStyle(invoice.status);
          final pendingBills = invoice.balanceDue > 0 ? [invoice] : <OwnerInvoice>[];

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: ownerWhiteCardDecoration(radius: CustomerDetailMetrics.cardRadius),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: CustomerDetailColors.avatarBg,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  customerInitials(invoice.customerName),
                                  style: AppText.screenTitle.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: CustomerDetailColors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invoice.customerName,
                                      style: AppText.screenTitle.copyWith(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        color: CustomerDetailColors.onSurface,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      invoice.invoiceNumber,
                                      style: AppText.meta.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: CustomerDetailColors.iconMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusStyle.bg,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: statusStyle.border),
                                ),
                                child: Text(
                                  _statusLabel(invoice.status),
                                  style: AppText.meta.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: statusStyle.fg,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          Divider(color: CustomerDetailColors.divider, height: 1),
                          const SizedBox(height: 13),
                          Row(
                            children: [
                              Icon(LucideIcons.calendar, size: 15, color: CustomerDetailColors.iconMuted),
                              const SizedBox(width: 8),
                              Text(
                                'Billing period · ${_billingPeriod(invoice)}',
                                style: AppText.body.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: CustomerDetailColors.bodyInk,
                                ),
                              ),
                            ],
                          ),
                          if (invoice.dueDate != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${AppStrings.billingDueDate}: ${_formatDate(invoice.dueDate!)}',
                              style: AppText.meta.copyWith(color: CustomerDetailColors.iconMuted),
                            ),
                          ],
                          if (invoice.sentLabel != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              invoice.sentLabel!,
                              style: AppText.meta.copyWith(
                                color: CustomerDetailColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _AmountTile(
                            label: 'BILLED',
                            value: '₹${formatOwnerCurrency(invoice.totalAmount)}',
                            valueColor: CustomerDetailColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AmountTile(
                            label: 'PAID',
                            value: '₹${formatOwnerCurrency(invoice.amountPaid)}',
                            valueColor: CustomerDetailColors.successInk,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _AmountTile(
                            label: 'DUE',
                            value: '₹${formatOwnerCurrency(invoice.balanceDue)}',
                            valueColor: CustomerDetailColors.danger,
                            highlight: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'LINE ITEMS',
                      style: AppText.meta.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: CustomerDetailColors.labelMuted,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Container(
                      decoration: ownerWhiteCardDecoration(radius: CustomerDetailMetrics.sectionCardRadius),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < data.lines.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data.lines[i].productName,
                                          style: AppText.body.copyWith(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: CustomerDetailColors.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${data.lines[i].shiftLabel} · ${data.lines[i].deliveryDays} days · ${data.lines[i].totalQuantity} ltr',
                                          style: AppText.meta.copyWith(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: CustomerDetailColors.iconMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${formatOwnerCurrency(data.lines[i].lineTotal)}',
                                    style: AppText.cardTitle.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: CustomerDetailColors.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (i < data.lines.length - 1)
                              Divider(height: 1, color: CustomerDetailColors.divider),
                          ],
                          Container(
                            color: CustomerDetailColors.statBg,
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Total billed',
                                    style: AppText.cardTitle.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: CustomerDetailColors.onSurface,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${formatOwnerCurrency(invoice.totalAmount)}',
                                  style: AppText.screenTitle.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: CustomerDetailColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'PAYMENTS RECEIVED',
                      style: AppText.meta.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: CustomerDetailColors.labelMuted,
                      ),
                    ),
                    const SizedBox(height: 11),
                    if (data.payments.isEmpty)
                      Text(
                        AppStrings.billingNoPayments,
                        style: AppText.body.copyWith(color: CustomerDetailColors.labelMuted),
                      )
                    else
                      ...data.payments.map(
                        (payment) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: ownerWhiteCardDecoration(radius: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: CustomerDetailColors.successBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    LucideIcons.check,
                                    size: 19,
                                    color: CustomerDetailColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        payment.paymentMethodLabel,
                                        style: AppText.cardTitle.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: CustomerDetailColors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        payment.paymentDate,
                                        style: AppText.meta.copyWith(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: CustomerDetailColors.iconMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${formatOwnerCurrency(payment.amount)}',
                                  style: AppText.cardTitle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: CustomerDetailColors.successInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: const BoxDecoration(
                  color: CustomerDetailColors.surface,
                  border: Border(top: BorderSide(color: CustomerDetailColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 10,
                      child: _BillActionButton(
                        label: 'Send',
                        icon: LucideIcons.send,
                        background: CustomerDetailColors.accentLight,
                        foreground: CustomerDetailColors.accent,
                        border: CustomerDetailColors.accentBorder,
                        loading: _sending,
                        onTap: _sending ? null : _sendBill,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 14,
                      child: _BillActionButton(
                        label: AppStrings.recordPaymentButton,
                        icon: LucideIcons.creditCard,
                        background: CustomerDetailColors.accent,
                        foreground: Colors.white,
                        elevated: true,
                        onTap: pendingBills.isEmpty
                            ? null
                            : () => OwnerActionSheets.showCollectPaymentForCustomer(
                                  context,
                                  ref,
                                  customerId: invoice.customerId,
                                  customerName: invoice.customerName,
                                  pendingBills: pendingBills,
                                  onSuccess: () => ref.invalidate(invoiceDetailProvider(widget.invoiceId)),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Frame 11 sticky action button — Quicksand 15px, accent-light "Send" and
/// elevated green "Record payment".
class _BillActionButton extends StatelessWidget {
  const _BillActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.border,
    this.elevated = false,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? border;
  final VoidCallback? onTap;
  final bool elevated;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
            )
          else ...[
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppText.cardTitle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ],
      ),
    );

    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: CustomerDetailColors.accent.withValues(alpha: 0.6),
                    blurRadius: 22,
                    spreadRadius: -10,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: border != null ? Border.all(color: border!) : null,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.label,
    required this.value,
    required this.valueColor,
    this.highlight = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: highlight ? CustomerDetailColors.dangerBg : CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? CustomerDetailColors.dangerBorder : CustomerDetailColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.meta.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: highlight ? CustomerDetailColors.dangerMuted : CustomerDetailColors.labelMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppText.cardTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
