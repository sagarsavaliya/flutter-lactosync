import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../owner/domain/entities/owner_models.dart';
import 'delivery_boy_auth_provider.dart';

// ── Keys ──────────────────────────────────────────────────────────────────────

class DbRouteSheetKey {
  const DbRouteSheetKey({required this.date, required this.shift});
  final String date;
  final String shift;

  static DbRouteSheetKey today(String shift) => DbRouteSheetKey(
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        shift: shift,
      );

  @override
  bool operator ==(Object other) =>
      other is DbRouteSheetKey && other.date == date && other.shift == shift;

  @override
  int get hashCode => Object.hash(date, shift);
}

// ── Models ────────────────────────────────────────────────────────────────────

class DbDeliveryLine {
  const DbDeliveryLine({
    this.orderId,
    required this.productName,
    required this.quantity,
    required this.status,
  });

  final int? orderId;
  final String productName;
  final double quantity;
  final String status;

  bool get isDelivered => status == 'delivered';
  bool get isSkipped =>
      status == 'skipped' || status == 'vacation' || status == 'cancelled';

  factory DbDeliveryLine.fromJson(Map<String, dynamic> j) => DbDeliveryLine(
        orderId: (j['order_id'] as num?)?.toInt(),
        productName: j['product_name'] as String? ?? '',
        quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
        status: j['status'] as String? ?? 'pending',
      );

  String get label {
    if (productName.isEmpty) return '${quantity.toStringAsFixed(1)} L';
    return '$productName ${quantity.toStringAsFixed(1)} L';
  }
}

class DbRouteCustomer {
  const DbRouteCustomer({
    required this.assignmentId,
    required this.sortOrder,
    required this.customerId,
    required this.name,
    required this.address,
    required this.deliveryLines,
    required this.onVacation,
    required this.isSkipped,
    required this.isDeliverable,
    required this.outstandingBalance,
  });

  final int assignmentId;
  final int sortOrder;
  final int customerId;
  final String name;
  final String address;
  final List<DbDeliveryLine> deliveryLines;
  final bool onVacation;
  final bool isSkipped;
  final bool isDeliverable;
  final double outstandingBalance;

  int? get primaryOrderId {
    for (final line in deliveryLines) {
      if (line.orderId != null) return line.orderId;
    }
    return null;
  }

  double get totalQty =>
      deliveryLines.fold<double>(0, (s, l) => s + l.quantity);

  String get primaryProductLabel {
    if (deliveryLines.isEmpty) return '';
    return deliveryLines.first.label;
  }

  bool get isDelivered =>
      deliveryLines.isNotEmpty && deliveryLines.every((l) => l.isDelivered);

  factory DbRouteCustomer.fromJson(Map<String, dynamic> j) {
    final c = j['customer'] is Map<String, dynamic>
        ? j['customer'] as Map<String, dynamic>
        : <String, dynamic>{
            'id': j['customer_id'] ?? j['id'],
            'name': j['customer_name'] ?? j['name'] ?? '',
            'address': j['address'] ?? '',
          };
    var linesRaw = j['delivery_lines'] as List<dynamic>? ?? [];
    var deliveryLines = linesRaw
        .map((e) => DbDeliveryLine.fromJson(e as Map<String, dynamic>))
        .toList();

    // Legacy API: single `order` object instead of delivery_lines.
    if (deliveryLines.isEmpty && j['order'] is Map<String, dynamic>) {
      final o = j['order'] as Map<String, dynamic>;
      final qty = (o['qty'] as num?)?.toDouble() ??
          (o['quantity'] as num?)?.toDouble() ??
          0;
      final status = o['status']?.toString() ?? 'pending';
      deliveryLines = [
        DbDeliveryLine(
          orderId: (o['id'] as num?)?.toInt(),
          productName: o['product_name'] as String? ?? 'Milk',
          quantity: qty,
          status: status,
        ),
      ];
    }

    final customerId = (c['id'] as num?)?.toInt() ?? 0;
    final isSkippedLegacy = j['is_skipped'] as bool? ??
        (j['order'] is Map && (j['order'] as Map)['status'] == 'skipped');

    return DbRouteCustomer(
      assignmentId: (j['assignment_id'] as num?)?.toInt() ?? 0,
      sortOrder: j['sort_order'] as int? ?? 0,
      customerId: customerId,
      name: c['name'] as String? ?? '',
      address: c['address'] as String? ?? '',
      deliveryLines: deliveryLines,
      onVacation: j['on_vacation'] as bool? ?? false,
      isSkipped: isSkippedLegacy,
      isDeliverable: j['is_deliverable'] as bool? ?? !isSkippedLegacy,
      outstandingBalance:
          (j['outstanding_balance'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DbRouteEntry {
  const DbRouteEntry({
    required this.routeId,
    required this.routeName,
    required this.shift,
    required this.totalLiters,
    required this.customerCount,
    required this.deliverableCount,
    required this.milkPreparation,
    required this.customers,
  });

  final int routeId;
  final String routeName;
  final String shift;
  final double totalLiters;
  final int customerCount;
  final int deliverableCount;
  final List<MilkPreparationContainerCard> milkPreparation;
  final List<DbRouteCustomer> customers;

  int get bottleCount => milkPreparation
      .where((c) => c.containerTypeName.toLowerCase().contains('glass'))
      .fold<int>(0, (s, c) => s + c.totals.values.fold(0, (a, b) => a + b));

  int get bagCount => milkPreparation
      .where((c) => c.containerTypeName.toLowerCase().contains('plastic'))
      .fold<int>(0, (s, c) => s + c.totals.values.fold(0, (a, b) => a + b));

  int get deliveredCount =>
      customers.where((c) => c.isDelivered).length;

  int get skippedCount => customers.where((c) => c.isSkipped && !c.isDelivered).length;

  int get remainingCount =>
      customers.where((c) => c.isDeliverable && !c.isDelivered && !c.isSkipped).length;

  factory DbRouteEntry.fromJson(Map<String, dynamic> j) {
    final milkRaw = j['milk_preparation'] as List<dynamic>? ?? [];
    final custs = (j['customers'] as List<dynamic>? ?? [])
        .map((e) => DbRouteCustomer.fromJson(e as Map<String, dynamic>))
        .toList();
    final totalLiters = (j['total_liters'] as num?)?.toDouble() ??
        custs.fold<double>(0, (s, c) => s + c.totalQty);
    return DbRouteEntry(
      routeId: (j['route_id'] as num?)?.toInt() ?? 0,
      routeName: j['route_name'] as String? ?? '',
      shift: j['shift'] as String? ?? 'morning',
      totalLiters: totalLiters,
      customerCount: j['customer_count'] as int? ?? custs.length,
      deliverableCount: j['deliverable_count'] as int? ?? custs.length,
      milkPreparation: milkRaw
          .map((e) => MilkPreparationContainerCard.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      customers: custs,
    );
  }
}

class DbRouteSheetData {
  const DbRouteSheetData({
    required this.deliveryBoyName,
    required this.routes,
  });

  final String deliveryBoyName;
  final List<DbRouteEntry> routes;

  DbRouteEntry? get primaryRoute =>
      routes.isNotEmpty ? routes.first : null;

  factory DbRouteSheetData.fromJson(Map<String, dynamic> j) {
    final routesRaw = j['routes'] as List<dynamic>? ?? j['data'] as List<dynamic>? ?? [];
    // Backward compat: API may return a bare list of routes.
    if (j['routes'] == null && j['delivery_boy_name'] == null && routesRaw.isNotEmpty) {
      return DbRouteSheetData(
        deliveryBoyName: '',
        routes: routesRaw
            .map((e) => DbRouteEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    return DbRouteSheetData(
      deliveryBoyName: j['delivery_boy_name'] as String? ?? '',
      routes: routesRaw
          .map((e) => DbRouteEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DbCashCollectionItem {
  const DbCashCollectionItem({
    required this.paymentId,
    required this.customerName,
    required this.amount,
    this.recordedAt,
    this.stopNumber,
  });

  final int paymentId;
  final String customerName;
  final double amount;
  final String? recordedAt;
  final int? stopNumber;

  factory DbCashCollectionItem.fromJson(Map<String, dynamic> j) =>
      DbCashCollectionItem(
        paymentId: j['payment_id'] as int,
        customerName: j['customer_name'] as String? ?? 'Customer',
        amount: (j['amount'] as num?)?.toDouble() ?? 0,
        recordedAt: j['recorded_at'] as String?,
        stopNumber: (j['stop_number'] as num?)?.toInt(),
      );
}

class DbCashCollectionsData {
  const DbCashCollectionsData({required this.total, required this.items});
  final double total;
  final List<DbCashCollectionItem> items;

  factory DbCashCollectionsData.fromJson(Map<String, dynamic> j) {
    final itemsRaw = j['items'] as List<dynamic>? ?? [];
    return DbCashCollectionsData(
      total: (j['total'] as num?)?.toDouble() ?? 0,
      items: itemsRaw
          .map((e) =>
              DbCashCollectionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final deliveryBoyRouteSheetProvider =
    FutureProvider.autoDispose.family<DbRouteSheetData, DbRouteSheetKey>(
        (ref, key) async {
  final dio = ref.watch(deliveryBoyDioProvider);
  final res = await dio.get<Map<String, dynamic>>(
    '/delivery-boy/v1/route-sheet',
    queryParameters: {'date': key.date, 'shift': key.shift},
  );
  final data = res.data!['data'];
  if (data is Map<String, dynamic>) {
    return DbRouteSheetData.fromJson(data);
  }
  if (data is List<dynamic>) {
    return DbRouteSheetData(
      deliveryBoyName: '',
      routes: data
          .map((e) => DbRouteEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
  return const DbRouteSheetData(deliveryBoyName: '', routes: []);
});

final deliveryBoyCashCollectionsProvider =
    FutureProvider.autoDispose.family<DbCashCollectionsData, String>(
        (ref, date) async {
  final dio = ref.watch(deliveryBoyDioProvider);
  final res = await dio.get<Map<String, dynamic>>(
    '/delivery-boy/v1/cash-collections',
    queryParameters: {'date': date},
  );
  return DbCashCollectionsData.fromJson(
    Map<String, dynamic>.from(res.data!['data'] as Map),
  );
});

// ── Actions ───────────────────────────────────────────────────────────────────

Future<void> deliveryBoyMarkDelivered({
  required WidgetRef ref,
  required int orderId,
  required String date,
  required double quantity,
  double cashReceived = 0,
}) async {
  final dio = ref.read(deliveryBoyDioProvider);
  await dio.post<Map<String, dynamic>>('/delivery-boy/v1/mark-delivered', data: {
    'order_id': orderId,
    'date': date,
    'quantity': quantity,
    if (cashReceived > 0) 'cash_received': cashReceived,
  });
}

Future<void> deliveryBoySkipDelivery({
  required WidgetRef ref,
  required int customerId,
  required String date,
}) async {
  final dio = ref.read(deliveryBoyDioProvider);
  await dio.post<Map<String, dynamic>>('/delivery-boy/v1/skip-delivery', data: {
    'customer_id': customerId,
    'date': date,
  });
}
