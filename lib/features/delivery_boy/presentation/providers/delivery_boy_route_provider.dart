import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'delivery_boy_auth_provider.dart';

// ── Value objects ─────────────────────────────────────────────────────────────

class DbRouteSheetKey {
  const DbRouteSheetKey({required this.date, required this.shift});
  final String date;
  final String shift;

  @override
  bool operator ==(Object other) =>
      other is DbRouteSheetKey &&
      other.date == date &&
      other.shift == shift;

  @override
  int get hashCode => Object.hash(date, shift);
}

class DbRouteCustomer {
  const DbRouteCustomer({
    required this.assignmentId,
    required this.sortOrder,
    required this.name,
    required this.address,
    this.orderId,
    this.qty,
    this.status,
  });

  final int assignmentId;
  final int sortOrder;
  final String name;
  final String address;
  // NOTE: phone is intentionally omitted — delivery boys must not see phone numbers.
  final int? orderId;
  final double? qty;
  final String? status;

  bool get isSkipped => status == 'skipped';

  factory DbRouteCustomer.fromJson(Map<String, dynamic> j) {
    final c = j['customer'] as Map<String, dynamic>;
    final o = j['order'] as Map<String, dynamic>?;
    return DbRouteCustomer(
      assignmentId: j['assignment_id'] as int,
      sortOrder: j['sort_order'] as int? ?? 0,
      name: c['name'] as String,
      address: c['address'] as String? ?? '',
      orderId: o?['id'] as int?,
      qty: (o?['qty'] as num?)?.toDouble(),
      status: o?['status'] as String?,
    );
  }
}

class DbRouteEntry {
  const DbRouteEntry({
    required this.routeId,
    required this.routeName,
    required this.shift,
    required this.sortOrder,
    required this.customers,
  });

  final int routeId;
  final String routeName;
  final String shift;
  final int sortOrder;
  final List<DbRouteCustomer> customers;

  factory DbRouteEntry.fromJson(Map<String, dynamic> j) {
    final custs = (j['customers'] as List<dynamic>? ?? [])
        .map((e) => DbRouteCustomer.fromJson(e as Map<String, dynamic>))
        .toList();
    return DbRouteEntry(
      routeId: j['route_id'] as int,
      routeName: j['route_name'] as String,
      shift: j['shift'] as String,
      sortOrder: j['sort_order'] as int? ?? 0,
      customers: custs,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final deliveryBoyRouteSheetProvider =
    FutureProvider.autoDispose.family<List<DbRouteEntry>, DbRouteSheetKey>(
        (ref, key) async {
  final dio = ref.watch(deliveryBoyDioProvider);
  final res = await dio.get('delivery-boy/v1/route-sheet', queryParameters: {
    'date': key.date,
    'shift': key.shift,
  });
  final list = res.data['data'] as List<dynamic>;
  return list
      .map((e) => DbRouteEntry.fromJson(e as Map<String, dynamic>))
      .toList();
});
