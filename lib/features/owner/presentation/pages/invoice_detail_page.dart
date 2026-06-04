import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/action_toast.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/owner_provider.dart';
import '../widgets/owner_design_system.dart';
import '../widgets/owner_form_theme.dart';
import '../widgets/owner_shared_widgets.dart';
import '../widgets/owner_widgets.dart';

class InvoiceDetailPage extends ConsumerStatefulWidget {
  const InvoiceDetailPage({super.key, required this.invoiceId});

  final int invoiceId;

  @override
  ConsumerState<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends ConsumerState<InvoiceDetailPage> {
  bool _sending = false;

  String _statusLabel(String status) {
    return switch (status) {
      'paid' => AppStrings.billStatusPaid,
      'partial' => AppStrings.billStatusPartial,
      _ => AppStrings.billStatusPending,
    };
  }

  Color _statusColor(String status, BuildContext context) {
    return switch (status) {
      'paid' => AppColors.success,
      'partial' => Theme.of(context).colorScheme.primary,
      _ => AppColors.danger,
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

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(invoiceDetailProvider(widget.invoiceId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final borderColor = OwnerFormTheme.borderColor;

    return Scaffold(
      backgroundColor: OwnerTheme.background,
      appBar: ownerDetailAppBar(title: AppStrings.billingDetailTitle),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(invoiceDetailProvider(widget.invoiceId)),
            child: const Text('Retry'),
          ),
        ),
        data: (data) {
          final invoice = data.invoice;
          final statusColor = _statusColor(invoice.status, context);

          return ListView(
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(invoice.customerName, style: AppText.screenTitle.copyWith(fontSize: 20)),
                          Text(invoice.invoiceNumber, style: AppText.meta.copyWith(color: inkMuted)),
                          if (invoice.sentLabel != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              invoice.sentLabel!,
                              style: AppText.meta.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (invoice.dueDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${AppStrings.billingDueDate}: ${_formatDate(invoice.dueDate!)}',
                              style: AppText.meta.copyWith(color: inkMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _statusLabel(invoice.status),
                          style: AppText.label.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpace.sm),
                        OwnerOutlineButton(
                          label: AppStrings.billingSendBillShort,
                          onPressed: _sending ? null : _sendBill,
                          enabled: !_sending,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
              BillAmountHero(
                billAmount: invoice.totalAmount,
                paidAmount: invoice.amountPaid,
                pendingAmount: invoice.balanceDue,
                status: invoice.status,
              ),
              const SizedBox(height: AppSpace.lg),
              Text(AppStrings.billingLineItems, style: AppText.cardTitle),
              const SizedBox(height: AppSpace.sm),
              ...data.lines.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(line.productName, style: AppText.label),
                                Text(
                                  '${line.shiftLabel} · ${line.deliveryDays} days · ${line.totalQuantity} ltr',
                                  style: AppText.meta.copyWith(color: inkMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${line.lineTotal.toStringAsFixed(0)}',
                            style: AppText.label.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(AppStrings.billingPayments, style: AppText.cardTitle),
              const SizedBox(height: AppSpace.sm),
              if (data.payments.isEmpty)
                Text(AppStrings.billingNoPayments, style: AppText.body.copyWith(color: inkMuted))
              else
                ...data.payments.map((payment) => PaymentListTile(payment: payment)),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
