import '../../../owner/domain/entities/owner_models.dart';

/// Maps customer dashboard subscription + monthly order days into owner detail models
/// so the same subscription/consumption UI can be reused in the customer app.
SubscriptionLineDetail customerSubscriptionLineFromOrders({
  required Map<String, dynamic> subscription,
  required List<Map<String, dynamic>> days,
}) {
  final lineId = (subscription['subscription_line_id'] as num?)?.toInt() ?? 0;
  final shift = subscription['shift'] as String? ?? 'morning';
  final shiftLabel = subscription['shift_label'] as String? ??
      (shift.isEmpty ? shift : '${shift[0].toUpperCase()}${shift.substring(1)}');

  final dailyOrders = <SubscriptionDayOrder>[];
  for (final day in days) {
    final date = day['date'] as String? ?? '';
    final status = day['status'] as String? ?? 'no_record';
    final entries = (day['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    Map<String, dynamic>? entry;
    for (final candidate in entries) {
      if ((candidate['subscription_line_id'] as num?)?.toInt() == lineId) {
        entry = candidate;
        break;
      }
    }
    if (entry == null) continue;

    final qty = (entry['qty'] as num?)?.toDouble() ?? 0;
    final delivered = status == 'delivered' && qty > 0;

    dailyOrders.add(
      SubscriptionDayOrder(
        date: date,
        morning: shift == 'morning' ? qty : null,
        evening: shift == 'evening' ? qty : null,
        hasDelivery: delivered,
      ),
    );
  }

  return SubscriptionLineDetail(
    id: lineId,
    productId: 0,
    productName: subscription['product_name'] as String? ?? '',
    unitRate: 0,
    couponAmount: 0,
    effectiveRate: 0,
    shift: shift,
    shiftLabel: shiftLabel,
    quantity: (subscription['qty'] as num?)?.toDouble() ?? 1,
    dailyOrders: dailyOrders,
  );
}

List<ConsumptionRow> customerConsumptionRowsFromJson(Map<String, dynamic>? json) {
  if (json == null) return const [];
  final rows = json['rows'] as List? ?? [];
  return rows
      .map((row) => ConsumptionRow.fromJson(Map<String, dynamic>.from(row as Map)))
      .toList();
}

double customerConsumptionGrandTotal(Map<String, dynamic>? json) =>
    (json?['grand_total'] as num?)?.toDouble() ?? 0;
