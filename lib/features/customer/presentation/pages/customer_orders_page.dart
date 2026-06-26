import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/customer_dashboard_provider.dart';
import '../providers/customer_order_provider.dart';
import '../widgets/customer_dashboard_styles.dart';
import '../widgets/customer_orders_sheets.dart';
import '../widgets/customer_orders_widgets.dart';

class CustomerOrdersPage extends ConsumerStatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  ConsumerState<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends ConsumerState<CustomerOrdersPage> {
  late DateTime _selectedMonth;

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

  void _openDaySheet(
    Map<String, dynamic> day, {
    required bool allowEdit,
  }) {
    final status = day['status'] as String? ?? 'no_record';
    final canEdit = day['can_edit'] as bool? ?? false;
    final repo = ref.read(customerOrderRepositoryProvider);
    final onSaved = () {
      ref.invalidate(customerOrdersProvider(_monthKey));
      ref.invalidate(customerDashboardProvider);
    };

    if (allowEdit && canEdit && (status == 'expected' || status == 'skipped')) {
      showCustomerOrderDayEditSheet(
        context: context,
        day: day,
        repository: repo,
        onSaved: onSaved,
      );
      return;
    }

    if (status == 'expected' ||
        status == 'delivered' ||
        status == 'skipped' ||
        status == 'vacation') {
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

  String _subtitleForDay(DateTime date, Map<String, dynamic> day, {required bool upcoming}) {
    final today = cusTodayDate();
    final diff = date.difference(today).inDays;
    final qty = cusOrderQtyLabel(day);
    final status = day['status'] as String? ?? '';

    if (upcoming) {
      if (status == 'skipped' || status == 'vacation') return '';
      if (status != 'expected') return '';
      final when = diff == 1 ? 'Tomorrow' : (diff == 0 ? 'Today' : DateFormat('EEE d MMM').format(date));
      return qty == '—' ? when : '$when · $qty';
    }
    if (status == 'skipped' || status == 'vacation') return '—';
    return qty;
  }

  bool _isToday(String dateStr) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return dateStr == today;
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  String _nextDeliverySubtitle(DateTime date, Map<String, dynamic> day) {
    final today = cusTodayDate();
    final diff = date.difference(today).inDays;
    final qty = cusOrderQtyLabel(day);
    final status = day['status'] as String? ?? '';
    if (status == 'skipped') {
      final when = diff == 1
          ? 'Tomorrow · Skipped'
          : (diff == 0 ? 'Today · Skipped' : '${DateFormat('EEE d MMM').format(date)} · Skipped');
      return when;
    }
    final when = diff == 1
        ? 'Tomorrow'
        : (diff == 0 ? 'Today' : DateFormat('EEE d MMM').format(date));
    return qty == '—' ? when : '$when · $qty';
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

                      final dashData = ref.watch(customerDashboardProvider).valueOrNull;
                      final subs = (dashData?['active_subscriptions'] as List?)
                              ?.cast<Map<String, dynamic>>() ??
                          [];
                      final shift = subs.isNotEmpty
                          ? (subs.first['shift'] as String? ?? 'morning')
                          : 'morning';

                      final stats = cusOrdersMonthStats(days);
                      final history = cusHistoryDays(days);
                      final nextEditableDay = _isCurrentMonth
                          ? cusNextEditableDay(days, shift: shift)
                          : null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CusOrdersStatsRow(
                            delivered: stats.delivered,
                            skipped: stats.skipped,
                            totalLiters: stats.totalLiters,
                          ),
                          if (nextEditableDay != null) ...[
                            const CusOrdersSectionLabel(title: 'NEXT DELIVERY'),
                            Builder(
                              builder: (_) {
                                final dateStr = nextEditableDay['date'] as String? ?? '';
                                final date = DateTime.parse(dateStr);
                                final isToday = _isToday(dateStr);
                                return CusOrderDayCard(
                                  day: nextEditableDay,
                                  productLabel: cusOrderProductLabel(
                                    nextEditableDay,
                                    consumptionRows,
                                  ),
                                  subtitle: _nextDeliverySubtitle(date, nextEditableDay),
                                  mode: CusOrderCardMode.upcoming,
                                  status: nextEditableDay['status'] as String? ?? 'expected',
                                  isToday: isToday,
                                  onTap: () => _openDaySheet(
                                    nextEditableDay,
                                    allowEdit: nextEditableDay['can_edit'] as bool? ?? true,
                                  ),
                                  onEdit: () => _openDaySheet(
                                    nextEditableDay,
                                    allowEdit: nextEditableDay['can_edit'] as bool? ?? true,
                                  ),
                                );
                              },
                            ),
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
                                mode: CusOrderCardMode.history,
                                status: status,
                                isToday: isToday,
                                onTap: () => _openDaySheet(day, allowEdit: false),
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
