import '../entities/owner_models.dart';
import '../entities/settings_models.dart';



abstract class OwnerRepository {

  Future<OwnerDashboardStats> fetchDashboard();



  Future<CustomersListResult> fetchCustomers(CustomersQuery query);

  Future<CustomerDetailResult> fetchCustomerDetail(CustomerDetailQuery query);

  Future<OwnerCustomer> updateCustomer(int id, CustomerUpdateRequest request);

  Future<void> deleteCustomer(int id);

  Future<SubscriptionLineDetail> updateSubscriptionLine(
    int subscriptionId,
    int lineId,
    SubscriptionLineUpdateRequest request,
  );



  Future<DailyOrdersResult> fetchDailyOrders(DailyOrdersQuery query);



  Future<DailyOrder> updateDailyOrder(int id, {String? status, double? quantity});



  Future<InvoicesListResult> fetchInvoices(InvoicesQuery query);



  Future<InvoiceDetailResult> fetchInvoiceDetail(int id);

  Future<void> sendInvoice(int id);

  Future<BulkInvoiceSendResult> sendInvoicesBulk(String billingMonth);



  Future<PaymentsListResult> fetchPayments(PaymentsQuery query);

  Future<PincodeResult> lookupPincode(String pincode);

  Future<OwnerSettings> fetchSettings();

  Future<OwnerSettings> updateSettings(OwnerSettingsUpdate update);

  Future<SettingsProduct> updateProduct(int id, Map<String, dynamic> data);

  Future<void> deleteProduct(int id);

  Future<void> deleteSubscriptionLine(int subscriptionId, int lineId);

  Future<void> deleteSubscription(int subscriptionId);

  Future<void> createSubscription(CreateSubscriptionRequest request);

  Future<void> sendMilkLog({
    required int customerId,
    required String billingMonth,
    int? subscriptionLineId,
  });

  Future<List<SubscriptionDayOrder>> fetchDeliveryLogGrid({
    required int customerId,
    required String billingMonth,
    required int subscriptionLineId,
  });

  Future<void> updateDeliveryLogs({
    required int customerId,
    required String billingMonth,
    required int subscriptionLineId,
    required List<DeliveryLogUpdateEntry> entries,
  });

  Future<GenerateOrdersResult> generateDailyOrders({
    required DateTime date,
    required String shift,
  });

  Future<void> generateInvoice({
    required int customerId,
    required String billingMonth,
    bool send = false,
  });

  /// Records payment. Returns WhatsApp receipt error message when payment saved but receipt failed.
  Future<String?> recordPayment({
    required int invoiceId,
    required double amount,
    required String paymentMethod,
    bool sendReceipt = true,
  });

  Future<void> shareUpiQr({
    required int customerId,
    int? invoiceId,
  });

  Future<List<FarmActivity>> fetchActivities();

  Future<void> restoreActivity(int activityLogId);

  // ── Milk types ────────────────────────────────────────────────────────────
  Future<List<MilkTypeItem>> fetchMilkTypes();
  Future<MilkTypeItem> addMilkType(String name);
  Future<void> deleteMilkType(int id);
  Future<void> hideMilkType(int id);
  Future<void> unhideMilkType(int id);

  // ── Container types ───────────────────────────────────────────────────────
  Future<List<ContainerTypeItem>> fetchContainerTypes();
  Future<ContainerTypeItem> addContainerType({required String material, required String size});
  Future<void> deleteContainerType(int id);
  Future<void> hideContainerType(int id);
  Future<void> unhideContainerType(int id);
}

