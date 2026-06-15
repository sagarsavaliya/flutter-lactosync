import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/owner_models.dart';
import 'customer_detail/customer_detail_styles.dart';
import 'customer_list_styles.dart';
import 'owner_screen_widgets.dart';

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
    final accent = color ?? CustomerDetailColors.accent;

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
    this.onUndo,
    this.dotColor,
  });

  final String customerName;
  final String productName;
  final String shiftLabel;
  final double quantity;
  final bool isSkipped;
  final ValueChanged<double> onQtyChanged;
  final VoidCallback onSkip;
  final VoidCallback? onUndo;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final dot = dotColor ?? milkTypeDotColor(productName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: ownerWhiteCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: AppText.cardTitle.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: CustomerDetailColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$productName · $shiftLabel',
                    style: AppText.meta.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: CustomerDetailColors.labelMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSkipped) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: CustomerListColors.inactiveBadgeBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  AppStrings.ordersSkipped,
                  style: AppText.meta.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: CustomerListColors.inactiveOrange,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              OwnerIconActionButton(
                icon: LucideIcons.rotateCcw,
                onTap: onUndo,
                background: CustomerDetailColors.surface,
                border: CustomerListColors.searchBorder,
                iconColor: CustomerDetailColors.accent,
              ),
            ] else ...[
              OwnerQtyStepper(quantity: quantity, onChanged: onQtyChanged),
              const SizedBox(width: 7),
              OwnerIconActionButton(
                icon: LucideIcons.skipForward,
                onTap: onSkip,
                iconColor: CustomerDetailColors.labelMuted,
              ),
            ],
          ],
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
    this.onSend,
    this.sending = false,
  });

  final OwnerInvoice invoice;
  final VoidCallback? onTap;
  final VoidCallback? onSend;
  final bool sending;

  ({Color bar, Color badgeBg, Color badgeFg, Color badgeBorder, Color outColor}) _colors() {
    return switch (invoice.status) {
      'paid' => (
          bar: CustomerDetailColors.success,
          badgeBg: CustomerDetailColors.successBg,
          badgeFg: CustomerDetailColors.successInk,
          badgeBorder: CustomerDetailColors.rateChipBorder,
          outColor: CustomerDetailColors.successInk,
        ),
      'partial' => (
          bar: CustomerListColors.inactiveDot,
          badgeBg: CustomerDetailColors.morningChipBg,
          badgeFg: CustomerDetailColors.morningChipInk,
          badgeBorder: CustomerDetailColors.morningChipBorder,
          outColor: CustomerDetailColors.danger,
        ),
      _ => (
          bar: CustomerDetailColors.accentBorder,
          badgeBg: CustomerDetailColors.accentLight,
          badgeFg: CustomerDetailColors.accent,
          badgeBorder: CustomerDetailColors.accentBorder,
          outColor: CustomerDetailColors.danger,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors();
    final outLabel = invoice.balanceDue <= 0
        ? 'Settled'
        : '₹${formatOwnerCurrency(invoice.balanceDue)} due';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: CustomerDetailColors.border),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF283C28).withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: -10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: colors.bar),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  invoice.customerName,
                                  style: AppText.cardTitle.copyWith(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: CustomerDetailColors.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '₹${formatOwnerCurrency(invoice.totalAmount)}',
                                style: AppText.cardTitle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: CustomerDetailColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colors.badgeBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        invoice.statusLabel,
                                        style: AppText.meta.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: colors.badgeFg,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Flexible(
                                      child: Text(
                                        invoice.invoiceNumber,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.meta.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: CustomerDetailColors.iconMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                outLabel,
                                style: AppText.body.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: colors.outColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: CustomerDetailColors.accentLight,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  onTap: sending ? null : onSend,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: CustomerDetailColors.accentBorder),
                                    ),
                                    alignment: Alignment.center,
                                    child: sending
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(
                                            LucideIcons.send,
                                            size: 14,
                                            color: CustomerDetailColors.accent,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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

  ({Color bg, Color fg}) _methodColors() {
    return switch (payment.paymentMethod) {
      'cash' => (bg: CustomerDetailColors.successBg, fg: CustomerDetailColors.successInk),
      'upi' => (bg: CustomerDetailColors.accentLight, fg: CustomerDetailColors.accent),
      'bank_transfer' => (bg: CustomerDetailColors.morningChipBg, fg: CustomerDetailColors.morningChipInk),
      _ => (bg: CustomerDetailColors.statBg, fg: CustomerDetailColors.bodyInk),
    };
  }

  @override
  Widget build(BuildContext context) {
    final methodColors = _methodColors();
    final initials = customerInitials(payment.customerName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Container(
        padding: EdgeInsets.all(compact ? 11 : 13),
        decoration: ownerWhiteCardDecoration(),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CustomerDetailColors.avatarBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                initials,
                style: AppText.cardTitle.copyWith(
                  fontSize: 14,
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
                    payment.customerName,
                    style: AppText.cardTitle.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: CustomerDetailColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          payment.invoiceNumber ?? '—',
                          style: AppText.meta.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: CustomerDetailColors.iconMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: const BoxDecoration(
                          color: CustomerListColors.indexInk,
                          shape: BoxShape.circle,
                        ),
                      ),
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
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${formatOwnerCurrency(payment.amount)}',
                  style: AppText.cardTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.successInk,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: methodColors.bg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    payment.paymentMethodLabel,
                    style: AppText.meta.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: methodColors.fg,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}