import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../owner/domain/entities/owner_models.dart';
import '../../../owner/presentation/widgets/customer_detail/customer_detail_styles.dart';
import '../../../owner/presentation/widgets/customer_detail/customer_detail_widgets.dart';
import '../../data/repositories/customer_billing_repository.dart';
import '../providers/customer_billing_provider.dart';
import '../providers/customer_dashboard_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';

class CustomerPaymentsPage extends ConsumerWidget {
  const CustomerPaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(customerDashboardProvider);
    final billsAsync = ref.watch(customerBillsProvider);
    final paymentsAsync = ref.watch(customerPaymentsProvider);

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      body: RefreshIndicator(
        color: CustomerDetailColors.accent,
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
            SliverAppBar(
              backgroundColor: CustomerDetailColors.background,
              surfaceTintColor: Colors.transparent,
              floating: true,
              snap: true,
              elevation: 0,
              titleSpacing: 16,
              title: Text(
                'Payments',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: CustomerDetailColors.accent,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
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
                  CustomerDetailSectionLabel(title: 'RECENT BILLS'),
                  billsAsync.when(
                    data: (bills) => bills.isEmpty
                        ? _EmptyCard(
                            icon: LucideIcons.receipt,
                            message: 'No bills yet',
                          )
                        : Column(
                            children: [
                              for (final bill in bills.take(4))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: CustomerDetailBillingRow(
                                    invoice: _toOwnerInvoice(bill),
                                    onTap: () {},
                                  ),
                                ),
                            ],
                          ),
                    loading: () => const _LoadingCard(),
                    error: (_, __) => _EmptyCard(
                      icon: LucideIcons.alertCircle,
                      message: 'Could not load bills',
                    ),
                  ),
                  CustomerDetailSectionLabel(title: 'TRANSACTION HISTORY'),
                  paymentsAsync.when(
                    data: (payments) => payments.isEmpty
                        ? _EmptyCard(
                            icon: LucideIcons.wallet,
                            message: 'No payments recorded yet',
                          )
                        : Column(
                            children: [
                              for (final payment in payments)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: CustomerDetailPaymentRow(
                                    invoiceRef: payment.invoiceNumber?.isNotEmpty == true
                                        ? payment.invoiceNumber!
                                        : _methodLabel(payment.method),
                                    dateLabel: _formatDate(payment.paymentDate),
                                    method: _methodLabel(payment.method),
                                    amount: NumberFormat('#,##0.##', 'en_IN').format(payment.amount),
                                  ),
                                ),
                            ],
                          ),
                    loading: () => const _LoadingCard(),
                    error: (_, __) => _EmptyCard(
                      icon: LucideIcons.alertCircle,
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

  static OwnerInvoice _toOwnerInvoice(CustomerBill bill) {
    final status = bill.status == 'unpaid' ? 'pending' : bill.status;
    return OwnerInvoice(
      id: bill.id,
      customerId: 0,
      customerName: '',
      billingMonth: bill.billingMonth,
      invoiceNumber: '',
      totalAmount: bill.totalAmount,
      amountPaid: bill.totalAmount - bill.balanceDue,
      balanceDue: bill.balanceDue,
      status: status,
      statusLabel: '',
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
        return 'Bank Transfer';
      default:
        return method.isEmpty ? 'Payment' : method;
    }
  }
}

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

  Future<void> _launchUpi() async {
    final vpa = widget.upiVpa;
    if (vpa == null || vpa.isEmpty) {
      AppSnackBar.show(context, 'UPI payment not configured by the dairy.');
      return;
    }
    final payee = Uri.encodeComponent(widget.upiPayeeName ?? 'Dairy');
    final amount = widget.balance.toStringAsFixed(2);
    final url =
        'upi://pay?pa=${Uri.encodeComponent(vpa)}&pn=$payee&am=$amount&cu=INR&tn=Dairy+Payment';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      AppSnackBar.show(context, 'No UPI app found. Please install one to continue.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CustomerDetailColors.duesGradientStart,
            CustomerDetailColors.duesGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CustomerDetailColors.danger.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pending balance',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF7DBCD),
            ),
          ),
          Text(
            '₹${fmt.format(widget.balance.round())}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFFCEFE8),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 15),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            child: InkWell(
              onTap: () => setState(() => _showPayMethods = !_showPayMethods),
              borderRadius: BorderRadius.circular(13),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.wallet, size: 17, color: CustomerDetailColors.danger),
                    const SizedBox(width: 7),
                    Text(
                      _showPayMethods ? 'Hide options' : 'Pay Now',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CustomerDetailColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_showPayMethods) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _UpiChip(label: 'GPay', onTap: _launchUpi),
                _UpiChip(label: 'PhonePe', onTap: _launchUpi),
                _UpiChip(label: 'Paytm', onTap: _launchUpi),
                _UpiChip(label: 'UPI', onTap: _launchUpi),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _UpiChip extends StatelessWidget {
  const _UpiChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
        border: Border.all(color: CustomerDetailColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: CustomerDetailColors.iconMuted),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: CustomerDetailColors.onSurfaceVariant),
          ),
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
      height: 80,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
        border: Border.all(color: CustomerDetailColors.border),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: CustomerDetailColors.accent, strokeWidth: 2),
      ),
    );
  }
}
