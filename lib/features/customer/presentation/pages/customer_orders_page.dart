import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/repositories/customer_order_repository.dart';
import '../providers/customer_dashboard_provider.dart';
import '../providers/customer_order_provider.dart';
import '../widgets/customer_dashboard_styles.dart';
import '../widgets/customer_orders_sheets.dart';
import '../widgets/customer_orders_widgets.dart';
import '../../../../core/widgets/app_snackbar.dart';

class CustomerOrdersPage extends ConsumerStatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  ConsumerState<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends ConsumerState<CustomerOrdersPage> {
  late DateTime _selectedMonth;
  String? _skippingDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  String get _monthKey =>
      '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}';

  Future<void> _pickMonth() async {
    final picked = await showCusOrdersMonthPicker(
      context: context,
      selected: _selectedMonth,
    );
    if (picked != null) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
  }

  void _openDaySheet(Map<String, dynamic> day) {
    final status = day['status'] as String? ?? 'no_record';
    final entries = (day['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final isLocked = entries.isNotEmpty && entries.every((e) => e['locked'] == true);
    final repo = ref.read(customerOrderRepositoryProvider);
    final onSaved = () => ref.invalidate(customerOrdersProvider(_monthKey));

    if (status == 'expected' && !isLocked) {
      showCustomerOrderDayEditSheet(
        context: context,
        day: day,
        repository: repo,
        onSaved: onSaved,
      );
    } else if (status == 'delivered' ||
        status == 'skipped' ||
        status == 'vacation' ||
        (status == 'expected' && isLocked)) {
      final dashData = ref.read(customerDashboardProvider).value;
      final activeSubs = (dashData?['active_subscriptions'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      showCustomerOrderDayDetailSheet(
        context: context,
        day: day,
        activeSubs: activeSubs,
      );
    }
  }

  Future<void> _skipDay(Map<String, dynamic> day) async {
    final dateStr = day['date'] as String? ?? '';
    if (dateStr.isEmpty) return;

    setState(() => _skippingDate = dateStr);
    try {
      await ref.read(customerOrderRepositoryProvider).skipDay(dateStr);
      ref.invalidate(customerOrdersProvider(_monthKey));
      ref.invalidate(customerDashboardProvider);
      if (mounted) AppSnackBar.show(context, 'Delivery skipped');
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _skippingDate = null);
    }
  }

  String _subtitleForDay(DateTime date, Map<String, dynamic> day, {required bool upcoming}) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final diff = date.difference(today).inDays;
    final qty = cusOrderQtyLabel(day);
    final status = day['status'] as String? ?? '';

    if (upcoming) {
      final when = diff == 1 ? 'Tomorrow' : (diff == 0 ? 'Today' : DateFormat('EEE d MMM').format(date));
      return '$when · $qty';
    }
    if (status == 'skipped' || status == 'vacation') return '—';
    return qty;
  }

  bool _isToday(String dateStr) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return dateStr == today;
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(customerOrdersProvider(_monthKey));

    return Scaffold(
      backgroundColor: CusDashColors.background,
      body: RefreshIndicator(
        color: CusDashColors.accent,
        onRefresh: () async {
          ref.invalidate(customerOrdersProvider(_monthKey));
          ref.invalidate(customerDashboardProvider);
          await ref.read(customerOrdersProvider(_monthKey).future).catchError((_) => <String, dynamic>{});
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: CusOrdersHeader(month: _selectedMonth, onMonthTap: _pickMonth),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: CusDashMetrics.horizontalPad),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  ordersAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(color: CusDashColors.accent),
                      ),
                    ),
                    error: (_, __) => CusOrdersErrorCard(
                      onRetry: () => ref.invalidate(customerOrdersProvider(_monthKey)),
                    ),
                    data: (data) {
                      final days =
                          (data['days'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                      final consumption =
                          (data['consumption'] as Map<String, dynamic>?)?['rows'] as List? ?? [];
                      final consumptionRows =
                          consumption.cast<Map<String, dynamic>>();

                      final stats = cusOrdersMonthStats(days);
                      final upcoming = cusUpcomingDays(days);
                      final history = cusHistoryDays(days);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CusOrdersStatsRow(
                            delivered: stats.delivered,
                            skipped: stats.skipped,
                            totalLiters: stats.totalLiters,
                          ),
                          if (upcoming.isNotEmpty) ...[
                            const CusOrdersSectionLabel(title: 'UPCOMING'),
                            ...upcoming.map((day) {
                              final dateStr = day['date'] as String? ?? '';
                              final date = DateTime.parse(dateStr);
                              return CusOrderDayCard(
                                day: day,
                                productLabel: cusOrderProductLabel(day, consumptionRows),
                                subtitle: _subtitleForDay(date, day, upcoming: true),
                                qtyLabel: cusOrderQtyLabel(day),
                                mode: CusOrderCardMode.upcoming,
                                onTap: () => _openDaySheet(day),
                                onSkip: () => _skipDay(day),
                                skipping: _skippingDate == dateStr,
                              );
                            }),
                          ],
                          const CusOrdersSectionLabel(title: 'DELIVERY HISTORY'),
                          if (history.isEmpty)
                            const CusOrdersEmptyCard(
                              message: 'No deliveries recorded for this month.',
                            )
                          else
                            ...history.map((day) {
                              final dateStr = day['date'] as String? ?? '';
                              final date = DateTime.parse(dateStr);
                              final isToday = _isToday(dateStr);
                              final status = day['status'] as String? ?? '';
                              return CusOrderDayCard(
                                day: day,
                                productLabel: cusOrderProductLabel(day, consumptionRows),
                                subtitle: _subtitleForDay(date, day, upcoming: false),
                                qtyLabel: cusOrderQtyLabel(day),
                                mode: CusOrderCardMode.history,
                                status: status,
                                isToday: isToday,
                                onTap: () => _openDaySheet(day),
                              );
                            }),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
