import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../../../core/network/dio_provider.dart';

import '../../data/repositories/owner_repository_impl.dart';

import '../../domain/entities/owner_models.dart';
import '../../domain/entities/settings_models.dart';

import '../../domain/repositories/owner_repository.dart';



final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {

  return OwnerRepositoryImpl(ref.watch(dioProvider));

});



final ownerDashboardProvider = FutureProvider.autoDispose<OwnerDashboardStats>((ref) {

  return ref.watch(ownerRepositoryProvider).fetchDashboard();

});



final customersListProvider =

    FutureProvider.autoDispose.family<CustomersListResult, CustomersQuery>((ref, query) {

  return ref.watch(ownerRepositoryProvider).fetchCustomers(query);

});



final dailyOrdersProvider =
    FutureProvider.autoDispose.family<DailyOrdersResult, DailyOrdersQuery>((ref, query) {
  return ref.read(ownerRepositoryProvider).fetchDailyOrders(query);
});



final invoicesListProvider =

    FutureProvider.autoDispose.family<InvoicesListResult, InvoicesQuery>((ref, query) {

  return ref.watch(ownerRepositoryProvider).fetchInvoices(query);

});



final invoiceDetailProvider = FutureProvider.autoDispose.family<InvoiceDetailResult, int>((ref, id) {

  return ref.watch(ownerRepositoryProvider).fetchInvoiceDetail(id);

});



final paymentsListProvider =

    FutureProvider.autoDispose.family<PaymentsListResult, PaymentsQuery>((ref, query) {

  return ref.watch(ownerRepositoryProvider).fetchPayments(query);

});



final farmActivitiesProvider = FutureProvider.autoDispose<List<FarmActivity>>((ref) {
  return ref.watch(ownerRepositoryProvider).fetchActivities();
});

final customerDetailProvider =

    FutureProvider.autoDispose.family<CustomerDetailResult, CustomerDetailQuery>((ref, query) {

  return ref.watch(ownerRepositoryProvider).fetchCustomerDetail(query);

});

final ownerSettingsProvider = FutureProvider.autoDispose<OwnerSettings>((ref) {
  return ref.watch(ownerRepositoryProvider).fetchSettings();
});

final milkTypesProvider = FutureProvider<List<MilkTypeItem>>((ref) async {
  return ref.watch(ownerRepositoryProvider).fetchMilkTypes();
});

final containerTypesProvider = FutureProvider<List<ContainerTypeItem>>((ref) async {
  return ref.watch(ownerRepositoryProvider).fetchContainerTypes();
});

