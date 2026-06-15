import 'package:intl/intl.dart';

import '../../features/owner/domain/entities/owner_models.dart';

class InvoiceDocumentBuilder {
  const InvoiceDocumentBuilder({this.farmName});

  final String? farmName;

  String build({
    required OwnerInvoice invoice,
    required List<InvoiceLine> lines,
    required List<OwnerPayment> payments,
  }) {
    final buffer = StringBuffer();
    if (farmName != null && farmName!.trim().isNotEmpty) {
      buffer.writeln(farmName!.trim());
    }
    buffer.writeln('Milk Bill');
    buffer.writeln('------------------------------');
    buffer.writeln('Customer: ${invoice.customerName}');
    buffer.writeln('Invoice: ${invoice.invoiceNumber}');
    buffer.writeln('Period: ${_billingPeriod(invoice.billingMonth)}');
    buffer.writeln('Status: ${invoice.statusLabel}');
    buffer.writeln('');
    buffer.writeln('Line items');
    for (final line in lines) {
      buffer.writeln(
        '• ${line.productName} — ₹${_amount(line.unitRate)}/ltr · '
        '${_linePeriodShort(invoice.billingMonth)} · ${line.totalQuantity.toStringAsFixed(1)} L = '
        '₹${_amount(line.lineTotal)}',
      );
    }
    buffer.writeln('');
    buffer.writeln('Billed: ₹${_amount(invoice.totalAmount)}');
    buffer.writeln('Paid: ₹${_amount(invoice.amountPaid)}');
    buffer.writeln('Due: ₹${_amount(_dueAmount(invoice))}');
    if (payments.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Payments received');
      for (final payment in payments) {
        buffer.writeln(
          '• ${_formatPaymentDate(payment.paymentDate)} — ${payment.paymentMethodLabel} — '
          '₹${_amount(payment.amount)}',
        );
      }
    }
    return buffer.toString().trim();
  }

  String _billingPeriod(String billingMonth) {
    final parsed = DateTime.tryParse('$billingMonth-01');
    if (parsed == null) return billingMonth;
    final lastDay = DateTime(parsed.year, parsed.month + 1, 0).day;
    return '1–$lastDay ${DateFormat('MMMM yyyy').format(parsed)}';
  }

  String _linePeriodShort(String billingMonth) {
    final parsed = DateTime.tryParse('$billingMonth-01');
    if (parsed == null) return billingMonth;
    final lastDay = DateTime(parsed.year, parsed.month + 1, 0).day;
    return '1–$lastDay ${DateFormat('MMM').format(parsed)}';
  }

  String _formatPaymentDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return DateFormat('dd MMM yyyy').format(parsed);
  }

  String _amount(double value) {
    return NumberFormat('#,##0', 'en_IN').format(value.round());
  }

  double _dueAmount(OwnerInvoice invoice) {
    if (invoice.status == 'paid') return 0;
    if (invoice.balanceDue > 0) return invoice.balanceDue;
    return invoice.totalAmount - invoice.amountPaid;
  }
}
