import 'package:url_launcher/url_launcher.dart';

import '../../features/owner/domain/entities/owner_models.dart';

class CustomerDocumentBuilder {
  const CustomerDocumentBuilder({
    required this.farmName,
    required this.includeFarmHeader,
  });

  final String farmName;
  final bool includeFarmHeader;

  String buildSubscriptionPlan({
    required CustomerDetailInfo customer,
    required List<CustomerSubscriptionDetail> subscriptions,
    required String billingMonth,
  }) {
    final buffer = StringBuffer();
    _writeHeader(buffer, 'Subscription Plan');
    buffer.writeln('Customer: ${customer.fullName}');
    buffer.writeln('Month: $billingMonth');
    buffer.writeln('');
    if (subscriptions.isEmpty) {
      buffer.writeln('No active subscriptions.');
      return buffer.toString();
    }
    for (final sub in subscriptions) {
      buffer.writeln('Plan #${sub.id} (${sub.status})');
      for (final line in sub.lines) {
        buffer.writeln(
          '• ${line.productName} — ${line.quantity} ltr · ${line.shiftLabel} · '
          '₹${line.effectiveRate.toStringAsFixed(0)}/ltr',
        );
      }
      buffer.writeln('');
    }
    return buffer.toString().trim();
  }

  String buildMilkLog({
    required CustomerDetailInfo customer,
    required List<CustomerSubscriptionDetail> subscriptions,
    required String billingMonth,
  }) {
    final buffer = StringBuffer();
    _writeHeader(buffer, 'Milk Delivery Log');
    buffer.writeln('Customer: ${customer.fullName}');
    buffer.writeln('Month: $billingMonth');
    buffer.writeln('');
    for (final sub in subscriptions) {
      if (sub.dailyOrders.isEmpty) continue;
      buffer.writeln('Plan #${sub.id}');
      buffer.writeln('Date       Morning  Evening');
      for (final day in sub.dailyOrders) {
        final morning = day.morning?.toString() ?? '-';
        final evening = day.evening?.toString() ?? '-';
        buffer.writeln('${day.date}   $morning      $evening');
      }
      buffer.writeln('');
    }
    if (buffer.length <= 80) {
      buffer.writeln('No delivery entries for this month.');
    }
    return buffer.toString().trim();
  }

  String buildBillingSummary({
    required CustomerDetailInfo customer,
    required ConsumptionSummary consumption,
    required List<OwnerInvoice> billingHistory,
    required String billingMonth,
  }) {
    final buffer = StringBuffer();
    _writeHeader(buffer, 'Billing Summary');
    buffer.writeln('Customer: ${customer.fullName}');
    buffer.writeln('Month: $billingMonth');
    buffer.writeln('');
    buffer.writeln('Consumption');
    for (final row in consumption.rows) {
      buffer.writeln(
        '• ${row.productName} — ${row.totalQuantity} ltr × '
        '₹${row.unitRate.toStringAsFixed(0)} = ₹${row.lineTotal.toStringAsFixed(0)}',
      );
    }
    buffer.writeln('Total: ₹${consumption.grandTotal.toStringAsFixed(0)}');
    buffer.writeln('');
    buffer.writeln('Billing history');
    if (billingHistory.isEmpty) {
      buffer.writeln('No bills yet.');
    } else {
      for (final bill in billingHistory.take(12)) {
        buffer.writeln(
          '• ${bill.billingMonth} — ${bill.statusLabel} — '
          '₹${bill.totalAmount.toStringAsFixed(0)} (due ₹${bill.balanceDue.toStringAsFixed(0)})',
        );
      }
    }
    return buffer.toString().trim();
  }

  String buildPaymentLog({
    required CustomerDetailInfo customer,
    required List<OwnerPayment> payments,
  }) {
    final buffer = StringBuffer();
    _writeHeader(buffer, 'Payment Receipt Log');
    buffer.writeln('Customer: ${customer.fullName}');
    buffer.writeln('');
    if (payments.isEmpty) {
      buffer.writeln('No payments recorded.');
      return buffer.toString().trim();
    }
    for (final payment in payments) {
      buffer.writeln(
        '• ${payment.paymentDate} — ${payment.paymentMethodLabel} — '
        '₹${payment.amount.toStringAsFixed(0)}'
        '${payment.invoiceNumber != null ? ' · Bill ${payment.invoiceNumber}' : ''}',
      );
    }
    return buffer.toString().trim();
  }

  void _writeHeader(StringBuffer buffer, String title) {
    if (includeFarmHeader) {
      buffer.writeln(farmName);
    }
    buffer.writeln(title);
    buffer.writeln('------------------------------');
  }
}

class WhatsAppShareService {
  Future<void> shareText({
    required String phone,
    required String message,
  }) async {
    final uri = Uri.parse(
      'https://wa.me/${_normalizePhone(phone)}?text=${Uri.encodeComponent(message)}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception('Could not open WhatsApp.');
    }
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '91$digits';
    return digits;
  }
}
