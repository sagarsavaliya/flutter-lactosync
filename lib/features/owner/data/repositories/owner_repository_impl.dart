import 'package:dio/dio.dart';



import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';

import '../../domain/entities/owner_models.dart';
import '../../domain/entities/settings_models.dart';

import '../../domain/repositories/owner_repository.dart';



class OwnerRepositoryImpl implements OwnerRepository {

  OwnerRepositoryImpl(this._dio);



  final Dio _dio;



  Map<String, dynamic> _readData(Map<String, dynamic>? body) {

    if (body == null || body['success'] != true) {

      throw ApiException('API_ERROR', 'Unexpected server response.');

    }

    return Map<String, dynamic>.from(body['data'] as Map);

  }



  @override

  Future<OwnerDashboardStats> fetchDashboard() async {

    final response = await _dio.get<Map<String, dynamic>>('/owner/dashboard');

    return OwnerDashboardStats.fromJson(_readData(response.data));

  }



  @override

  Future<CustomersListResult> fetchCustomers(CustomersQuery query) async {

    final response = await _dio.get<Map<String, dynamic>>(

      '/owner/customers',

      queryParameters: {

        if (query.search.isNotEmpty) 'search': query.search,

        'status': query.statusParam,

        'sort': query.sortParam,

      },

    );

    return CustomersListResult.fromJson(_readData(response.data));

  }



  @override

  Future<CustomerDetailResult> fetchCustomerDetail(CustomerDetailQuery query) async {

    final response = await _dio.get<Map<String, dynamic>>(

      '/owner/customers/${query.customerId}',

      queryParameters: {'billing_month': query.billingMonthParam},

    );

    return CustomerDetailResult.fromJson(_readData(response.data));

  }



  @override

  Future<OwnerCustomer> updateCustomer(int id, CustomerUpdateRequest request) async {

    final response = await _dio.patch<Map<String, dynamic>>(

      '/owner/customers/$id',

      data: request.toJson(),

    );

    return OwnerCustomer.fromJson(_readData(response.data));

  }



  @override

  Future<SubscriptionLineDetail> updateSubscriptionLine(

    int subscriptionId,

    int lineId,

    SubscriptionLineUpdateRequest request,

  ) async {

    final response = await _dio.patch<Map<String, dynamic>>(

      '/owner/subscriptions/$subscriptionId/lines/$lineId',

      data: request.toJson(),

    );

    return SubscriptionLineDetail.fromJson(_readData(response.data));

  }



  @override
  Future<DailyOrdersResult> fetchDailyOrders(DailyOrdersQuery query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/owner/daily-orders',
        queryParameters: {
          'date': query.dateParam,
          'shift': query.shiftParam,
          'status': query.statusParam,
        },
      );
      return DailyOrdersResult.fromJson(_readData(response.data));
    } catch (e) {
      throw mapDioError(e);
    }
  }



  @override

  Future<DailyOrder> updateDailyOrder(int id, {String? status, double? quantity}) async {

    final response = await _dio.patch<Map<String, dynamic>>(

      '/owner/daily-orders/$id',

      data: {

        if (status != null) 'status': status,

        if (quantity != null) 'quantity': quantity,

      },

    );

    return DailyOrder.fromJson(_readData(response.data));

  }



  @override

  Future<InvoicesListResult> fetchInvoices(InvoicesQuery query) async {

    final response = await _dio.get<Map<String, dynamic>>(

      '/owner/invoices',

      queryParameters: {

        'billing_month': query.billingMonthParam,

        'status': query.statusParam,

      },

    );

    return InvoicesListResult.fromJson(_readData(response.data));

  }



  @override
  Future<InvoiceDetailResult> fetchInvoiceDetail(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/owner/invoices/$id');
    return InvoiceDetailResult.fromJson(_readData(response.data));
  }

  @override
  Future<void> sendInvoice(int id) async {
    await _dio.post<Map<String, dynamic>>('/owner/invoices/$id/send');
  }

  @override
  Future<BulkInvoiceSendResult> sendInvoicesBulk(String billingMonth) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/owner/invoices/send-bulk',
      queryParameters: {'billing_month': billingMonth},
    );
    return BulkInvoiceSendResult.fromJson(_readData(response.data));
  }



  @override

  Future<PaymentsListResult> fetchPayments(PaymentsQuery query) async {

    final response = await _dio.get<Map<String, dynamic>>(

      '/owner/payments',

      queryParameters: {
        'billing_month': query.billingMonthParam,
        'payment_method': query.paymentMethodParam,
      },

    );

    return PaymentsListResult.fromJson(_readData(response.data));
  }

  @override
  Future<PincodeResult> lookupPincode(String pincode) async {
    final response = await _dio.get<Map<String, dynamic>>('/owner/pincode/$pincode');
    return PincodeResult.fromJson(_readData(response.data));
  }

  @override
  Future<OwnerSettings> fetchSettings() async {
    final response = await _dio.get<Map<String, dynamic>>('/owner/settings');
    return OwnerSettings.fromJson(_readData(response.data));
  }

  @override
  Future<OwnerSettings> updateSettings(OwnerSettingsUpdate update) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/owner/settings',
      data: update.toJson(),
    );
    return OwnerSettings.fromJson(_readData(response.data));
  }

  @override
  Future<SettingsProduct> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/owner/products/$id',
      data: data,
    );
    final body = _readData(response.data);
    return SettingsProduct.fromJson(Map<String, dynamic>.from(body['product'] as Map));
  }

  @override
  Future<void> deleteCustomer(int id) async {
    await _dio.delete<void>('/owner/customers/$id');
  }

  @override
  Future<void> deleteProduct(int id) async {
    await _dio.delete<void>('/owner/products/$id');
  }

  @override
  Future<void> deleteSubscriptionLine(int subscriptionId, int lineId) async {
    await _dio.delete<void>('/owner/subscriptions/$subscriptionId/lines/$lineId');
  }

  @override
  Future<void> deleteSubscription(int subscriptionId) async {
    await _dio.delete<void>('/owner/subscriptions/$subscriptionId');
  }

  @override
  Future<void> createSubscription(CreateSubscriptionRequest request) async {
    await _dio.post<Map<String, dynamic>>(
      '/owner/subscriptions',
      data: request.toJson(),
    );
  }

  @override
  Future<void> sendMilkLog({
    required int customerId,
    required String billingMonth,
    int? subscriptionLineId,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/owner/customers/$customerId/milk-log/send',
      data: {
        'billing_month': billingMonth,
        if (subscriptionLineId != null) 'subscription_line_id': subscriptionLineId,
      },
    );
  }

  @override
  Future<List<SubscriptionDayOrder>> fetchDeliveryLogGrid({
    required int customerId,
    required String billingMonth,
    required int subscriptionLineId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/owner/customers/$customerId/delivery-logs',
      queryParameters: {
        'billing_month': billingMonth,
        'subscription_line_id': subscriptionLineId,
      },
    );
    final body = _readData(response.data);
    final grid = body['grid'] as List<dynamic>? ?? [];
    return grid
        .map((e) => SubscriptionDayOrder.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> updateDeliveryLogs({
    required int customerId,
    required String billingMonth,
    required int subscriptionLineId,
    required List<DeliveryLogUpdateEntry> entries,
  }) async {
    await _dio.patch<Map<String, dynamic>>(
      '/owner/customers/$customerId/delivery-logs',
      data: {
        'billing_month': billingMonth,
        'subscription_line_id': subscriptionLineId,
        'entries': entries.map((e) => e.toJson()).toList(),
      },
    );
  }

  @override
  Future<GenerateOrdersResult> generateDailyOrders({
    required DateTime date,
    required String shift,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/owner/daily-orders/generate',
      data: {
        'date': date.toIso8601String().split('T').first,
        'shift': shift,
      },
    );
    final body = _readData(response.data);
    return GenerateOrdersResult(created: (body['created'] as num?)?.toInt() ?? 0);
  }

  @override
  Future<void> generateInvoice({
    required int customerId,
    required String billingMonth,
    bool send = false,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/owner/invoices/generate',
      data: {
        'customer_id': customerId,
        'billing_month': billingMonth,
        'send': send,
      },
    );
  }

  @override
  Future<String?> recordPayment({
    required int invoiceId,
    required double amount,
    required String paymentMethod,
    bool sendReceipt = true,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/owner/payments',
      data: {
        'invoice_id': invoiceId,
        'amount': amount,
        'payment_method': paymentMethod,
        'send_receipt': sendReceipt,
      },
    );
    final body = _readData(response.data);
    return body['receipt_error'] as String?;
  }

  @override
  Future<void> shareUpiQr({
    required int customerId,
    int? invoiceId,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/owner/payments/share-upi-qr',
      data: {
        'customer_id': customerId,
        if (invoiceId != null) 'invoice_id': invoiceId,
      },
    );
  }

  @override
  Future<List<FarmActivity>> fetchActivities() async {
    final response = await _dio.get<Map<String, dynamic>>('/owner/activities');
    final body = _readData(response.data);
    final list = body['activities'] as List<dynamic>? ?? [];
    return list
        .map((e) => FarmActivity.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> restoreActivity(int activityLogId) async {
    await _dio.post<Map<String, dynamic>>('/owner/activities/$activityLogId/restore');
  }

  // ── Milk types ────────────────────────────────────────────────────────────

  @override
  Future<List<MilkTypeItem>> fetchMilkTypes() async {
    final response = await _dio.get<Map<String, dynamic>>('/owner/milk-types');
    final body = _readData(response.data);
    final list = body['milk_types'] as List<dynamic>? ?? [];
    return list
        .map((e) => MilkTypeItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<MilkTypeItem> addMilkType(String name) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/owner/milk-types',
      data: {'name': name},
    );
    return MilkTypeItem.fromJson(_readData(response.data));
  }

  @override
  Future<void> deleteMilkType(int id) async {
    await _dio.delete<void>('/owner/milk-types/$id');
  }

  @override
  Future<void> hideMilkType(int id) async {
    await _dio.post<Map<String, dynamic>>('/owner/milk-types/$id/hide');
  }

  @override
  Future<void> unhideMilkType(int id) async {
    await _dio.delete<void>('/owner/milk-types/$id/hide');
  }

  // ── Container types ───────────────────────────────────────────────────────

  @override
  Future<List<ContainerTypeItem>> fetchContainerTypes() async {
    final response = await _dio.get<Map<String, dynamic>>('/owner/container-types');
    final body = _readData(response.data);
    final list = body['container_types'] as List<dynamic>? ?? [];
    return list
        .map((e) => ContainerTypeItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<ContainerTypeItem> addContainerType({
    required String material,
    required String size,
  }) async {
    // Map material slug to display label for the composite name
    final materialLabel = material == 'glass_bottle' ? 'Glass Bottle' : 'Plastic Bag';
    final name = '$materialLabel $size';
    final response = await _dio.post<Map<String, dynamic>>(
      '/owner/container-types',
      data: {'name': name},
    );
    return ContainerTypeItem.fromJson(_readData(response.data));
  }

  @override
  Future<void> deleteContainerType(int id) async {
    await _dio.delete<void>('/owner/container-types/$id');
  }

  @override
  Future<void> hideContainerType(int id) async {
    await _dio.post<Map<String, dynamic>>('/owner/container-types/$id/hide');
  }

  @override
  Future<void> unhideContainerType(int id) async {
    await _dio.delete<void>('/owner/container-types/$id/hide');
  }
}

