import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../owner/domain/entities/owner_models.dart';
import '../../data/repositories/customer_billing_repository.dart';
import '../providers/customer_billing_provider.dart';
import '../../../../core/utils/api_json.dart';
import '../providers/customer_dashboard_provider.dart';
import '../providers/customer_order_provider.dart';
import '../providers/customer_profile_provider.dart';
import '../widgets/customer_dashboard_styles.dart';
import '../widgets/customer_dashboard_widgets.dart';
import '../widgets/customer_orders_widgets.dart';
import '../widgets/customer_subscription_adapter.dart';

class CustomerDashboardPage extends ConsumerStatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  ConsumerState<CustomerDashboardPage> createState() =>
      _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends ConsumerState<CustomerDashboardPage> {
  late DateTime _calendarMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calendarMonth = DateTime(now.year, now.month);
  }

  String get _monthKey =>
      '${_calendarMonth.year}-${_calendarMonth.month.toString().padLeft(2, '0')}';

  void _previousMonth() {
    final earliest = DateTime(DateTime.now().year - 1, DateTime.now().month);
    if (_calendarMonth.isAfter(earliest)) {
      setState(() => _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1));
    }
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_calendarMonth.isBefore(DateTime(now.year, now.month))) {
      setState(() => _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1));
    }
  }

  bool get _canGoBack {
    final earliest = DateTime(DateTime.now().year - 1, DateTime.now().month);
    return _calendarMonth.isAfter(earliest);
  }

  bool get _canGoForward {
    final now = DateTime.now();
    return _calendarMonth.isBefore(DateTime(now.year, now.month));
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(customerDashboardProvider);
    final profileAsync = ref.watch(customerProfileProvider);
    final ordersAsync = ref.watch(customerOrdersProvider(_monthKey));
    final billsAsync = ref.watch(customerBillsProvider);

    return dashAsync.when(
      loading: () => const Scaffold(
        backgroundColor: CusDashColors.background,
        body: Center(
          child: CircularProgressIndicator(color: CusDashColors.accent),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: CusDashColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.cloudOff, size: 48, color: CusDashColors.inkMuted),
              const SizedBox(height: 12),
              Text(
                'Failed to load',
                style: AppText.body.copyWith(color: CusDashColors.inkMuted),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: CusDashColors.accent),
                onPressed: () => ref.invalidate(customerDashboardProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (data) {
        final balance = (data['outstanding_balance'] as num?)?.toDouble() ?? 0.0;
        final upiVpa = data['upi_vpa'] as String?;
        final upiPayeeName = data['upi_payee_name'] as String?;
        final monthlySummary =
            (data['monthly_summary'] as Map?)?.cast<String, dynamic>() ?? {};
        final dashConsumption = data['consumption'] as Map<String, dynamic>?;
        final rawSubs = data['active_subscriptions'];
        final subs = rawSubs is List
            ? rawSubs.cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];

        final profile = profileAsync.valueOrNull;
        final firstName = profile?.profile['first_name'] as String? ?? '';
        final farmName = profile?.farmContact?['farm_name'] as String? ?? '';
        final ownerMobile = profile?.farmContact?['owner_mobile'] as String?;

        final now = DateTime.now();
        final heroStats = _heroMonthStats(
          month: _calendarMonth,
          now: now,
          ordersData: ordersAsync.valueOrNull,
          ordersLoading: ordersAsync.isLoading,
          dashConsumption: dashConsumption,
          monthlySummary: monthlySummary,
        );

        final consumptionRows = heroStats.consumptionRows;
        final consumptionTotal = heroStats.billAmount;

        final ordersDays = ordersAsync.valueOrNull?['days'] as List?;
        final daysList = ordersDays?.cast<Map<String, dynamic>>() ?? [];
        final nextDelivery = _findNextDelivery(daysList, subs, consumptionRows);
        final primarySub = subs.isNotEmpty ? subs.first : null;

        final billInfo = _billLabels(billsAsync.valueOrNull, now);
        final consumptionTitle = _calendarMonth.year == now.year &&
                _calendarMonth.month == now.month
            ? 'THIS MONTH CONSUMPTION'
            : '${DateFormat('MMMM yyyy').format(_calendarMonth).toUpperCase()} CONSUMPTION';

        return Scaffold(
          backgroundColor: CusDashColors.background,
          body: RefreshIndicator(
            color: CusDashColors.accent,
            onRefresh: () async {
              ref.invalidate(customerDashboardProvider);
              ref.invalidate(customerProfileProvider);
              ref.invalidate(customerOrdersProvider(_monthKey));
              ref.invalidate(customerBillsProvider);
              await ref.read(customerDashboardProvider.future);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: CusDashHeader(
                    farmName: farmName,
                    firstName: firstName,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CusDashMetrics.horizontalPad,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (nextDelivery != null) ...[
                        CusDashNextDeliveryCard(
                          date: nextDelivery.date,
                          dateLabel: nextDelivery.dateLabel,
                          shiftLabel: nextDelivery.shiftLabel,
                          isMorning: nextDelivery.isMorning,
                          productLine: nextDelivery.productLine,
                          day: nextDelivery.day,
                          canEdit: nextDelivery.canEdit,
                        ),
                        const SizedBox(height: CusDashMetrics.sectionGap),
                      ],
                      CusDashMonthlySummaryCard(
                        month: _calendarMonth,
                        deliveredLiters: heroStats.deliveredLiters,
                        billAmount: heroStats.billAmount,
                        daysLabel: heroStats.daysLabel,
                        progress: heroStats.progress,
                        footerText: heroStats.footerText,
                        isLoading: heroStats.isLoading,
                      ),
                      const SizedBox(height: CusDashMetrics.sectionGap),
                      ordersAsync.when(
                        data: (orders) => CusDashDeliveryCalendar(
                          month: _calendarMonth,
                          days: (orders['days'] as List?)?.cast<Map<String, dynamic>>() ?? [],
                          canGoBack: _canGoBack,
                          canGoForward: _canGoForward,
                          onPrevious: _previousMonth,
                          onNext: _nextMonth,
                        ),
                        loading: () => Container(
                          height: 280,
                          alignment: Alignment.center,
                          decoration: CusDashText.whiteCard(),
                          child: const CircularProgressIndicator(
                            color: CusDashColors.accent,
                          ),
                        ),
                        error: (e, _) => Container(
                          padding: const EdgeInsets.all(20),
                          decoration: CusDashText.whiteCard(),
                          child: Column(
                            children: [
                              Text(
                                'Could not load delivery calendar.',
                                style: AppText.body.copyWith(color: CusDashColors.inkMuted),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: CusDashColors.accent,
                                ),
                                onPressed: () => ref.invalidate(customerOrdersProvider(_monthKey)),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (balance > 0) ...[
                        const SizedBox(height: CusDashMetrics.sectionGap),
                        CusDashPaymentCard(
                          balance: balance,
                          billLabel: billInfo.billLabel,
                          dueLabel: billInfo.dueLabel,
                          upiVpa: upiVpa,
                          upiPayeeName: upiPayeeName,
                        ),
                      ],
                      CusDashSectionLabel(title: consumptionTitle),
                      cusDashConsumptionSection(
                        rows: consumptionRows,
                        grandTotal: consumptionTotal,
                      ),
                      if (primarySub != null) ...[
                        const CusDashSectionLabel(title: 'MY SUBSCRIPTION'),
                        CusDashSubscriptionCard(
                          productLabel: _productLabel(primarySub, consumptionRows),
                          shiftLabel: primarySub['shift_label'] as String? ??
                              _capitalize(primarySub['shift'] as String? ?? 'morning'),
                          isMorning: (primarySub['shift'] as String? ?? 'morning') == 'morning',
                          qtyPerDay: (primarySub['qty'] as num?)?.toDouble() ?? 0,
                          isActive: true,
                        ),
                      ],
                      CusDashQuickActions(ownerMobile: ownerMobile),
                      const CusDashBrandingFooter(),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroMonthStats {
  const _HeroMonthStats({
    required this.deliveredLiters,
    required this.billAmount,
    required this.daysLabel,
    required this.progress,
    required this.footerText,
    required this.consumptionRows,
    this.isLoading = false,
  });

  final double deliveredLiters;
  final double billAmount;
  final String daysLabel;
  final double progress;
  final String footerText;
  final List<ConsumptionRow> consumptionRows;
  final bool isLoading;
}

_HeroMonthStats _heroMonthStats({
  required DateTime month,
  required DateTime now,
  required Map<String, dynamic>? ordersData,
  required bool ordersLoading,
  Map<String, dynamic>? dashConsumption,
  Map<String, dynamic>? monthlySummary,
}) {
  final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
  final isCurrentMonth = month.year == now.year && month.month == now.month;

  if (ordersData != null) {
    final consumption = ordersData['consumption'] as Map<String, dynamic>?;
    final rows = customerConsumptionRowsFromJson(consumption);
    final billAmount = customerConsumptionGrandTotal(consumption);
    final days = (ordersData['days'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final stats = cusOrdersMonthStats(days);
    final deliveredLiters = rows.fold<double>(0, (sum, r) => sum + r.totalQuantity);

    final progress = isCurrentMonth ? now.day / daysInMonth : 1.0;
    final footerText = isCurrentMonth
        ? _daysLeftLabel(daysInMonth - now.day)
        : 'Month complete';

    return _HeroMonthStats(
      deliveredLiters: deliveredLiters,
      billAmount: billAmount,
      daysLabel: '${stats.delivered}/$daysInMonth',
      progress: progress,
      footerText: footerText,
      consumptionRows: rows,
    );
  }

  if (ordersLoading) {
    return const _HeroMonthStats(
      deliveredLiters: 0,
      billAmount: 0,
      daysLabel: '—',
      progress: 0,
      footerText: '',
      consumptionRows: [],
      isLoading: true,
    );
  }

  if (isCurrentMonth && dashConsumption != null) {
    final rows = customerConsumptionRowsFromJson(dashConsumption);
    final billAmount = customerConsumptionGrandTotal(dashConsumption);
    final deliveredLiters = rows.fold<double>(0, (sum, r) => sum + r.totalQuantity);
    final deliveredLogs = (monthlySummary?['delivered'] as num?)?.toInt() ?? 0;

    return _HeroMonthStats(
      deliveredLiters: deliveredLiters,
      billAmount: billAmount,
      daysLabel: '$deliveredLogs/$daysInMonth',
      progress: now.day / daysInMonth,
      footerText: _daysLeftLabel(daysInMonth - now.day),
      consumptionRows: rows,
    );
  }

  return _HeroMonthStats(
    deliveredLiters: 0,
    billAmount: 0,
    daysLabel: '0/$daysInMonth',
    progress: isCurrentMonth ? now.day / daysInMonth : 1.0,
    footerText: isCurrentMonth ? _daysLeftLabel(daysInMonth - now.day) : 'Month complete',
    consumptionRows: const [],
  );
}

String _daysLeftLabel(int daysLeft) {
  if (daysLeft <= 0) return 'Last day of month';
  if (daysLeft == 1) return '1 day left';
  return '$daysLeft days left';
}

class _NextDelivery {
  const _NextDelivery({
    required this.date,
    required this.dateLabel,
    required this.shiftLabel,
    required this.isMorning,
    required this.productLine,
    required this.day,
    required this.canEdit,
  });

  final DateTime date;
  final String dateLabel;
  final String shiftLabel;
  final bool isMorning;
  final String productLine;
  final Map<String, dynamic> day;
  final bool canEdit;
}

_NextDelivery? _findNextDelivery(
  List<Map<String, dynamic>> days,
  List<Map<String, dynamic>> subs,
  List<ConsumptionRow> consumptionRows,
) {
  if (subs.isEmpty) return null;

  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);
  final sub = subs.first;
  final shift = sub['shift'] as String? ?? 'morning';
  final shiftLabel = sub['shift_label'] as String? ?? _capitalize(shift);
  final qty = parseApiDouble(sub['qty']);
  final productName = sub['product_name'] as String? ?? '';
  final minEditableDate = shift == 'evening'
      ? todayDate
      : todayDate.add(const Duration(days: 1));

  double rate = 0;
  for (final row in consumptionRows) {
    if (row.productName.toLowerCase().contains(productName.toLowerCase().split(' ').first)) {
      rate = row.unitRate;
      break;
    }
  }
  if (rate <= 0 && consumptionRows.isNotEmpty) {
    rate = consumptionRows.first.unitRate;
  }

  final productLine = rate > 0
      ? '$productName — ₹${rate.round()} · ${qty == qty.roundToDouble() ? qty.toInt() : qty} L'
      : '$productName · ${qty == qty.roundToDouble() ? qty.toInt() : qty} L';

  for (final day in days) {
    final dateStr = day['date'] as String?;
    final parsed = DateTime.tryParse(dateStr ?? '');
    if (parsed == null) continue;
    final d = DateTime(parsed.year, parsed.month, parsed.day);
    if (d.isBefore(minEditableDate)) continue;

    final status = day['status'] as String? ?? 'no_record';
    if (status == 'vacation') continue;
    if (status == 'delivered' && !d.isAfter(todayDate)) continue;

    final canEdit = day['can_edit'] as bool? ??
        (status == 'expected' || status == 'skipped');

    if (!canEdit) continue;

    final isTomorrow = d.difference(todayDate).inDays == 1;
    final dateLabel = isTomorrow
        ? 'Tomorrow'
        : DateFormat('EEE d MMM').format(d);

    return _NextDelivery(
      date: d,
      dateLabel: dateLabel,
      shiftLabel: shiftLabel,
      isMorning: shift == 'morning',
      productLine: productLine,
      day: day,
      canEdit: canEdit,
    );
  }

  // Fallback when orders not loaded yet.
  final fallbackDate = minEditableDate;
  final fallbackStr = DateFormat('yyyy-MM-dd').format(fallbackDate);
  final isTomorrow = fallbackDate.difference(todayDate).inDays == 1;
  return _NextDelivery(
    date: fallbackDate,
    dateLabel: isTomorrow ? 'Tomorrow' : DateFormat('EEE d MMM').format(fallbackDate),
    shiftLabel: shiftLabel,
    isMorning: shift == 'morning',
    productLine: productLine,
    day: {
      'date': fallbackStr,
      'status': 'expected',
      'entries': [
        {
          'product_name': productName,
          'quantity': qty,
          'locked': false,
        },
      ],
    },
    canEdit: true,
  );
}

class _BillLabels {
  const _BillLabels({required this.billLabel, required this.dueLabel});
  final String billLabel;
  final String dueLabel;
}

_BillLabels _billLabels(List<CustomerBill>? bills, DateTime now) {
  final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  CustomerBill? current;
  if (bills != null) {
    for (final b in bills) {
      if (b.billingMonth == monthKey && b.balanceDue > 0) {
        current = b;
        break;
      }
    }
    if (current == null) {
      for (final b in bills) {
        if (b.balanceDue > 0) {
          current = b;
          break;
        }
      }
    }
  }

  if (current != null) {
    final parts = current.billingMonth.split('-');
    final billMonth = parts.length == 2
        ? DateFormat('MMMM').format(DateTime(int.parse(parts[0]), int.parse(parts[1])))
        : 'Bill';
    final due = DateTime(
      parts.length == 2 ? int.parse(parts[0]) : now.year,
      parts.length == 2 ? int.parse(parts[1]) + 1 : now.month + 1,
      5,
    );
    return _BillLabels(
      billLabel: '$billMonth bill',
      dueLabel: 'Due ${DateFormat('d MMM').format(due)}',
    );
  }

  return const _BillLabels(billLabel: 'June bill', dueLabel: 'Due 5 Jul');
}

String _productLabel(Map<String, dynamic> sub, List<ConsumptionRow> rows) {
  final name = sub['product_name'] as String? ?? '';
  for (final row in rows) {
    if (row.productName.toLowerCase().contains(name.toLowerCase().split(' ').first)) {
      return '${row.productName} – ₹${row.unitRate.round()}';
    }
  }
  if (rows.isNotEmpty) {
    return '${rows.first.productName} – ₹${rows.first.unitRate.round()}';
  }
  return name;
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
