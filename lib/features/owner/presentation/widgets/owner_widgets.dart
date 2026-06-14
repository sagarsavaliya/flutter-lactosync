import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/owner_models.dart';
import 'owner_form_theme.dart';
import 'owner_shared_widgets.dart';

class KpiStatCard extends StatelessWidget {
  const KpiStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;

    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.meta.copyWith(color: accent)),
                Text(value, style: AppText.cardTitle),
                if (subtitle != null)
                  Text(subtitle!, style: AppText.meta.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderListTile extends StatelessWidget {
  const OrderListTile({
    super.key,
    required this.customerName,
    required this.productName,
    required this.shiftLabel,
    required this.quantity,
    required this.isSkipped,
    required this.onQtyChanged,
    required this.onSkip,
  });

  final String customerName;
  final String productName;
  final String shiftLabel;
  final double quantity;
  final bool isSkipped;
  final ValueChanged<double> onQtyChanged;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final borderColor = OwnerFormTheme.borderColor;
    final dropdownValue = isSkipped ? kMilkQtyOptions.first : nearestMilkQty(quantity);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      customerName,
                      style: AppText.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$productName · $shiftLabel',
                      style: AppText.meta.copyWith(color: inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              if (isSkipped)
                Text(AppStrings.ordersSkipped, style: AppText.meta.copyWith(color: inkMuted))
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 76,
                      height: kOwnerCompactActionHeight,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                          color: Colors.white,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            value: dropdownValue,
                            isExpanded: true,
                            isDense: true,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                            items: kMilkQtyOptions
                                .map(
                                  (q) => DropdownMenuItem(
                                    value: q,
                                    child: Text(milkQtyLabel(q), style: AppText.meta),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) onQtyChanged(v);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    OwnerOutlineButton(
                      label: AppStrings.ordersSkip,
                      onPressed: onSkip,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class InvoiceListTile extends StatelessWidget {
  const InvoiceListTile({
    super.key,
    required this.invoice,
    this.onTap,
  });

  final OwnerInvoice invoice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final color = switch (invoice.status) {
      'paid' => AppColors.success,
      'partial' => Theme.of(context).colorScheme.primary,
      _ => AppColors.danger,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: Material(
        color: color.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            padding: const EdgeInsets.all(AppSpace.md),
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
                            invoice.customerName,
                            style: AppText.cardTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            invoice.invoiceNumber,
                            style: AppText.meta.copyWith(color: inkMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      invoice.statusLabel,
                      style: AppText.label.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                ThreeColumnAmountGrid(
                  columns: [
                    AmountGridColumn(
                      label: AppStrings.billingTotalBilled,
                      value: invoice.totalAmount,
                      valueColor: Theme.of(context).colorScheme.primary,
                    ),
                    AmountGridColumn(
                      label: AppStrings.billingCollected,
                      value: invoice.amountPaid,
                      valueColor: AppColors.success,
                    ),
                    AmountGridColumn(
                      label: AppStrings.billingOutstanding,
                      value: invoice.balanceDue,
                      valueColor: AppColors.danger,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentListTile extends StatelessWidget {
  const PaymentListTile({super.key, required this.payment, this.compact = false});

  final OwnerPayment payment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final borderColor = OwnerFormTheme.borderColor;
    final isCash = payment.paymentMethod == 'cash';
    final methodLine = isCash && payment.handedTo != null && payment.handedTo!.isNotEmpty
        ? '${payment.paymentMethodLabel} · ${payment.handedTo}'
        : payment.paymentMethodLabel;
    final padding = compact ? AppSpace.sm : AppSpace.md;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
          color: AppColors.success.withValues(alpha: isDark ? 0.08 : 0.04),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(payment.customerName, style: AppText.cardTitle)),
                  Text(payment.paymentDate, style: AppText.meta.copyWith(color: inkMuted)),
                ],
              ),
              const SizedBox(height: AppSpace.xxs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      payment.invoiceNumber ?? '—',
                      style: AppText.meta.copyWith(color: inkMuted),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${payment.amount.toStringAsFixed(0)}',
                        style: AppText.cardTitle.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(methodLine, style: AppText.meta.copyWith(color: inkMuted)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
