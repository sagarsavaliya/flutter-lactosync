import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class DeliveryBoyModel {
  const DeliveryBoyModel({
    required this.id,
    required this.name,
    this.phone,
    required this.salaryType,
    this.salaryAmount,
    required this.isActive,
    required this.hasPin,
  });

  final int id;
  final String name;
  final String? phone;
  final String salaryType;
  final double? salaryAmount;
  final bool isActive;
  final bool hasPin;

  factory DeliveryBoyModel.fromJson(Map<String, dynamic> j) => DeliveryBoyModel(
        id: j['id'] as int,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        salaryType: j['salary_type'] as String,
        salaryAmount: (j['salary_amount'] as num?)?.toDouble(),
        isActive: j['is_active'] as bool? ?? true,
        hasPin: j['has_pin'] as bool? ?? false,
      );
}

class DeliveryRouteModel {
  const DeliveryRouteModel({
    required this.id,
    required this.name,
    required this.shift,
    required this.sortOrder,
    required this.isActive,
  });

  final int id;
  final String name;
  final String shift;
  final int sortOrder;
  final bool isActive;

  factory DeliveryRouteModel.fromJson(Map<String, dynamic> j) => DeliveryRouteModel(
        id: j['id'] as int,
        name: j['name'] as String,
        shift: j['shift'] as String,
        sortOrder: j['sort_order'] as int? ?? 0,
        isActive: j['is_active'] as bool? ?? true,
      );
}

class RouteCustomerModel {
  const RouteCustomerModel({
    required this.assignmentId,
    required this.sortOrder,
    required this.customerId,
    required this.name,
    required this.address,
  });

  final int assignmentId;
  final int sortOrder;
  final int customerId;
  final String name;
  final String address;

  factory RouteCustomerModel.fromJson(Map<String, dynamic> j) {
    final c = j['customer'] as Map<String, dynamic>;
    return RouteCustomerModel(
      assignmentId: j['id'] as int,
      sortOrder: j['sort_order'] as int? ?? 0,
      customerId: c['id'] as int,
      name: c['name'] as String,
      address: c['address'] as String? ?? '',
    );
  }
}

class RouteSheetCustomer {
  const RouteSheetCustomer({
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
  final int? orderId;
  final double? qty;
  final String? status;

  bool get isSkipped => status == 'skipped';

  factory RouteSheetCustomer.fromJson(Map<String, dynamic> j) {
    final c = j['customer'] as Map<String, dynamic>;
    final o = j['order'] as Map<String, dynamic>?;
    return RouteSheetCustomer(
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

class RouteSheetEntry {
  const RouteSheetEntry({
    required this.routeId,
    required this.routeName,
    required this.shift,
    required this.sortOrder,
    this.deliveryBoyName,
    required this.customers,
  });

  final int routeId;
  final String routeName;
  final String shift;
  final int sortOrder;
  final String? deliveryBoyName;
  final List<RouteSheetCustomer> customers;

  factory RouteSheetEntry.fromJson(Map<String, dynamic> j) {
    final boy = j['delivery_boy'] as Map<String, dynamic>?;
    final custs = (j['customers'] as List<dynamic>? ?? [])
        .map((e) => RouteSheetCustomer.fromJson(e as Map<String, dynamic>))
        .toList();
    return RouteSheetEntry(
      routeId: j['route_id'] as int,
      routeName: j['route_name'] as String,
      shift: j['shift'] as String,
      sortOrder: j['sort_order'] as int? ?? 0,
      deliveryBoyName: boy?['name'] as String?,
      customers: custs,
    );
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final deliveryBoysProvider = FutureProvider.autoDispose<List<DeliveryBoyModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/v1/owner/delivery-boys');
  final list = res.data['data'] as List<dynamic>;
  return list.map((e) => DeliveryBoyModel.fromJson(e as Map<String, dynamic>)).toList();
});

final deliveryRoutesProvider = FutureProvider.autoDispose<List<DeliveryRouteModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/v1/owner/routes');
  final list = res.data['data'] as List<dynamic>;
  return list.map((e) => DeliveryRouteModel.fromJson(e as Map<String, dynamic>)).toList();
});

final routeCustomersProvider =
    FutureProvider.autoDispose.family<List<RouteCustomerModel>, int>((ref, routeId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/v1/owner/routes/$routeId/customers');
  final list = res.data['data'] as List<dynamic>;
  return list.map((e) => RouteCustomerModel.fromJson(e as Map<String, dynamic>)).toList();
});

class RouteSheetQuery {
  const RouteSheetQuery({required this.date, required this.shift});
  final String date;
  final String shift;
  @override
  bool operator ==(Object other) =>
      other is RouteSheetQuery && other.date == date && other.shift == shift;
  @override
  int get hashCode => Object.hash(date, shift);
}

final ownerRouteSheetProvider =
    FutureProvider.autoDispose.family<List<RouteSheetEntry>, RouteSheetQuery>((ref, q) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/api/v1/owner/route-sheet', queryParameters: {
    'date': q.date,
    'shift': q.shift,
  });
  final list = res.data['data'] as List<dynamic>;
  return list.map((e) => RouteSheetEntry.fromJson(e as Map<String, dynamic>)).toList();
});
