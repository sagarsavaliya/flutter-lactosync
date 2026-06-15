import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/repositories/customer_billing_repository.dart';
import 'customer_dashboard_styles.dart';

// ── Header ────────────────────────────────────────────────────────────────────

class CusPaymentsHeader extends StatelessWidget {
  const CusPaymentsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CusDashMetrics.horizontalPad,
        12,
        CusDashMetrics.horizontalPad,
        8,
      ),
      child: Text('Payments', style: CusDashText.greeting.copyWith(fontSize: 28)),
    );
  }
}

// ── Pending hero ──────────────────────────────────────────────────────────────

class CusPaymentsPendingHero extends StatelessWidget {
  const CusPaymentsPendingHero({
    super.key,
    required this.balance,
    required this.billLabel,
    required this.dueLabel,
    required this.upiVpa,
    required this.upiPayeeName,
  });

  final double balance;
  final String billLabel;
  final String dueLabel;
  final String? upiVpa;
  final String? upiPayeeName;

  Future<void> _pay(BuildContext context) async {
    final vpa = upiVpa;
    if (vpa == null || vpa.isEmpty) {
      AppSnackBar.show(context, 'UPI payment not configured by the dairy.');
      return;
    }
    final payee = Uri.encodeComponent(upiPayeeName ?? 'Dairy');
    final amount = balance.toStringAsFixed(2);
    final uri = Uri.parse(
      'upi://pay?pa=${Uri.encodeComponent(vpa)}&pn=$payee&am=$amount&cu=INR&tn=Dairy+Payment',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      AppSnackBar.show(context, 'No UPI app found. Please install one to continue.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final amountLabel = '₹${fmt.format(balance.round())}';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC06C4D), Color(0xFFA85A3F)],
        ),
        borderRadius: BorderRadius.circular(CusDashMetrics.cardRadius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC06C4D).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Total pending',
            style: AppText.meta.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amountLabel,
            style: GoogleFonts.quicksand(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(LucideIcons.clock3, size: 14, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
              Text(
                '$billLabel • $dueLabel',
                style: AppText.meta.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: balance > 0 ? () => _pay(context) : null,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.wallet, size: 18, color: CusDashColors.payBrown),
                    const SizedBox(width: 8),
                    Text(
                      'Pay $amountLabel',
                      style: AppText.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: CusDashColors.payBrown,
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

// ── Quick pay actions ─────────────────────────────────────────────────────────

class CusPaymentsQuickActions extends StatelessWidget {
  const CusPaymentsQuickActions({
    super.key,
    required this.balance,
    required this.upiVpa,
    required this.upiPayeeName,
  });

  final double balance;
  final String? upiVpa;
  final String? upiPayeeName;

  Future<void> _launchUpi(BuildContext context) async {
    final vpa = upiVpa;
    if (vpa == null || vpa.isEmpty) {
      AppSnackBar.show(context, 'UPI payment not configured by the dairy.');
      return;
    }
    final payee = Uri.encodeComponent(upiPayeeName ?? 'Dairy');
    final amount = balance.toStringAsFixed(2);
    final uri = Uri.parse(
      'upi://pay?pa=${Uri.encodeComponent(vpa)}&pn=$payee&am=$amount&cu=INR&tn=Dairy+Payment',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      AppSnackBar.show(context, 'No UPI app found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickPayTile(
            icon: LucideIcons.qrCode,
            iconBg: const Color(0xFFE3EEF9),
            iconColor: const Color(0xFF3B6EA8),
            label: 'Pay by UPI',
            onTap: balance > 0 ? () => _launchUpi(context) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickPayTile(
            icon: LucideIcons.banknote,
            iconBg: CusDashColors.accentLight,
            iconColor: CusDashColors.accent,
            label: 'Pay cash',
            onTap: () => AppSnackBar.show(
              context,
              'Pay cash to your delivery person or dairy office.',
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickPayTile extends StatelessWidget {
  const _QuickPayTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CusDashColors.surface,
      borderRadius: BorderRadius.circular(CusDashMetrics.innerRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CusDashMetrics.innerRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CusDashMetrics.innerRadius),
            border: Border.all(color: CusDashColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF283C28).withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: AppText.body.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CusDashColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bills ─────────────────────────────────────────────────────────────────────

class CusPaymentsBillRow extends StatelessWidget {
  const CusPaymentsBillRow({
    super.key,
    required this.bill,
    required this.subtitle,
    this.isCurrent = false,
  });

  final CustomerBill bill;
  final String subtitle;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final parts = bill.billingMonth.split('-');
    final title = parts.length == 2
        ? DateFormat('MMMM yyyy').format(DateTime(int.parse(parts[0]), int.parse(parts[1])))
        : bill.billingMonth;

    final isPaid = bill.status == 'paid' || bill.balanceDue <= 0;
    final statusLabel = isPaid ? 'Paid' : 'Pending';
    final statusBg = isPaid ? CusDashColors.accentLight : const Color(0xFFFCE8E6);
    final statusInk = isPaid ? CusDashColors.activeInk : const Color(0xFFC0392B);
    final iconBg = isPaid ? CusDashColors.accentLight : const Color(0xFFFCE8E6);
    final iconColor = isPaid ? CusDashColors.accent : const Color(0xFFC0392B);

    final fmt = NumberFormat('#,##0', 'en_IN');
    final amount = bill.balanceDue > 0 ? bill.balanceDue : bill.totalAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: CusDashText.whiteCard(radius: CusDashMetrics.innerRadius),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.receipt, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.cardTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CusDashColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppText.meta.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CusDashColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${fmt.format(amount.round())}',
                style: AppText.cardTitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: CusDashColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: AppText.meta.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusInk,
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

// ── Payment history ───────────────────────────────────────────────────────────

class CusPaymentsHistoryRow extends StatelessWidget {
  const CusPaymentsHistoryRow({super.key, required this.payment});

  final CustomerPayment payment;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(payment.paymentDate);
    final method = _methodLabel(payment.method);
    final methodBg = method == 'UPI' ? const Color(0xFFE3EEF9) : CusDashColors.accentLight;
    final methodInk = method == 'UPI' ? const Color(0xFF3B6EA8) : CusDashColors.activeInk;

    final monthTitle = payment.invoiceNumber?.isNotEmpty == true
        ? '${payment.invoiceNumber} paid'
        : '$dateLabel paid';

    final fmt = NumberFormat('#,##0', 'en_IN');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: CusDashText.whiteCard(radius: CusDashMetrics.innerRadius),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: CusDashColors.accentLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.check, size: 20, color: CusDashColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthTitle,
                  style: AppText.cardTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CusDashColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      dateLabel,
                      style: AppText.meta.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CusDashColors.inkMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: methodBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        method,
                        style: AppText.meta.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: methodInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₹${fmt.format(payment.amount.round())}',
            style: AppText.cardTitle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: CusDashColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(String raw) {
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  static String _methodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'upi':
        return 'UPI';
      case 'bank_transfer':
        return 'Bank';
      default:
        return method.isEmpty ? 'Payment' : method;
    }
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class CusPaymentsSectionLabel extends StatelessWidget {
  const CusPaymentsSectionLabel({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(title, style: CusDashText.sectionLabel),
    );
  }
}

class CusPaymentsEmptyCard extends StatelessWidget {
  const CusPaymentsEmptyCard({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(24),
      decoration: CusDashText.whiteCard(radius: CusDashMetrics.innerRadius),
      child: Center(
        child: Text(
          message,
          style: AppText.body.copyWith(color: CusDashColors.inkMuted),
        ),
      ),
    );
  }
}

class CusPaymentsLoadingCard extends StatelessWidget {
  const CusPaymentsLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: CusDashText.whiteCard(radius: CusDashMetrics.innerRadius),
      child: const Center(
        child: CircularProgressIndicator(color: CusDashColors.accent, strokeWidth: 2),
      ),
    );
  }
}

/// Bill subtitle helpers shared with the payments page.
String cusBillSubtitle({
  required CustomerBill bill,
  required bool isCurrent,
  double? currentLiters,
}) {
  if (bill.status == 'paid' || bill.balanceDue <= 0) {
    return 'Invoice • settled';
  }
  if (isCurrent && currentLiters != null && currentLiters > 0) {
    final liters = currentLiters == currentLiters.roundToDouble()
        ? '${currentLiters.toInt()} L'
        : '${currentLiters.toStringAsFixed(1)} L';
    return 'Current • $liters';
  }
  return 'Invoice • pending';
}

CusBillHeroLabels cusBillHeroLabels(List<CustomerBill>? bills, DateTime now) {
  final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  CustomerBill? current;
  if (bills != null) {
    for (final b in bills) {
      if (b.billingMonth == monthKey && b.balanceDue > 0) {
        current = b;
        break;
      }
    }
    if (current == null) {
      for (final b in bills) {
        if (b.balanceDue > 0) {
          current = b;
          break;
        }
      }
    }
  }

  if (current != null) {
    final parts = current.billingMonth.split('-');
    final billMonth = parts.length == 2
        ? DateFormat('MMMM').format(DateTime(int.parse(parts[0]), int.parse(parts[1])))
        : 'Bill';
    final due = DateTime(
      parts.length == 2 ? int.parse(parts[0]) : now.year,
      parts.length == 2 ? int.parse(parts[1]) + 1 : now.month + 1,
      5,
    );
    return CusBillHeroLabels(
      billLabel: '$billMonth bill',
      dueLabel: 'due ${DateFormat('d MMM').format(due)}',
    );
  }

  final billMonth = DateFormat('MMMM').format(now);
  final due = DateTime(now.year, now.month + 1, 5);
  return CusBillHeroLabels(
    billLabel: '$billMonth bill',
    dueLabel: 'due ${DateFormat('d MMM').format(due)}',
  );
}

class CusBillHeroLabels {
  const CusBillHeroLabels({required this.billLabel, required this.dueLabel});
  final String billLabel;
  final String dueLabel;
}
