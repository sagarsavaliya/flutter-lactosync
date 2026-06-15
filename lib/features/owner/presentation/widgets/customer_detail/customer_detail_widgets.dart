import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../domain/entities/owner_models.dart';
import 'customer_detail_styles.dart';

class CustomerDetailHeader extends StatelessWidget {
  const CustomerDetailHeader({
    super.key,
    required this.onBack,
    this.onDelete,
    this.onEdit,
  });

  final VoidCallback onBack;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 14),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            color: CustomerDetailColors.accent,
          ),
          Expanded(
            child: Text(
              AppStrings.customerDetailTitle,
              style: AppText.screenTitle.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: CustomerDetailColors.accent,
              ),
            ),
          ),
          if (onDelete != null)
            _HeaderIconButton(
              icon: Icons.delete_outline_rounded,
              bg: CustomerDetailColors.deleteBg,
              border: CustomerDetailColors.deleteBorder,
              iconColor: CustomerDetailColors.danger,
              onTap: onDelete!,
            ),
          if (onDelete != null && onEdit != null) const SizedBox(width: 9),
          if (onEdit != null)
            _HeaderIconButton(
              icon: Icons.edit_outlined,
              bg: CustomerDetailColors.accentLight,
              border: CustomerDetailColors.accentBorder,
              iconColor: CustomerDetailColors.accent,
              onTap: onEdit!,
            ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.bg,
    required this.border,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color bg;
  final Color border;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}

class CustomerDetailHeroCard extends StatelessWidget {
  const CustomerDetailHeroCard({
    super.key,
    required this.customer,
    required this.monthTotal,
    required this.pendingTotal,
    required this.subscriptionCount,
  });

  final CustomerDetailInfo customer;
  final double monthTotal;
  final double pendingTotal;
  final int subscriptionCount;

  Future<void> _callCustomer() async {
    final digits = customer.contact.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final uri = Uri.parse('tel:$digits');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(customer.fullName);
    final status = customer.displayStatus;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.cardRadius),
        border: Border.all(color: CustomerDetailColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283C28).withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CustomerDetailColors.avatarBg,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Text(
                  initials,
                  style: AppText.screenTitle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.screenTitle.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: CustomerDetailColors.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusPill(status: status),
                  ],
                ),
              ),
              Material(
                color: CustomerDetailColors.accent,
                borderRadius: BorderRadius.circular(15),
                elevation: 4,
                shadowColor: CustomerDetailColors.accent.withValues(alpha: 0.5),
                child: InkWell(
                  onTap: _callCustomer,
                  borderRadius: BorderRadius.circular(15),
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(Icons.phone_outlined, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: CustomerDetailColors.divider),
          const SizedBox(height: 13),
          _ContactRow(icon: Icons.phone_outlined, text: customer.contact),
          const SizedBox(height: 9),
          _ContactRow(
            icon: Icons.location_on_outlined,
            text: customer.fullAddress,
            alignTop: true,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'THIS MONTH',
                  value: '₹${_formatAmount(monthTotal)}',
                  valueColor: CustomerDetailColors.onSurface,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _StatBox(
                  label: 'PENDING',
                  value: '₹${_formatAmount(pendingTotal)}',
                  bg: CustomerDetailColors.dangerBg,
                  border: CustomerDetailColors.dangerBorder,
                  labelColor: CustomerDetailColors.dangerMuted,
                  valueColor: CustomerDetailColors.danger,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _StatBox(
                  label: 'SUBS',
                  value: '$subscriptionCount',
                  valueColor: CustomerDetailColors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    final w = parts.first;
    return w.length >= 2 ? w.substring(0, 2).toUpperCase() : w[0].toUpperCase();
  }

  static String _formatAmount(double value) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    return fmt.format(value.round());
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final CustomerDisplayStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, dot, bg, ink) = switch (status) {
      CustomerDisplayStatus.inactive => (
          AppStrings.kpiInactive,
          CustomerDetailColors.danger,
          CustomerDetailColors.dangerBg,
          CustomerDetailColors.danger,
        ),
      CustomerDisplayStatus.vacation => (
          AppStrings.onVacationLabel,
          const Color(0xFF4A66A6),
          const Color(0xFFE4ECF7),
          const Color(0xFF3D5896),
        ),
      _ => (
          AppStrings.kpiActive,
          CustomerDetailColors.success,
          CustomerDetailColors.successBg,
          CustomerDetailColors.successInk,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.meta.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
    this.alignTop = false,
  });

  final IconData icon;
  final String text;
  final bool alignTop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(top: alignTop ? 1 : 0),
          child: Icon(icon, size: 15, color: CustomerDetailColors.iconMuted),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: AppText.body.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: CustomerDetailColors.bodyInk,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    this.bg = CustomerDetailColors.statBg,
    this.border = CustomerDetailColors.border,
    this.labelColor = CustomerDetailColors.onSurfaceVariant,
    this.valueColor = CustomerDetailColors.onSurface,
  });

  final String label;
  final String value;
  final Color bg;
  final Color border;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.meta.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppText.cardTitle.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerDetailMonthNav extends StatelessWidget {
  const CustomerDetailMonthNav({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy').format(month);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: CustomerDetailColors.border),
      ),
      child: Row(
        children: [
          _MonthArrow(icon: Icons.arrow_back_ios_new_rounded, onTap: onPrevious),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.cardTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CustomerDetailColors.onSurface,
              ),
            ),
          ),
          _MonthArrow(icon: Icons.arrow_forward_ios_rounded, onTap: onNext),
        ],
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomerDetailColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 16, color: CustomerDetailColors.accent),
        ),
      ),
    );
  }
}

class CustomerDetailVacationCard extends StatelessWidget {
  const CustomerDetailVacationCard({
    super.key,
    required this.isOnVacation,
    required this.onPauseTap,
  });

  final bool isOnVacation;
  final VoidCallback onPauseTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
        border: Border.all(color: CustomerDetailColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283C28).withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CustomerDetailColors.successBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isOnVacation ? Icons.flight_takeoff_rounded : Icons.local_shipping_outlined,
              color: CustomerDetailColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnVacation ? AppStrings.onVacationLabel : 'Deliveries active',
                  style: AppText.cardTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pause when away — billing stops automatically.',
                  style: AppText.meta.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: isOnVacation ? CustomerDetailColors.accent : CustomerDetailColors.background,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onPauseTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: isOnVacation
                      ? null
                      : Border.all(color: const Color(0xFFE4E8DD)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnVacation ? Icons.login_rounded : Icons.logout_rounded,
                      size: 18,
                      color: isOnVacation ? Colors.white : const Color(0xFF6E8A72),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      isOnVacation ? 'Resume' : 'Pause',
                      style: AppText.meta.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isOnVacation ? Colors.white : const Color(0xFF5C6B5E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerDetailSectionLabel extends StatelessWidget {
  const CustomerDetailSectionLabel({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 11),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppText.meta.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: CustomerDetailColors.onSurfaceVariant,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class CustomerDetailAddChip extends StatelessWidget {
  const CustomerDetailAddChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomerDetailColors.accentLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CustomerDetailColors.accentBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 14, color: CustomerDetailColors.accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.meta.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: CustomerDetailColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerDetailDuesCard extends StatelessWidget {
  const CustomerDetailDuesCard({
    super.key,
    required this.pending,
    required this.paid,
    required this.onRecordPayment,
    this.onRemind,
  });

  final double pending;
  final double paid;
  final VoidCallback? onRecordPayment;
  final VoidCallback? onRemind;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final settled = pending <= 0;
    // Green (settled) vs salmon (dues outstanding) — when previous months are
    // unpaid, `pending` carries the cumulative balance and the card stays salmon.
    final gradientColors = settled
        ? const [
            CustomerDetailColors.duesGreenStart,
            CustomerDetailColors.duesGreenEnd,
          ]
        : const [
            CustomerDetailColors.duesGradientStart,
            CustomerDetailColors.duesGradientEnd,
          ];
    final shadowColor = settled
        ? CustomerDetailColors.accent.withValues(alpha: 0.45)
        : CustomerDetailColors.danger.withValues(alpha: 0.45);
    final actionInk =
        settled ? CustomerDetailColors.accent : CustomerDetailColors.danger;
    const labelTint = Color(0xFFF7DBCD);
    const greenLabelTint = Color(0xFFCDEBD5);
    final labelColor = settled ? greenLabelTint : labelTint;
    const valueColor = Color(0xFFFCEFE8);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settled ? 'No pending dues' : 'Pending balance',
                      style: AppText.meta.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                    Text(
                      '₹${fmt.format(pending.round())}',
                      style: AppText.screenTitle.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: valueColor,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Paid',
                    style: AppText.meta.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                  Text(
                    '₹${fmt.format(paid.round())}',
                    style: AppText.cardTitle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    onTap: onRecordPayment,
                    borderRadius: BorderRadius.circular(13),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.credit_card_outlined,
                              size: 17, color: actionInk),
                          const SizedBox(width: 7),
                          Text(
                            AppStrings.recordPaymentButton,
                            style: AppText.cardTitle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: actionInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  onTap: onRemind,
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.send_outlined, size: 17, color: Colors.white),
                        const SizedBox(width: 7),
                        Text(
                          'Remind',
                          style: AppText.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CustomerDetailBillingSummaryChip extends StatelessWidget {
  const CustomerDetailBillingSummaryChip({
    super.key,
    required this.label,
    required this.isPaid,
  });

  final String label;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isPaid ? CustomerDetailColors.successBg : CustomerDetailColors.dangerBg,
        border: Border.all(
          color: isPaid ? const Color(0xFFCFE6D4) : CustomerDetailColors.dangerBorder,
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isPaid ? CustomerDetailColors.success : CustomerDetailColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.meta.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: isPaid ? CustomerDetailColors.successInk : CustomerDetailColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerDetailBillingHistorySection extends StatelessWidget {
  const CustomerDetailBillingHistorySection({
    super.key,
    required this.totalPaidLabel,
    required this.totalPendingLabel,
    required this.bills,
    required this.visibleBills,
    required this.showAllBills,
    required this.onGenerateBill,
    required this.onBillTap,
    this.onToggleShowAll,
    this.emptyMessage,
  });

  final String totalPaidLabel;
  final String totalPendingLabel;
  final List<OwnerInvoice> bills;
  final List<OwnerInvoice> visibleBills;
  final bool showAllBills;
  final VoidCallback onGenerateBill;
  final ValueChanged<OwnerInvoice> onBillTap;
  final VoidCallback? onToggleShowAll;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.billingHistoryTitle,
                  style: AppText.cardTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.onSurface,
                  ),
                ),
              ),
              CustomerDetailIconAction(
                icon: Icons.receipt_long_outlined,
                onTap: onGenerateBill,
              ),
            ],
          ),
        ),
        if (bills.isNotEmpty) ...[
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              CustomerDetailBillingSummaryChip(
                label: totalPaidLabel,
                isPaid: true,
              ),
              CustomerDetailBillingSummaryChip(
                label: totalPendingLabel,
                isPaid: false,
              ),
            ],
          ),
          const SizedBox(height: 11),
        ],
        if (bills.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              emptyMessage ?? AppStrings.noBillsGenerated,
              style: AppText.body.copyWith(
                color: CustomerDetailColors.onSurfaceVariant,
              ),
            ),
          )
        else ...[
          for (final invoice in visibleBills)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: CustomerDetailBillingRow(invoice: invoice, onTap: () => onBillTap(invoice)),
            ),
          if (bills.length > 3 && onToggleShowAll != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onToggleShowAll,
                child: Text(
                  showAllBills ? AppStrings.showLessBills : AppStrings.showMoreBills,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

String billingInvoiceSubtitle(String status) {
  return status == 'paid' ? 'Invoice · settled' : 'Invoice · unpaid';
}

String billingChipStatusLabel(String status) {
  return switch (status) {
    'paid' => AppStrings.billStatusPaid,
    'partial' => AppStrings.billStatusPartial,
    _ => AppStrings.billStatusPending,
  };
}

double billingChipAmount(OwnerInvoice invoice) {
  if (invoice.status == 'paid') return invoice.totalAmount;
  return invoice.balanceDue > 0 ? invoice.balanceDue : invoice.totalAmount;
}

class CustomerDetailBillingRow extends StatelessWidget {
  const CustomerDetailBillingRow({
    super.key,
    required this.invoice,
    required this.onTap,
    this.monthLabel,
  });

  final OwnerInvoice invoice;
  final VoidCallback onTap;
  final String? monthLabel;

  String get _monthLabel {
    if (monthLabel != null) return monthLabel!;
    final parsed = DateTime.tryParse('${invoice.billingMonth}-01');
    if (parsed == null) return invoice.billingMonth;
    return DateFormat('MMMM yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final isSettled = invoice.status == 'paid';
    final accent = isSettled ? CustomerDetailColors.success : CustomerDetailColors.danger;
    final chipBg = isSettled ? CustomerDetailColors.successBg : CustomerDetailColors.dangerBg;
    final chipInk = isSettled ? CustomerDetailColors.successInk : CustomerDetailColors.danger;
    final cardBorder = isSettled ? const Color(0xFFD9E7DC) : CustomerDetailColors.dangerBorder;
    final fmt = NumberFormat('#,##0', 'en_IN');
    final amount = fmt.format(billingChipAmount(invoice).round());
    final chipLabel = billingChipStatusLabel(invoice.status);

    return Container(
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283C28).withValues(alpha: 0.18),
            blurRadius: 14,
            spreadRadius: -10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Material(
          color: CustomerDetailColors.surface,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 13, 12, 13),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _monthLabel,
                                  style: AppText.body.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: CustomerDetailColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  billingInvoiceSubtitle(invoice.status),
                                  style: AppText.meta.copyWith(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: CustomerDetailColors.labelMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '$chipLabel ₹$amount',
                              style: AppText.meta.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: chipInk,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: CustomerDetailColors.labelMuted.withValues(alpha: 0.85),
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

class CustomerDetailPaymentRow extends StatelessWidget {
  const CustomerDetailPaymentRow({
    super.key,
    required this.invoiceRef,
    required this.dateLabel,
    required this.method,
    required this.amount,
  });

  final String invoiceRef;
  final String dateLabel;
  final String method;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CustomerDetailColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283C28).withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: CustomerDetailColors.successBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.check_rounded, color: CustomerDetailColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoiceRef,
                  style: AppText.cardTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      dateLabel,
                      style: AppText.meta.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: CustomerDetailColors.labelMuted,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: CustomerDetailColors.statBg,
                        border: Border.all(color: const Color(0xFFE4E8DD)),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        method,
                        style: AppText.meta.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF5C6B5E),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₹$amount',
            style: AppText.cardTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CustomerDetailColors.successInk,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomerDetailIconAction extends StatelessWidget {
  const CustomerDetailIconAction({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomerDetailColors.accentLight,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: CustomerDetailColors.accentBorder),
          ),
          child: Icon(icon, size: 16, color: CustomerDetailColors.accent),
        ),
      ),
    );
  }
}

/// Subscription card with expandable calendar heatmap.
class CustomerDetailSubscriptionCard extends StatefulWidget {
  const CustomerDetailSubscriptionCard({
    super.key,
    required this.index,
    required this.line,
    required this.month,
    this.onEdit,
    this.onDelete,
    this.onLongPressCalendar,
    this.initiallyExpanded = false,
    this.showCalendar = true,
  });

  final int index;
  final SubscriptionLineDetail line;
  final DateTime month;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPressCalendar;
  final bool initiallyExpanded;
  final bool showCalendar;

  @override
  State<CustomerDetailSubscriptionCard> createState() =>
      _CustomerDetailSubscriptionCardState();
}

class _CustomerDetailSubscriptionCardState extends State<CustomerDetailSubscriptionCard> {
  late bool _expanded = widget.initiallyExpanded;

  Color get _productDot {
    final name = widget.line.productName.toLowerCase();
    if (name.contains('buffalo')) return CustomerDetailColors.buffaloDot;
    return CustomerDetailColors.cowDot;
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;
    final isMorning = line.shift != 'evening';

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
        border: Border.all(color: CustomerDetailColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283C28).withValues(alpha: _expanded ? 0.14 : 0.1),
            blurRadius: _expanded ? 18 : 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                      style: AppText.meta.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: CustomerDetailColors.iconMuted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: _productDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            line.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.cardTitle.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: CustomerDetailColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ShiftChip(label: line.shiftLabel, isMorning: isMorning),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onDelete != null)
                    _SubActionButton(
                      icon: Icons.delete_outline_rounded,
                      iconColor: CustomerDetailColors.onSurfaceVariant,
                      onTap: widget.onDelete!,
                    ),
                  if (widget.onDelete != null && widget.onEdit != null)
                    const SizedBox(width: 7),
                  if (widget.onEdit != null)
                    _SubActionButton(
                      icon: Icons.edit_outlined,
                      iconColor: CustomerDetailColors.accent,
                      onTap: widget.onEdit!,
                    ),
                  if (widget.showCalendar) ...[
                    const SizedBox(width: 7),
                    _SubActionButton(
                      icon: _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      iconColor: CustomerDetailColors.accent,
                      bg: CustomerDetailColors.accentLight,
                      onTap: () => setState(() => _expanded = !_expanded),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (_expanded && widget.showCalendar) ...[
            const SizedBox(height: 15),
            const Divider(height: 1, color: CustomerDetailColors.divider),
            const SizedBox(height: 14),
            _DeliveryCalendarHeatmap(
              line: line,
              month: widget.month,
              onLongPress: widget.onLongPressCalendar,
            ),
          ],
        ],
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  const _ShiftChip({required this.label, required this.isMorning});

  final String label;
  final bool isMorning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CustomerDetailColors.morningChipBg,
        border: Border.all(color: CustomerDetailColors.morningChipBorder),
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMorning ? Icons.wb_sunny_outlined : Icons.nightlight_round,
            size: 13,
            color: const Color(0xFFE89A2E),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.meta.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CustomerDetailColors.morningChipInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubActionButton extends StatelessWidget {
  const _SubActionButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.bg = CustomerDetailColors.background,
  });

  final IconData icon;
  final Color iconColor;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}

class _DeliveryCalendarHeatmap extends StatelessWidget {
  const _DeliveryCalendarHeatmap({
    required this.line,
    required this.month,
    this.onLongPress,
  });

  final SubscriptionLineDetail line;
  final DateTime month;
  final VoidCallback? onLongPress;

  static const _dow = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  double? _qtyForDay(SubscriptionDayOrder day) {
    return line.shift == 'evening' ? day.evening : day.morning;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final firstWeekday = DateTime(month.year, month.month, 1).weekday; // Mon=1
    final leading = firstWeekday - 1;

    final ordersByDay = <int, SubscriptionDayOrder>{};
    for (final order in line.dailyOrders) {
      final parsed = DateTime.tryParse(order.date);
      if (parsed == null) continue;
      if (parsed.year == month.year && parsed.month == month.month) {
        ordersByDay[parsed.day] = order;
      }
    }

    var monthTotal = 0.0;
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      if (date.isAfter(today)) continue;
      final order = ordersByDay[d];
      if (order == null || !order.hasDelivery) continue;
      final q = _qtyForDay(order);
      if (q != null && q > 0) monthTotal += q;
    }

    final cells = <Widget>[
      for (final w in _dow)
        Text(
          w,
          textAlign: TextAlign.center,
          style: AppText.meta.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: CustomerDetailColors.labelMuted,
          ),
        ),
      for (var i = 0; i < leading; i++) const SizedBox(height: 42),
      for (var d = 1; d <= daysInMonth; d++)
        _CalendarDayCell(
          day: d,
          month: month,
          order: ordersByDay[d],
          shift: line.shift,
          today: today,
        ),
    ];

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.heavyImpact();
        onLongPress?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DELIVERY CALENDAR · ${line.shiftLabel.toUpperCase()}',
                  style: AppText.meta.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: CustomerDetailColors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '${monthTotal.toStringAsFixed(1)} L',
                style: AppText.cardTitle.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: CustomerDetailColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            childAspectRatio: 1,
            children: cells,
          ),
          const SizedBox(height: 13),
          const _CalendarLegend(),
        ],
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.month,
    required this.order,
    required this.shift,
    required this.today,
  });

  final int day;
  final DateTime month;
  final SubscriptionDayOrder? order;
  final String shift;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final date = DateTime(month.year, month.month, day);
    final isFuture = date.isAfter(today);
    final qty = order == null
        ? null
        : (shift == 'evening' ? order!.evening : order!.morning);
    final skipped = !isFuture && (order == null || !order!.hasDelivery || qty == null || qty <= 0);

    late Color bg;
    late BoxBorder border;
    late String qtyLabel;
    late Color qtyColor;
    late Color numColor;

    if (isFuture) {
      bg = CustomerDetailColors.surface;
      border = Border.all(color: CustomerDetailColors.calFutureBorder, style: BorderStyle.solid);
      qtyLabel = '·';
      qtyColor = const Color(0xFFCFD6C8);
      numColor = const Color(0xFFC5CCBE);
    } else if (skipped) {
      bg = CustomerDetailColors.calSkippedBg;
      border = Border.all(color: CustomerDetailColors.calSkippedBorder);
      qtyLabel = '–';
      qtyColor = const Color(0xFFC2CABB);
      numColor = const Color(0xFFBBC2B4);
    } else if (qty! >= 1) {
      bg = CustomerDetailColors.accent;
      border = Border.all(color: CustomerDetailColors.accent);
      qtyLabel = qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toString();
      qtyColor = Colors.white;
      numColor = const Color(0xFF9FCBAC);
    } else {
      bg = CustomerDetailColors.calHalfBg;
      border = Border.all(color: CustomerDetailColors.calHalfBorder);
      qtyLabel = '½';
      qtyColor = CustomerDetailColors.calHalfInk;
      numColor = const Color(0xFF6E9579);
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(11),
        border: border,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 3,
            left: 5,
            child: Text(
              '$day',
              style: AppText.meta.copyWith(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: numColor,
                height: 1,
              ),
            ),
          ),
          Text(
            qtyLabel,
            style: AppText.cardTitle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: qtyColor,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: const [
        _LegendItem(color: CustomerDetailColors.calHalfBg, border: CustomerDetailColors.calHalfBorder, label: '0.5 L'),
        _LegendItem(color: CustomerDetailColors.accent, label: '1 L', filled: true),
        _LegendItem(color: CustomerDetailColors.calSkippedBg, border: CustomerDetailColors.calSkippedBorder, label: 'Skipped'),
        _LegendItem(color: CustomerDetailColors.surface, border: CustomerDetailColors.calFutureBorder, label: 'Scheduled', dashed: true),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    this.border,
    this.filled = false,
    this.dashed = false,
  });

  final Color color;
  final Color? border;
  final String label;
  final bool filled;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            border: dashed
                ? Border.all(color: border ?? CustomerDetailColors.calFutureBorder, style: BorderStyle.solid)
                : filled
                    ? null
                    : Border.all(color: border ?? color),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.meta.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF7E8A7B),
          ),
        ),
      ],
    );
  }
}

class CustomerDetailConsumptionCard extends StatelessWidget {
  const CustomerDetailConsumptionCard({
    super.key,
    required this.rows,
    required this.grandTotal,
  });

  final List<ConsumptionRow> rows;
  final double grandTotal;

  Color _dotFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('buffalo')) return CustomerDetailColors.buffaloDot;
    return CustomerDetailColors.cowDot;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
        border: Border.all(color: CustomerDetailColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283C28).withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'PRODUCT',
                    style: AppText.meta.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: CustomerDetailColors.labelMuted,
                    ),
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    'RATE',
                    textAlign: TextAlign.right,
                    style: AppText.meta.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: CustomerDetailColors.labelMuted,
                    ),
                  ),
                ),
                SizedBox(
                  width: 62,
                  child: Text(
                    'QTY',
                    textAlign: TextAlign.right,
                    style: AppText.meta.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: CustomerDetailColors.labelMuted,
                    ),
                  ),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    'AMOUNT',
                    textAlign: TextAlign.right,
                    style: AppText.meta.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: CustomerDetailColors.labelMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CustomerDetailColors.divider),
          for (final row in rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _dotFor(row.productName),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            row.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: CustomerDetailColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '₹${row.unitRate.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: AppText.meta.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7E8A7B),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 62,
                    child: Text(
                      '${row.totalQuantity} L',
                      textAlign: TextAlign.right,
                      style: AppText.meta.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7E8A7B),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '₹${row.lineTotal.toStringAsFixed(0)}',
                      textAlign: TextAlign.right,
                      style: AppText.cardTitle.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: CustomerDetailColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF4F6EF)),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 13, 0, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.grandTotal,
                    style: AppText.cardTitle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CustomerDetailColors.onSurface,
                    ),
                  ),
                ),
                Text(
                  '₹${fmt.format(grandTotal.round())}',
                  style: AppText.screenTitle.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
