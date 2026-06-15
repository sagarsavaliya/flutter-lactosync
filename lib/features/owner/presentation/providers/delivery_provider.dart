import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../domain/entities/owner_models.dart';

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
    required this.customerCount,
    required this.deliverableCount,
    required this.offCount,
    required this.totalLiters,
    this.deliveryBoyName,
    required this.milkPreparation,
  });

  final int id;
  final String name;
  final String shift;
  final int sortOrder;
  final bool isActive;
  final int customerCount;
  final int deliverableCount;
  final int offCount;
  final double totalLiters;
  final String? deliveryBoyName;
  final List<MilkPreparationContainerCard> milkPreparation;

  factory DeliveryRouteModel.fromJson(Map<String, dynamic> j) {
    final boy = j['delivery_boy'] as Map<String, dynamic>?;
    final milkRaw = j['milk_preparation'] as List<dynamic>? ?? [];
    return DeliveryRouteModel(
      id: j['id'] as int,
      name: j['name'] as String,
      shift: j['shift'] as String,
      sortOrder: j['sort_order'] as int? ?? 0,
      isActive: j['is_active'] as bool? ?? true,
      customerCount: j['customer_count'] as int? ?? 0,
      deliverableCount: j['deliverable_count'] as int? ?? 0,
      offCount: j['off_count'] as int? ?? 0,
      totalLiters: (j['total_liters'] as num?)?.toDouble() ?? 0,
      deliveryBoyName: boy?['name'] as String?,
      milkPreparation: milkRaw
          .map((e) => MilkPreparationContainerCard.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class RouteCustomerOrderLine {
  const RouteCustomerOrderLine({
    this.orderId,
    required this.productName,
    required this.quantity,
    required this.status,
  });

  final int? orderId;
  final String productName;
  final double quantity;
  final String status;

  factory RouteCustomerOrderLine.fromJson(Map<String, dynamic> j) =>
      RouteCustomerOrderLine(
        orderId: j['order_id'] as int?,
        productName: j['product_name'] as String? ?? '',
        quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
        status: j['status'] as String? ?? 'pending',
      );
}

class RouteCustomerModel {
  const RouteCustomerModel({
    required this.assignmentId,
    required this.sortOrder,
    required this.customerId,
    required this.name,
    required this.address,
    required this.deliveryLines,
    required this.onVacation,
    required this.isSkipped,
    required this.isDeliverable,
  });

  final int assignmentId;
  final int sortOrder;
  final int customerId;
  final String name;
  final String address;
  final List<RouteCustomerOrderLine> deliveryLines;
  final bool onVacation;
  final bool isSkipped;
  final bool isDeliverable;

  int? get primaryOrderId {
    for (final line in deliveryLines) {
      if (line.orderId != null) return line.orderId;
    }
    return null;
  }

  factory RouteCustomerModel.fromJson(Map<String, dynamic> j) {
    final c = j['customer'] as Map<String, dynamic>;
    final linesRaw = j['delivery_lines'] as List<dynamic>? ?? [];
    return RouteCustomerModel(
      assignmentId: j['id'] as int,
      sortOrder: j['sort_order'] as int? ?? 0,
      customerId: c['id'] as int,
      name: c['name'] as String,
      address: c['address'] as String? ?? '',
      deliveryLines: linesRaw
          .map((e) => RouteCustomerOrderLine.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      onVacation: j['on_vacation'] as bool? ?? false,
      isSkipped: j['is_skipped'] as bool? ?? false,
      isDeliverable: j['is_deliverable'] as bool? ?? true,
    );
  }
}

class RouteSheetCustomer {
  const RouteSheetCustomer({
    required this.assignmentId,
    required this.sortOrder,
    required this.customerId,
    required this.name,
    required this.address,
    this.orderId,
    this.qty,
    this.status,
  });

  final int assignmentId;
  final int sortOrder;
  final int customerId;
  final String name;
  final String address;
  final int? orderId;
  final double? qty;
  final String? status;

  bool get isSkipped => status == 'skipped';

  factory RouteSheetCustomer.fromJson(Map<String, dynamic> j) {
    final c = j['customer'] as Map<String, dynamic>;
    final o = j['order'] as Map<String, dynamic>?;
    final qty = (o?['quantity'] as num?)?.toDouble() ?? (o?['qty'] as num?)?.toDouble();
    return RouteSheetCustomer(
      assignmentId: j['assignment_id'] as int,
      sortOrder: j['sort_order'] as int? ?? 0,
      customerId: (j['customer_id'] as num?)?.toInt() ?? (c['id'] as num?)?.toInt() ?? 0,
      name: c['name'] as String,
      address: c['address'] as String? ?? '',
      orderId: o?['id'] as int?,
      qty: qty,
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
  final res = await dio.get('/owner/delivery-boys');
  final list = res.data['data'] as List<dynamic>;
  return list.map((e) => DeliveryBoyModel.fromJson(e as Map<String, dynamic>)).toList();
});

final deliveryRoutesProvider = FutureProvider.autoDispose<List<DeliveryRouteModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/owner/routes');
  final list = res.data['data'] as List<dynamic>;
  return list.map((e) => DeliveryRouteModel.fromJson(e as Map<String, dynamic>)).toList();
});

Future<void> deleteDeliveryRoute(WidgetRef ref, int routeId) async {
  final dio = ref.read(dioProvider);
  await dio.delete('/owner/routes/$routeId');
  ref.invalidate(deliveryRoutesProvider);
}

final routeAvailableCustomersProvider =
    FutureProvider.autoDispose.family<List<RouteEligibleCustomer>, int>((ref, routeId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/owner/routes/$routeId/available-customers');
  final list = res.data['data'] as List<dynamic>;
  return list
      .map((e) => RouteEligibleCustomer.fromJson(e as Map<String, dynamic>))
      .toList();
});

class RouteEligibleCustomer {
  const RouteEligibleCustomer({
    required this.id,
    required this.name,
    required this.address,
  });

  final int id;
  final String name;
  final String address;

  factory RouteEligibleCustomer.fromJson(Map<String, dynamic> j) =>
      RouteEligibleCustomer(
        id: j['id'] as int,
        name: j['name'] as String,
        address: j['address'] as String? ?? '',
      );
}

final routeCustomersProvider =
    FutureProvider.autoDispose.family<List<RouteCustomerModel>, int>((ref, routeId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/owner/routes/$routeId/customers');
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
  final res = await dio.get('/owner/route-sheet', queryParameters: {
    'date': q.date,
    'shift': q.shift,
  });
  final list = res.data['data'] as List<dynamic>;
  return list.map((e) => RouteSheetEntry.fromJson(e as Map<String, dynamic>)).toList();
});
