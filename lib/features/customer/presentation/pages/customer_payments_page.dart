import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/customer_billing_repository.dart';
import '../providers/customer_billing_provider.dart';
import '../providers/customer_dashboard_provider.dart';

class CustomerPaymentsPage extends ConsumerWidget {
  const CustomerPaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(customerDashboardProvider);
    final billsAsync = ref.watch(customerBillsProvider);
    final paymentsAsync = ref.watch(customerPaymentsProvider);

    return Scaffold(
      backgroundColor: CusColors.surface,
      body: RefreshIndicator(
        color: CusColors.primaryContainer,
        onRefresh: () async {
          ref.invalidate(customerDashboardProvider);
          ref.invalidate(customerBillsProvider);
          ref.invalidate(customerPaymentsProvider);
          await Future.wait([
            ref.read(customerDashboardProvider.future).catchError((_) => <String, dynamic>{}),
            ref.read(customerBillsProvider.future).catchError((_) => <CustomerBill>[]),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            _SliverPaymentsHeader(),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  // Outstanding bill banner
                  dashAsync.when(
                    data: (data) {
                      final balance = (data['outstanding_balance'] as num?)?.toDouble() ?? 0.0;
                      final upiVpa = data['upi_vpa'] as String?;
                      final upiPayeeName = data['upi_payee_name'] as String?;
                      if (balance <= 0) return const SizedBox.shrink();
                      return Column(
                        children: [
                          _OutstandingCard(
                            balance: balance,
                            upiVpa: upiVpa,
                            upiPayeeName: upiPayeeName,
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Recent bills
                  _SectionTitle(title: 'Recent Bills'),
                  const SizedBox(height: 12),
                  billsAsync.when(
                    data: (bills) => bills.isEmpty
                        ? _EmptyCard(
                            icon: Icons.receipt_long_outlined,
                            message: 'No bills yet',
                          )
                        : _BillsList(bills: bills),
                    loading: () => const _LoadingCard(),
                    error: (_, __) => _EmptyCard(
                      icon: Icons.error_outline,
                      message: 'Could not load bills',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transaction history
                  _SectionTitle(title: 'Transaction History'),
                  const SizedBox(height: 12),
                  paymentsAsync.when(
                    data: (payments) => payments.isEmpty
                        ? _EmptyCard(
                            icon: Icons.payments_outlined,
                            message: 'No payments recorded yet',
                          )
                        : _TransactionsList(payments: payments),
                    loading: () => const _LoadingCard(),
                    error: (_, __) => _EmptyCard(
                      icon: Icons.error_outline,
                      message: 'Could not load payments',
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SliverPaymentsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: CusColors.surface,
      surfaceTintColor: Colors.transparent,
      floating: true,
      snap: true,
      elevation: 0,
      titleSpacing: 20,
      title: const Text(
        'Payments',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: CusColors.primary,
        ),
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: CusColors.onSurface,
      ),
    );
  }
}

// ── Outstanding card ──────────────────────────────────────────────────────────

class _OutstandingCard extends StatefulWidget {
  const _OutstandingCard({
    required this.balance,
    required this.upiVpa,
    required this.upiPayeeName,
  });

  final double balance;
  final String? upiVpa;
  final String? upiPayeeName;

  @override
  State<_OutstandingCard> createState() => _OutstandingCardState();
}

class _OutstandingCardState extends State<_OutstandingCard> {
  bool _showPayMethods = false;

  String get _formattedBalance =>
      '₹${NumberFormat('#,##,##0.##', 'en_IN').format(widget.balance)}';

  Future<void> _launchUpi({String? packageHint}) async {
    final vpa = widget.upiVpa;
    if (vpa == null || vpa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI payment not configured by the dairy.')),
      );
      return;
    }
    final payee = Uri.encodeComponent(widget.upiPayeeName ?? 'Dairy');
    final amount = widget.balance.toStringAsFixed(2);
    final url = 'upi://pay?pa=${Uri.encodeComponent(vpa)}&pn=$payee&am=$amount&cu=INR&tn=Dairy+Payment';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No UPI app found. Please install one to continue.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [CusColors.primaryContainer, Color(0xFF1A5C3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: CusColors.primaryContainer.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT OUTSTANDING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: CusColors.onPrimaryContainer,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formattedBalance,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: CusColors.onPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => setState(() => _showPayMethods = !_showPayMethods),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CusColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _showPayMethods ? Icons.expand_less : Icons.arrow_forward,
                          size: 18,
                          color: CusColors.primaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showPayMethods) ...[
            Divider(height: 1, thickness: 0.5, color: Colors.white.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  const Text(
                    'Choose payment app',
                    style: TextStyle(
                      fontSize: 13,
                      color: CusColors.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _UpiAppButton(
                        label: 'GPay',
                        icon: Icons.account_balance_wallet_outlined,
                        color: const Color(0xFF4285F4),
                        onTap: () => _launchUpi(packageHint: 'com.google.android.apps.nbu.paisa.user'),
                      ),
                      _UpiAppButton(
                        label: 'PhonePe',
                        icon: Icons.phone_android_outlined,
                        color: const Color(0xFF5F259F),
                        onTap: () => _launchUpi(packageHint: 'com.phonepe.app'),
                      ),
                      _UpiAppButton(
                        label: 'Paytm',
                        icon: Icons.account_balance_outlined,
                        color: const Color(0xFF00B9F1),
                        onTap: () => _launchUpi(packageHint: 'net.one97.paytm'),
                      ),
                      _UpiAppButton(
                        label: 'UPI',
                        icon: Icons.qr_code_outlined,
                        color: Colors.white,
                        onTap: () => _launchUpi(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpiAppButton extends StatelessWidget {
  const _UpiAppButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: CusColors.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bills list ────────────────────────────────────────────────────────────────

class _BillsList extends StatelessWidget {
  const _BillsList({required this.bills});
  final List<CustomerBill> bills;

  @override
  Widget build(BuildContext context) {
    final visible = bills.take(4).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CusColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          for (int i = 0; i < visible.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 0.5, indent: 20, endIndent: 20, color: CusColors.outlineVariant),
            _BillRow(bill: visible[i]),
          ],
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.bill});
  final CustomerBill bill;

  String _formatMonth(String raw) {
    try {
      return DateFormat('MMMM yyyy').format(DateTime.parse('$raw-01'));
    } catch (_) {
      return raw;
    }
  }

  String _formatAmount(double amount) =>
      '₹${NumberFormat('#,##,##0', 'en_IN').format(amount)}';

  @override
  Widget build(BuildContext context) {
    final isPaid = bill.status.toLowerCase() == 'paid';
    final badgeColor = isPaid ? const Color(0xFF1E8E5A) : CusColors.error;
    final badgeBg = isPaid ? const Color(0xFFE8F5EE) : CusColors.errorContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPaid ? const Color(0xFFE8F5EE) : CusColors.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPaid ? Icons.check_outlined : Icons.receipt_outlined,
              size: 20,
              color: badgeColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatMonth(bill.billingMonth),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CusColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isPaid ? 'Paid' : (bill.status == 'partial' ? 'Partial' : 'Due'),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: badgeColor),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatAmount(bill.totalAmount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: CusColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transactions list ─────────────────────────────────────────────────────────

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({required this.payments});
  final List<CustomerPayment> payments;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CusColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          for (int i = 0; i < payments.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 0.5, indent: 20, endIndent: 20, color: CusColors.outlineVariant),
            _PaymentRow(payment: payments[i]),
          ],
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});
  final CustomerPayment payment;

  String _formatDate(String raw) {
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _formatAmount(double amount) =>
      '₹${NumberFormat('#,##,##0.##', 'en_IN').format(amount)}';

  String _methodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash': return 'Cash';
      case 'upi': return 'UPI';
      case 'bank_transfer': return 'Bank Transfer';
      default: return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_downward_rounded, size: 20, color: Color(0xFF1E8E5A)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _methodLabel(payment.method),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CusColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(payment.paymentDate),
                  style: const TextStyle(fontSize: 12, color: CusColors.onSurfaceVariant),
                ),
                if (payment.note != null && payment.note!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    payment.note!,
                    style: const TextStyle(fontSize: 11, color: CusColors.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text(
            _formatAmount(payment.amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E8E5A),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CusColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(icon, size: 40, color: CusColors.outlineVariant),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(fontSize: 14, color: CusColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CusColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      height: 80,
      child: const Center(
        child: CircularProgressIndicator(color: CusColors.primaryContainer, strokeWidth: 2),
      ),
    );
  }
}
