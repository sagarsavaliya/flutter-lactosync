import '../../../../core/utils/api_json.dart';

class OwnerDashboardStats {
  const OwnerDashboardStats({
    required this.customers,
    required this.subscriptions,
    this.todayOrders,
    this.milkPreparation,
  });

  final CountBreakdown customers;
  final SubscriptionBreakdown subscriptions;
  final OrderSummary? todayOrders;
  final MilkPreparationSummary? milkPreparation;

  factory OwnerDashboardStats.fromJson(Map<String, dynamic> json) {
    return OwnerDashboardStats(
      customers: CountBreakdown.fromJson(
        Map<String, dynamic>.from(json['customers'] as Map),
      ),
      subscriptions: SubscriptionBreakdown.fromJson(
        Map<String, dynamic>.from(json['subscriptions'] as Map),
      ),
      todayOrders: json['today_orders'] != null
          ? OrderSummary.fromJson(Map<String, dynamic>.from(json['today_orders'] as Map))
          : null,
      milkPreparation: json['milk_preparation'] != null
          ? MilkPreparationSummary.fromJson(
              Map<String, dynamic>.from(json['milk_preparation'] as Map),
            )
          : null,
    );
  }
}

class MilkPreparationSummary {
  const MilkPreparationSummary({
    required this.date,
    required this.morning,
    required this.evening,
  });

  final String date;
  /// Cards for the morning shift — one per active container type.
  final List<MilkPreparationContainerCard> morning;
  /// Cards for the evening shift — one per active container type.
  final List<MilkPreparationContainerCard> evening;

  double get morningTotalLiters =>
      morning.fold(0, (sum, c) => sum + c.totalLiters);

  double get eveningTotalLiters =>
      evening.fold(0, (sum, c) => sum + c.totalLiters);

  factory MilkPreparationSummary.fromJson(Map<String, dynamic> json) {
    List<MilkPreparationContainerCard> _parseCards(Object? raw) {
      if (raw is List) {
        return raw
            .map((e) => MilkPreparationContainerCard.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    }

    return MilkPreparationSummary(
      date: json['date'] as String? ?? '',
      morning: _parseCards(json['morning']),
      evening: _parseCards(json['evening']),
    );
  }
}

/// One card per container type per shift.
class MilkPreparationContainerCard {
  const MilkPreparationContainerCard({
    required this.containerTypeId,
    required this.containerTypeName,
    required this.totalLiters,
    required this.sizes,
    required this.products,
    required this.totals,
  });

  final int containerTypeId;
  final String containerTypeName;
  final double totalLiters;
  final List<MilkPreparationSizeColumn> sizes;
  final List<MilkPreparationProductRow> products;
  final Map<String, int> totals;

  bool get hasAnyContainers => totals.values.any((count) => count > 0);

  factory MilkPreparationContainerCard.fromJson(Map<String, dynamic> json) {
    final sizeList = json['sizes'] as List<dynamic>? ?? [];
    final productList = json['products'] as List<dynamic>? ?? [];
    final totalsMap = Map<String, dynamic>.from(json['totals'] as Map? ?? {});

    return MilkPreparationContainerCard(
      containerTypeId: (json['container_type_id'] as num?)?.toInt() ?? 0,
      containerTypeName: json['container_type_name'] as String? ?? '',
      totalLiters: (json['total_liters'] as num?)?.toDouble() ?? 0,
      sizes: sizeList
          .map((e) =>
              MilkPreparationSizeColumn.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      products: productList
          .map((e) =>
              MilkPreparationProductRow.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      totals: totalsMap.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
    );
  }
}

class MilkPreparationSizeColumn {
  const MilkPreparationSizeColumn({required this.key, required this.label});

  final String key;
  final String label;

  factory MilkPreparationSizeColumn.fromJson(Map<String, dynamic> json) {
    return MilkPreparationSizeColumn(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}

class MilkPreparationProductRow {
  const MilkPreparationProductRow({
    required this.productId,
    required this.productName,
    required this.totalLiters,
    required this.counts,
  });

  final int productId;
  final String productName;
  final double totalLiters;
  final Map<String, int> counts;

  factory MilkPreparationProductRow.fromJson(Map<String, dynamic> json) {
    final countsMap = Map<String, dynamic>.from(json['counts'] as Map? ?? {});

    return MilkPreparationProductRow(
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      productName: json['product_name'] as String? ?? '',
      totalLiters: (json['total_liters'] as num?)?.toDouble() ??
          (json['total_litres'] as num?)?.toDouble() ?? 0,
      counts: countsMap.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0)),
    );
  }
}

class CountBreakdown {
  const CountBreakdown({
    required this.total,
    required this.active,
    required this.inactive,
    required this.onVacation,
  });

  final int total;
  final int active;
  final int inactive;
  final int onVacation;

  factory CountBreakdown.fromJson(Map<String, dynamic> json) {
    return CountBreakdown(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      inactive: (json['inactive'] as num?)?.toInt() ?? 0,
      onVacation: (json['on_vacation'] as num?)?.toInt() ?? 0,
    );
  }
}

class SubscriptionBreakdown {
  const SubscriptionBreakdown({
    required this.total,
    required this.active,
    required this.paused,
  });

  final int total;
  final int active;
  final int paused;

  factory SubscriptionBreakdown.fromJson(Map<String, dynamic> json) {
    return SubscriptionBreakdown(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      paused: (json['paused'] as num?)?.toInt() ?? 0,
    );
  }
}

enum CustomerDisplayStatus { active, inactive, vacation }

enum CustomerSort { nameAsc, nameDesc, updatedDesc, updatedAsc }

enum CustomerStatusFilter { all, active, inactive }

class OwnerCustomer {
  const OwnerCustomer({
    required this.id,
    required this.fullName,
    required this.shortAddress,
    required this.displayStatus,
    required this.isActive,
    required this.subscriptionCount,
    required this.updatedAt,
    this.vacationStart,
    this.vacationEnd,
  });

  final int id;
  final String fullName;
  final String shortAddress;
  final CustomerDisplayStatus displayStatus;
  final bool isActive;
  final int subscriptionCount;
  final DateTime? updatedAt;
  final DateTime? vacationStart;
  final DateTime? vacationEnd;

  bool get toggleOn =>
      isActive || displayStatus == CustomerDisplayStatus.vacation;

  factory OwnerCustomer.fromJson(Map<String, dynamic> json) {
    return OwnerCustomer(
      id: (json['id'] as num).toInt(),
      fullName: json['full_name'] as String? ?? '',
      shortAddress: json['short_address'] as String? ?? json['address_line'] as String? ?? '',
      displayStatus: _statusFrom(json['display_status'] as String? ?? 'active'),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      subscriptionCount: (json['subscription_count'] as num?)?.toInt() ?? 0,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      vacationStart: json['vacation_start'] != null
          ? DateTime.tryParse(json['vacation_start'] as String)
          : null,
      vacationEnd: json['vacation_end'] != null
          ? DateTime.tryParse(json['vacation_end'] as String)
          : null,
    );
  }

  static CustomerDisplayStatus _statusFrom(String value) {
    return switch (value) {
      'inactive' => CustomerDisplayStatus.inactive,
      'vacation' => CustomerDisplayStatus.vacation,
      _ => CustomerDisplayStatus.active,
    };
  }
}

class ShiftCountBreakdown {
  const ShiftCountBreakdown({
    required this.active,
    required this.inactive,
  });

  final int active;
  final int inactive;

  factory ShiftCountBreakdown.fromJson(Map<String, dynamic> json) {
    return ShiftCountBreakdown(
      active: (json['active'] as num?)?.toInt() ?? 0,
      inactive: (json['inactive'] as num?)?.toInt() ?? 0,
    );
  }
}

class CustomersListResult {
  const CustomersListResult({
    required this.summary,
    required this.customers,
    this.morning,
    this.evening,
  });

  final CountBreakdown summary;
  final List<OwnerCustomer> customers;
  final ShiftCountBreakdown? morning;
  final ShiftCountBreakdown? evening;

  factory CustomersListResult.fromJson(Map<String, dynamic> json) {
    final list = json['customers'] as List<dynamic>? ?? [];
    final summaryMap = Map<String, dynamic>.from(json['summary'] as Map? ?? {});
    final customers = <OwnerCustomer>[];
    for (final item in list) {
      if (item is! Map) continue;
      try {
        customers.add(OwnerCustomer.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {
        // Skip malformed rows instead of failing the whole list.
      }
    }
    return CustomersListResult(
      summary: CountBreakdown.fromJson(summaryMap),
      customers: customers,
      morning: summaryMap['morning'] != null
          ? ShiftCountBreakdown.fromJson(
              Map<String, dynamic>.from(summaryMap['morning'] as Map),
            )
          : null,
      evening: summaryMap['evening'] != null
          ? ShiftCountBreakdown.fromJson(
              Map<String, dynamic>.from(summaryMap['evening'] as Map),
            )
          : null,
    );
  }
}

class CustomersQuery {
  const CustomersQuery({
    this.search = '',
    this.status = CustomerStatusFilter.all,
    this.sort = CustomerSort.nameAsc,
    this.productId,
  });

  final String search;
  final CustomerStatusFilter status;
  final CustomerSort sort;
  final int? productId;

  String get statusParam => switch (status) {
        CustomerStatusFilter.active => 'active',
        CustomerStatusFilter.inactive => 'inactive',
        _ => 'all',
      };

  String get sortParam => switch (sort) {
        CustomerSort.nameDesc => 'name_desc',
        CustomerSort.updatedDesc => 'updated_desc',
        CustomerSort.updatedAsc => 'updated_asc',
        _ => 'name_asc',
      };

  @override
  bool operator ==(Object other) =>
      other is CustomersQuery &&
      other.search == search &&
      other.status == status &&
      other.sort == sort &&
      other.productId == productId;

  @override
  int get hashCode => Object.hash(search, status, sort, productId);
}

enum DeliveryShiftFilter { all, morning, evening }

enum OrderStatusFilter { all, pending, delivered, skipped }

enum InvoiceStatusFilter { all, issued, partial, paid }

class OrderSummary {
  const OrderSummary({
    required this.total,
    required this.pending,
    required this.delivered,
    required this.skipped,
    this.litresToDeliver,
  });

  final int total;
  final int pending;
  final int delivered;
  final int skipped;
  final double? litresToDeliver;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      delivered: (json['delivered'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
      litresToDeliver: (json['litres_to_deliver'] as num?)?.toDouble(),
    );
  }
}

class DailyOrder {
  const DailyOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.shortAddress = '',
    required this.productName,
    required this.quantity,
    required this.subscribedQuantity,
    required this.unitRate,
    required this.lineTotal,
    required this.shift,
    required this.shiftLabel,
    required this.status,
    required this.statusLabel,
    required this.deliveryDate,
  });

  final int id;
  final int customerId;
  final String customerName;
  final String shortAddress;
  final String productName;
  final double quantity;
  final double subscribedQuantity;
  final double unitRate;
  final double lineTotal;
  final String shift;
  final String shiftLabel;
  final String status;
  final String statusLabel;
  final String deliveryDate;

  factory DailyOrder.fromJson(Map<String, dynamic> json) {
    return DailyOrder(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      customerName: json['customer_name'] as String? ?? '',
      shortAddress: json['short_address'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      subscribedQuantity: (json['subscribed_quantity'] as num?)?.toDouble() ??
          (json['quantity'] as num?)?.toDouble() ??
          0,
      unitRate: (json['unit_rate'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0,
      shift: json['shift'] as String? ?? 'morning',
      shiftLabel: json['shift_label'] as String? ?? 'Morning',
      status: json['status'] as String? ?? 'pending',
      statusLabel: json['status_label'] as String? ?? 'Pending',
      deliveryDate: json['delivery_date'] as String? ?? '',
    );
  }
}

class DailyOrdersResult {
  const DailyOrdersResult({
    required this.date,
    required this.summary,
    required this.orders,
  });

  final String date;
  final OrderSummary summary;
  final List<DailyOrder> orders;

  factory DailyOrdersResult.fromJson(Map<String, dynamic> json) {
    final list = json['orders'] as List<dynamic>? ?? [];
    return DailyOrdersResult(
      date: json['date'] as String? ?? '',
      summary: OrderSummary.fromJson(Map<String, dynamic>.from(json['summary'] as Map? ?? {})),
      orders: list.map((e) => DailyOrder.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}

class DailyOrdersQuery {
  const DailyOrdersQuery({
    required this.date,
    this.shift = DeliveryShiftFilter.all,
    this.status = OrderStatusFilter.all,
    this.productId,
  });

  final DateTime date;
  final DeliveryShiftFilter shift;
  final OrderStatusFilter status;
  final int? productId;

  String get dateParam =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String get shiftParam => switch (shift) {
        DeliveryShiftFilter.morning => 'morning',
        DeliveryShiftFilter.evening => 'evening',
        _ => 'all',
      };

  String get statusParam => switch (status) {
        OrderStatusFilter.pending => 'pending',
        OrderStatusFilter.delivered => 'delivered',
        OrderStatusFilter.skipped => 'skipped',
        _ => 'all',
      };

  @override
  bool operator ==(Object other) =>
      other is DailyOrdersQuery &&
      other.dateParam == dateParam &&
      other.shift == shift &&
      other.status == status &&
      other.productId == productId;

  @override
  int get hashCode => Object.hash(dateParam, shift, status, productId);
}

class BillingSummary {
  const BillingSummary({
    required this.total,
    required this.paid,
    required this.partial,
    required this.unpaid,
    required this.totalAmount,
    required this.collected,
    required this.outstanding,
  });

  final int total;
  final int paid;
  final int partial;
  final int unpaid;
  final double totalAmount;
  final double collected;
  final double outstanding;

  factory BillingSummary.fromJson(Map<String, dynamic> json) {
    return BillingSummary(
      total: (json['total'] as num?)?.toInt() ?? 0,
      paid: (json['paid'] as num?)?.toInt() ?? 0,
      partial: (json['partial'] as num?)?.toInt() ?? 0,
      unpaid: (json['unpaid'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      collected: (json['collected'] as num?)?.toDouble() ?? 0,
      outstanding: (json['outstanding'] as num?)?.toDouble() ?? 0,
    );
  }
}

class GenerateOrdersResult {
  const GenerateOrdersResult({required this.created});
  final int created;
}

class OwnerInvoice {
  const OwnerInvoice({
    required this.id,
    required this.customerId,
    required this.customerName,
    this.customerAddress = '',
    required this.billingMonth,
    required this.invoiceNumber,
    required this.totalAmount,
    required this.amountPaid,
    required this.balanceDue,
    required this.status,
    required this.statusLabel,
    this.issuedAt,
    this.dueDate,
    this.sentAt,
    this.sentLabel,
    this.sentVia,
  });

  final int id;
  final int customerId;
  final String customerName;
  final String customerAddress;
  final String billingMonth;
  final String invoiceNumber;
  final double totalAmount;
  final double amountPaid;
  final double balanceDue;
  final String status;
  final String statusLabel;
  final DateTime? issuedAt;
  final DateTime? dueDate;
  final DateTime? sentAt;
  final String? sentLabel;
  final String? sentVia;

  factory OwnerInvoice.fromJson(Map<String, dynamic> json) {
    return OwnerInvoice(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      customerName: json['customer_name'] as String? ?? '',
      customerAddress: json['customer_address'] as String? ?? '',
      billingMonth: json['billing_month'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0,
      balanceDue: (json['balance_due'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'issued',
      statusLabel: json['status_label'] as String? ?? 'Issued',
      issuedAt: json['issued_at'] != null ? DateTime.tryParse(json['issued_at'] as String) : null,
      dueDate: json['due_date'] != null ? DateTime.tryParse(json['due_date'] as String) : null,
      sentAt: json['sent_at'] != null ? DateTime.tryParse(json['sent_at'] as String) : null,
      sentLabel: json['sent_label'] as String?,
      sentVia: json['sent_via'] as String?,
    );
  }
}

class BulkInvoiceSendResult {
  const BulkInvoiceSendResult({
    required this.billingMonth,
    required this.sentCount,
    required this.failedCount,
    required this.skippedCount,
    required this.message,
  });

  final String billingMonth;
  final int sentCount;
  final int failedCount;
  final int skippedCount;
  final String message;

  factory BulkInvoiceSendResult.fromJson(Map<String, dynamic> json) {
    final sent = json['sent_count'] as int? ?? 0;
    final failed = json['failed_count'] as int? ?? 0;
    final skipped = json['skipped_count'] as int? ?? 0;

    return BulkInvoiceSendResult(
      billingMonth: json['billing_month'] as String? ?? '',
      sentCount: sent,
      failedCount: failed,
      skippedCount: skipped,
      message: 'Sent $sent · Skipped $skipped · Failed $failed',
    );
  }
}

class InvoicesListResult {
  const InvoicesListResult({
    required this.billingMonth,
    required this.summary,
    required this.invoices,
  });

  final String billingMonth;
  final BillingSummary summary;
  final List<OwnerInvoice> invoices;

  factory InvoicesListResult.fromJson(Map<String, dynamic> json) {
    final list = json['invoices'] as List<dynamic>? ?? [];
    return InvoicesListResult(
      billingMonth: json['billing_month'] as String? ?? '',
      summary: BillingSummary.fromJson(Map<String, dynamic>.from(json['summary'] as Map? ?? {})),
      invoices: list.map((e) => OwnerInvoice.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}

class InvoicesQuery {
  const InvoicesQuery({
    required this.billingMonth,
    this.status = InvoiceStatusFilter.all,
  });

  final DateTime billingMonth;
  final InvoiceStatusFilter status;

  String get billingMonthParam =>
      '${billingMonth.year.toString().padLeft(4, '0')}-${billingMonth.month.toString().padLeft(2, '0')}';

  String get statusParam => switch (status) {
        InvoiceStatusFilter.issued => 'issued',
        InvoiceStatusFilter.partial => 'partial',
        InvoiceStatusFilter.paid => 'paid',
        _ => 'all',
      };

  @override
  bool operator ==(Object other) =>
      other is InvoicesQuery && other.billingMonthParam == billingMonthParam && other.status == status;

  @override
  int get hashCode => Object.hash(billingMonthParam, status);
}

class InvoiceLine {
  const InvoiceLine({
    required this.productName,
    required this.shiftLabel,
    required this.deliveryDays,
    required this.totalQuantity,
    required this.unitRate,
    required this.lineTotal,
  });

  final String productName;
  final String shiftLabel;
  final int deliveryDays;
  final double totalQuantity;
  final double unitRate;
  final double lineTotal;

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    return InvoiceLine(
      productName: json['product_name'] as String? ?? '',
      shiftLabel: json['shift_label'] as String? ?? '',
      deliveryDays: (json['delivery_days'] as num?)?.toInt() ?? 0,
      totalQuantity: (json['total_quantity'] as num?)?.toDouble() ?? 0,
      unitRate: (json['unit_rate'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class OwnerPayment {
  const OwnerPayment({
    required this.id,
    required this.customerName,
    required this.invoiceNumber,
    required this.amount,
    required this.paymentTypeLabel,
    required this.paymentMethodLabel,
    required this.paymentMethod,
    required this.paymentDate,
    this.handedTo,
    this.notes,
  });

  final int id;
  final String customerName;
  final String? invoiceNumber;
  final double amount;
  final String paymentTypeLabel;
  final String paymentMethodLabel;
  final String paymentMethod;
  final String paymentDate;
  final String? handedTo;
  final String? notes;

  factory OwnerPayment.fromJson(Map<String, dynamic> json) {
    return OwnerPayment(
      id: json['id'] as int,
      customerName: json['customer_name'] as String? ?? '',
      invoiceNumber: json['invoice_number'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentTypeLabel: json['payment_type_label'] as String? ?? '',
      paymentMethodLabel: json['payment_method_label'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? '',
      paymentDate: json['payment_date'] as String? ?? '',
      handedTo: json['handed_to'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class InvoiceDetailResult {
  const InvoiceDetailResult({
    required this.invoice,
    required this.lines,
    required this.payments,
  });

  final OwnerInvoice invoice;
  final List<InvoiceLine> lines;
  final List<OwnerPayment> payments;

  factory InvoiceDetailResult.fromJson(Map<String, dynamic> json) {
    final lineList = json['lines'] as List<dynamic>? ?? [];
    final payList = json['payments'] as List<dynamic>? ?? [];
    return InvoiceDetailResult(
      invoice: OwnerInvoice.fromJson(Map<String, dynamic>.from(json['invoice'] as Map)),
      lines: lineList.map((e) => InvoiceLine.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      payments: payList.map((e) => OwnerPayment.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}

class PaymentsListResult {
  const PaymentsListResult({
    required this.billingMonth,
    required this.totalCollected,
    required this.payments,
  });

  final String billingMonth;
  final double totalCollected;
  final List<OwnerPayment> payments;

  factory PaymentsListResult.fromJson(Map<String, dynamic> json) {
    final list = json['payments'] as List<dynamic>? ?? [];
    final summary = Map<String, dynamic>.from(json['summary'] as Map? ?? {});
    return PaymentsListResult(
      billingMonth: json['billing_month'] as String? ?? '',
      totalCollected: (summary['total_collected'] as num?)?.toDouble() ?? 0,
      payments: list.map((e) => OwnerPayment.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }
}

class PaymentsQuery {
  const PaymentsQuery({
    required this.billingMonth,
    this.paymentMethod = PaymentMethodFilter.all,
  });

  final DateTime billingMonth;
  final PaymentMethodFilter paymentMethod;

  String get billingMonthParam =>
      '${billingMonth.year.toString().padLeft(4, '0')}-${billingMonth.month.toString().padLeft(2, '0')}';

  String get paymentMethodParam => switch (paymentMethod) {
        PaymentMethodFilter.cash => 'cash',
        PaymentMethodFilter.upi => 'upi',
        PaymentMethodFilter.bankTransfer => 'bank_transfer',
        PaymentMethodFilter.other => 'other',
        _ => 'all',
      };

  @override
  bool operator ==(Object other) =>
      other is PaymentsQuery &&
      other.billingMonthParam == billingMonthParam &&
      other.paymentMethod == paymentMethod;

  @override
  int get hashCode => Object.hash(billingMonthParam, paymentMethod);
}

enum PaymentMethodFilter { all, cash, upi, bankTransfer, other }

class CustomerUpdateRequest {
  const CustomerUpdateRequest({
    this.isActive,
    this.vacationStart,
    this.vacationEnd,
    this.clearVacation = false,
    this.firstName,
    this.lastName,
    this.addressLine,
    this.area,
    this.landmark,
    this.city,
    this.state,
    this.zip,
    this.contact,
    this.whatsappEnabled,
    this.secondaryContact,
    this.deliveryType,
  });

  final bool? isActive;
  final DateTime? vacationStart;
  final DateTime? vacationEnd;
  final bool clearVacation;
  final String? firstName;
  final String? lastName;
  final String? addressLine;
  final String? area;
  final String? landmark;
  final String? city;
  final String? state;
  final String? zip;
  final String? contact;
  final bool? whatsappEnabled;
  final String? secondaryContact;
  /// 'home_delivery' or 'walk_in'
  final String? deliveryType;

  Map<String, dynamic> toJson() {
    if (clearVacation) {
      return {
        'vacation_start': null,
        'vacation_end': null,
        if (isActive != null) 'is_active': isActive,
      };
    }

    return {
      if (isActive != null) 'is_active': isActive,
      if (vacationStart != null)
        'vacation_start':
            '${vacationStart!.year}-${vacationStart!.month.toString().padLeft(2, '0')}-${vacationStart!.day.toString().padLeft(2, '0')}',
      if (vacationEnd != null)
        'vacation_end':
            '${vacationEnd!.year}-${vacationEnd!.month.toString().padLeft(2, '0')}-${vacationEnd!.day.toString().padLeft(2, '0')}',
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (addressLine != null) 'address_line': addressLine,
      if (area != null) 'area': area,
      if (landmark != null) 'landmark': landmark,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (zip != null) 'zip': zip,
      if (contact != null) 'contact': contact,
      if (whatsappEnabled != null) 'whatsapp_enabled': whatsappEnabled,
      if (secondaryContact != null) 'secondary_contact': secondaryContact,
      if (deliveryType != null) 'delivery_type': deliveryType,
    };
  }
}

class SubscriptionLineUpdateRequest {
  const SubscriptionLineUpdateRequest({
    required this.productId,
    required this.quantity,
    required this.shift,
    this.couponAmount = 0,
  });

  final int productId;
  final double quantity;
  final String shift;
  final double couponAmount;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
        'coupon_amount': couponAmount,
        'shift': shift,
      };
}

class CreateSubscriptionRequest {
  const CreateSubscriptionRequest({
    required this.customerId,
    required this.lines,
  });

  final int customerId;
  final List<SubscriptionLineUpdateRequest> lines;

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'lines': lines.map((l) => l.toJson()).toList(),
      };
}

class DeliveryLogUpdateEntry {
  const DeliveryLogUpdateEntry({
    required this.date,
    this.morning,
    this.evening,
  });

  final String date;
  final double? morning;
  final double? evening;

  Map<String, dynamic> toJson() => {
        'date': date,
        if (morning != null) 'morning': morning,
        if (evening != null) 'evening': evening,
      };
}

class CustomerDetailQuery {
  const CustomerDetailQuery({
    required this.customerId,
    required this.billingMonth,
  });

  final int customerId;
  final DateTime billingMonth;

  String get billingMonthParam =>
      '${billingMonth.year.toString().padLeft(4, '0')}-${billingMonth.month.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is CustomerDetailQuery &&
      other.customerId == customerId &&
      other.billingMonthParam == billingMonthParam;

  @override
  int get hashCode => Object.hash(customerId, billingMonthParam);
}

class CustomerDetailInfo {
  const CustomerDetailInfo({
    required this.id,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.contact,
    required this.shortAddress,
    required this.fullAddress,
    required this.addressLine,
    required this.area,
    required this.landmark,
    required this.city,
    required this.state,
    required this.zip,
    required this.whatsappEnabled,
    required this.isActive,
    required this.displayStatus,
    this.deliveryType = 'home_delivery',
    this.secondaryContact,
    this.vacationStart,
    this.vacationEnd,
  });

  final int id;
  final String fullName;
  final String firstName;
  final String lastName;
  final String contact;
  final String shortAddress;
  final String fullAddress;
  final String addressLine;
  final String area;
  final String landmark;
  final String city;
  final String state;
  final String zip;
  final bool whatsappEnabled;
  final bool isActive;
  final CustomerDisplayStatus displayStatus;
  final String deliveryType;
  final String? secondaryContact;
  final String? vacationStart;
  final String? vacationEnd;

  bool get isWalkIn => deliveryType == 'walk_in';

  factory CustomerDetailInfo.fromJson(Map<String, dynamic> json) {
    final parts = [
      json['address_line'],
      json['area'],
      json['landmark'],
      json['city'],
      json['state'],
      json['zip'],
    ].whereType<String>().where((s) => s.isNotEmpty);

    return CustomerDetailInfo(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      contact: json['contact'] as String? ?? '',
      shortAddress: json['short_address'] as String? ?? '',
      fullAddress: parts.join(', '),
      addressLine: json['address_line'] as String? ?? '',
      area: json['area'] as String? ?? '',
      landmark: json['landmark'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zip: json['zip'] as String? ?? '',
      whatsappEnabled: json['whatsapp_enabled'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      deliveryType: json['delivery_type'] as String? ?? 'home_delivery',
      secondaryContact: json['secondary_contact'] as String?,
      displayStatus: OwnerCustomer._statusFrom(json['display_status'] as String? ?? 'active'),
      vacationStart: json['vacation_start'] as String?,
      vacationEnd: json['vacation_end'] as String?,
    );
  }
}

class SubscriptionLineDetail {
  const SubscriptionLineDetail({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitRate,
    required this.couponAmount,
    required this.effectiveRate,
    required this.shift,
    required this.shiftLabel,
    required this.quantity,
    this.dailyOrders = const [],
  });

  final int id;
  final int productId;
  final String productName;
  final double unitRate;
  final double couponAmount;
  final double effectiveRate;
  final String shift;
  final String shiftLabel;
  final double quantity;
  final List<SubscriptionDayOrder> dailyOrders;

  factory SubscriptionLineDetail.fromJson(Map<String, dynamic> json) {
    final orderList = json['daily_orders'] as List<dynamic>? ?? [];
    return SubscriptionLineDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['product_id'] as num?)?.toInt() ?? 0,
      productName: json['product_name'] as String? ?? '',
      unitRate: (json['unit_rate'] as num?)?.toDouble() ?? 0,
      couponAmount: (json['coupon_amount'] as num?)?.toDouble() ?? 0,
      effectiveRate: (json['effective_rate'] as num?)?.toDouble() ?? 0,
      shift: json['shift'] as String? ?? 'morning',
      shiftLabel: json['shift_label'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      dailyOrders: orderList
          .map((e) => SubscriptionDayOrder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class SubscriptionDayOrder {
  const SubscriptionDayOrder({
    required this.date,
    this.morning,
    this.evening,
    this.hasDelivery = true,
  });

  final String date;
  final double? morning;
  final double? evening;
  final bool hasDelivery;

  factory SubscriptionDayOrder.fromJson(Map<String, dynamic> json) {
    return SubscriptionDayOrder(
      date: json['date'] as String? ?? '',
      morning: (json['morning'] as num?)?.toDouble(),
      evening: (json['evening'] as num?)?.toDouble(),
      hasDelivery: json['has_delivery'] as bool? ?? true,
    );
  }
}

class CustomerSubscriptionDetail {
  const CustomerSubscriptionDetail({
    required this.id,
    required this.status,
    required this.lines,
    required this.dailyOrders,
  });

  final int id;
  final String status;
  final List<SubscriptionLineDetail> lines;
  final List<SubscriptionDayOrder> dailyOrders;

  factory CustomerSubscriptionDetail.fromJson(Map<String, dynamic> json) {
    final lineList = json['lines'] as List<dynamic>? ?? [];
    final orderList = json['daily_orders'] as List<dynamic>? ?? [];
    return CustomerSubscriptionDetail(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'active',
      lines: lineList
          .map((e) => SubscriptionLineDetail.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      dailyOrders: orderList
          .map((e) => SubscriptionDayOrder.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class ConsumptionSummary {
  const ConsumptionSummary({
    required this.billingMonth,
    required this.rows,
    required this.grandTotal,
  });

  final String billingMonth;
  final List<ConsumptionRow> rows;
  final double grandTotal;

  factory ConsumptionSummary.fromJson(Map<String, dynamic> json) {
    final list = json['rows'] as List<dynamic>? ?? [];
    return ConsumptionSummary(
      billingMonth: json['billing_month'] as String? ?? '',
      rows: list.map((e) => ConsumptionRow.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class ConsumptionRow {
  const ConsumptionRow({
    required this.productName,
    required this.unitRate,
    required this.totalQuantity,
    required this.lineTotal,
  });

  final String productName;
  final double unitRate;
  final double totalQuantity;
  final double lineTotal;

  factory ConsumptionRow.fromJson(Map<String, dynamic> json) {
    return ConsumptionRow(
      productName: json['product_name'] as String? ?? '',
      unitRate: parseApiDouble(json['unit_rate']),
      totalQuantity: parseApiDouble(json['total_quantity']),
      lineTotal: parseApiDouble(json['line_total']),
    );
  }
}

class CustomerDetailResult {
  const CustomerDetailResult({
    required this.customer,
    required this.billingMonth,
    required this.subscriptions,
    required this.consumption,
    required this.billingHistory,
    required this.payments,
  });

  final CustomerDetailInfo customer;
  final String billingMonth;
  final List<CustomerSubscriptionDetail> subscriptions;
  final ConsumptionSummary consumption;
  final List<OwnerInvoice> billingHistory;
  final List<OwnerPayment> payments;

  factory CustomerDetailResult.fromJson(Map<String, dynamic> json) {
    final subList = json['subscriptions'] as List<dynamic>? ?? [];
    final billList = json['billing_history'] as List<dynamic>? ?? [];
    final payList = json['payments'] as List<dynamic>? ?? [];
    return CustomerDetailResult(
      customer: CustomerDetailInfo.fromJson(Map<String, dynamic>.from(json['customer'] as Map)),
      billingMonth: json['billing_month'] as String? ?? '',
      subscriptions: subList
          .map((e) => CustomerSubscriptionDetail.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      consumption: ConsumptionSummary.fromJson(
        Map<String, dynamic>.from(json['consumption'] as Map? ?? {}),
      ),
      billingHistory: billList
          .map((e) => OwnerInvoice.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      payments: payList
          .map((e) => OwnerPayment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class FarmActivity {
  const FarmActivity({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.entityLabel,
    required this.createdAt,
    required this.canRestore,
    this.description,
    this.meta,
  });

  final int id;
  final String action;
  final String entityType;
  final int entityId;
  final String entityLabel;
  final String? createdAt;
  final bool canRestore;
  final String? description;
  final Map<String, dynamic>? meta;

  factory FarmActivity.fromJson(Map<String, dynamic> json) {
    return FarmActivity(
      id: json['id'] as int,
      action: json['action'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id'] as int? ?? 0,
      entityLabel: json['entity_label'] as String? ?? '',
      createdAt: json['created_at'] as String?,
      canRestore: json['can_restore'] as bool? ?? false,
      description: json['description'] as String?,
      meta: json['meta'] != null ? Map<String, dynamic>.from(json['meta'] as Map) : null,
    );
  }

  String get actionLabel => switch (action) {
        'created' => 'Added',
        'updated' => 'Updated',
        'deleted' => 'Deleted',
        'restored' => 'Restored',
        'sent' => 'Sent',
        _ => action,
      };

  String get entityTypeLabel => switch (entityType) {
        'customer' => 'Customer',
        'subscription' => 'Subscription',
        'subscription_line' => 'Subscription',
        'payment' => 'Payment',
        'invoice' => 'Bill',
        'product' => 'Product',
        _ => entityType,
      };

  String get displayText => description ?? '$actionLabel · $entityTypeLabel';
}

enum CommunicationSort {
  newest,
  oldest,
  customerAsc,
  customerDesc,
}

class CommunicationsQuery {
  const CommunicationsQuery({
    this.search = '',
    this.status = '',
  });

  final String search;
  final String status;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunicationsQuery &&
          other.search == search &&
          other.status == status;

  @override
  int get hashCode => Object.hash(search, status);
}

class CommunicationMessage {
  const CommunicationMessage({
    required this.id,
    this.customerId,
    this.customerName,
    required this.recipientMobile,
    required this.messageType,
    this.templateName,
    this.preview,
    required this.status,
    this.failureReason,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.failedAt,
    this.createdAt,
  });

  final int id;
  final int? customerId;
  final String? customerName;
  final String recipientMobile;
  final String messageType;
  final String? templateName;
  final String? preview;
  final String status;
  final String? failureReason;
  final String? sentAt;
  final String? deliveredAt;
  final String? readAt;
  final String? failedAt;
  final String? createdAt;

  factory CommunicationMessage.fromJson(Map<String, dynamic> json) {
    return CommunicationMessage(
      id: json['id'] as int,
      customerId: json['customer_id'] as int?,
      customerName: json['customer_name'] as String?,
      recipientMobile: json['recipient_mobile'] as String? ?? '',
      messageType: json['message_type'] as String? ?? '',
      templateName: json['template_name'] as String?,
      preview: json['preview'] as String?,
      status: json['status'] as String? ?? 'pending',
      failureReason: json['failure_reason'] as String?,
      sentAt: json['sent_at'] as String?,
      deliveredAt: json['delivered_at'] as String?,
      readAt: json['read_at'] as String?,
      failedAt: json['failed_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  String get displayName {
    final name = customerName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return recipientMobile;
  }

  String get headline => preview?.trim().isNotEmpty == true
      ? preview!.trim()
      : (templateName?.trim().isNotEmpty == true ? templateName! : typeLabel);

  String get typeLabel => switch (messageType) {
        'bill' => 'Monthly bill',
        'payment_confirmed' => 'Payment receipt',
        'order_log' => 'Order log',
        'delivery_paused' => 'Vacation set',
        'qty_change' => 'Qty change',
        'sub_resumed' => 'Subscription resumed',
        'upi_qr' => 'UPI QR',
        'otp' => 'OTP',
        _ => messageType.replaceAll('_', ' '),
      };

  String get statusLabel => switch (status) {
        'sent' => 'Sent',
        'delivered' => 'Delivered',
        'read' => 'Read',
        'failed' => 'Failed',
        'simulated' => 'Simulated',
        'pending' => 'Pending',
        _ => status,
      };

  String? get primaryTimestamp => readAt ?? deliveredAt ?? sentAt ?? createdAt;
}
