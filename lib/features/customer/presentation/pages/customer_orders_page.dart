import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../owner/presentation/widgets/customer_detail/customer_detail_styles.dart';
import '../../../owner/presentation/widgets/customer_detail/customer_detail_widgets.dart';
import '../widgets/customer_subscription_adapter.dart';
import '../../data/repositories/customer_order_repository.dart';
import '../providers/customer_dashboard_provider.dart';
import '../providers/customer_order_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

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

  void _previousMonth() {
    final earliest = DateTime(DateTime.now().year - 1, DateTime.now().month);
    if (_selectedMonth.isAfter(earliest)) {
      setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1));
    }
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.isBefore(DateTime(now.year, now.month))) {
      setState(() => _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1));
    }
  }

  bool get _canGoBack {
    final earliest = DateTime(DateTime.now().year - 1, DateTime.now().month);
    return _selectedMonth.isAfter(earliest);
  }

  bool get _canGoForward {
    final now = DateTime.now();
    return _selectedMonth.isBefore(DateTime(now.year, now.month));
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  void _openDaySheet(BuildContext context, Map<String, dynamic> day) {
    final status = day['status'] as String? ?? 'no_record';
    final entries = (day['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final isLocked = entries.every((e) => e['locked'] == true);

    if (status == 'expected' && !isLocked) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: false,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _DayEditSheet(
          day: day,
          repository: ref.read(customerOrderRepositoryProvider),
          onSaved: () => ref.invalidate(customerOrdersProvider(_monthKey)),
        ),
      );
    } else if (status == 'delivered' || status == 'skipped' || status == 'vacation' ||
        (status == 'expected' && isLocked)) {
      final dashData = ref.read(customerDashboardProvider).value;
      final activeSubs = (dashData?['active_subscriptions'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: false,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _DayDetailSheet(day: day, activeSubs: activeSubs),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(customerDashboardProvider);
    final ordersAsync = ref.watch(customerOrdersProvider(_monthKey));

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      body: RefreshIndicator(
        color: CustomerDetailColors.accent,
        onRefresh: () async {
          ref.invalidate(customerOrdersProvider(_monthKey));
          ref.invalidate(customerDashboardProvider);
          await ref
              .read(customerOrdersProvider(_monthKey).future)
              .catchError((_) => <String, dynamic>{});
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: CustomerDetailColors.background,
              surfaceTintColor: Colors.transparent,
              floating: true,
              snap: true,
              elevation: 0,
              titleSpacing: 16,
              title: Text(
                'Orders',
                style: AppText.screenTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: CustomerDetailColors.accent,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(LucideIcons.plane, color: CustomerDetailColors.accent, size: 22),
                  tooltip: 'Manage Vacation',
                  onPressed: () => context.push('/customer/vacation'),
                ),
                const SizedBox(width: 4),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 4),

                  dashAsync.when(
                    data: (dashData) {
                      final rawSubs = dashData['active_subscriptions'];
                      final subs = rawSubs is List
                          ? rawSubs.cast<Map<String, dynamic>>()
                          : <Map<String, dynamic>>[];
                      final ordersData = ordersAsync.valueOrNull;
                      final days = (ordersData?['days'] as List?)
                              ?.cast<Map<String, dynamic>>() ??
                          const <Map<String, dynamic>>[];
                      final hasOrderDays = ordersAsync.hasValue;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomerDetailSectionLabel(
                            title: AppStrings.subscriptionsTitle.toUpperCase(),
                          ),
                          if (subs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                AppStrings.noSubscriptions,
                                style: AppText.body.copyWith(
                                  color: CustomerDetailColors.onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            ...subs.asMap().entries.map((entry) {
                              final line = customerSubscriptionLineFromOrders(
                                subscription: entry.value,
                                days: hasOrderDays ? days : const [],
                              );
                              return CustomerDetailSubscriptionCard(
                                index: entry.key + 1,
                                line: line,
                                month: _selectedMonth,
                                showCalendar: hasOrderDays,
                                initiallyExpanded: entry.key == subs.length - 1,
                              );
                            }),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Orders section
                  ordersAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: CustomerDetailColors.accent,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: _ErrorCard(
                        message: error.toString(),
                        onRetry: () => ref.invalidate(customerOrdersProvider(_monthKey)),
                      ),
                    ),
                    data: (data) {
                      final days = (data['days'] as List?)
                              ?.cast<Map<String, dynamic>>() ??
                          [];

                      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                      final tomorrow = DateFormat('yyyy-MM-dd')
                          .format(DateTime.now().add(const Duration(days: 1)));

                      final todayDay = days.firstWhere(
                        (d) => d['date'] == today,
                        orElse: () => <String, dynamic>{},
                      );
                      final tomorrowDay = days.firstWhere(
                        (d) => d['date'] == tomorrow,
                        orElse: () => <String, dynamic>{},
                      );

                      final listDays = days
                          .where((d) => d['status'] != 'no_record')
                          .toList()
                          .reversed
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick actions (current month only)
                          if (_isCurrentMonth) ...[
                            _QuickActionsCard(
                              todayDay: todayDay,
                              tomorrowDay: tomorrowDay,
                              repository: ref.read(customerOrderRepositoryProvider),
                              onSaved: () {
                                ref.invalidate(customerOrdersProvider(_monthKey));
                              },
                            ),
                            const SizedBox(height: 20),
                          ],

                          CustomerDetailMonthNav(
                            month: _selectedMonth,
                            onPrevious: _canGoBack ? _previousMonth : () {},
                            onNext: _canGoForward ? _nextMonth : () {},
                          ),
                          const SizedBox(height: 16),

                          CustomerDetailSectionLabel(title: 'ORDER LOG'),
                          if (listDays.isEmpty)
                            _EmptyOrdersCard()
                          else
                            _OrderLogList(
                              days: listDays,
                              onTap: (day) => _openDaySheet(context, day),
                            ),
                          const SizedBox(height: 24),

                          CustomerDetailSectionLabel(
                            title: AppStrings.consumptionTitle.toUpperCase(),
                          ),
                          Builder(
                            builder: (context) {
                              final consumption =
                                  data['consumption'] as Map<String, dynamic>?;
                              final rows = customerConsumptionRowsFromJson(consumption);
                              final grandTotal =
                                  customerConsumptionGrandTotal(consumption);
                              if (rows.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    AppStrings.noConsumptionRecorded,
                                    style: AppText.body.copyWith(
                                      color: CustomerDetailColors.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              }
                              return CustomerDetailConsumptionCard(
                                rows: rows,
                                grandTotal: grandTotal,
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions card ────────────────────────────────────────────────────────

class _QuickActionsCard extends StatefulWidget {
  const _QuickActionsCard({
    required this.todayDay,
    required this.tomorrowDay,
    required this.repository,
    required this.onSaved,
  });

  final Map<String, dynamic> todayDay;
  final Map<String, dynamic> tomorrowDay;
  final CustomerOrderRepository repository;
  final VoidCallback onSaved;

  @override
  State<_QuickActionsCard> createState() => _QuickActionsCardState();
}

class _QuickActionsCardState extends State<_QuickActionsCard> {
  // qty overrides: subscription_line_id → qty
  final Map<int, int> _tomorrowQtys = {};
  final Map<int, int> _todayQtys = {};
  bool _savingTomorrow = false;
  bool _savingToday = false;
  bool _skipping = false;

  List<Map<String, dynamic>> get _tomorrowEntries =>
      ((widget.tomorrowDay['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [])
          .where((e) => e['locked'] == false)
          .toList();

  List<Map<String, dynamic>> get _todayUnlockedEntries =>
      ((widget.todayDay['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [])
          .where((e) => e['locked'] == false)
          .toList();

  String get _tomorrowDateStr => widget.tomorrowDay['date'] as String? ?? '';
  String get _todayDateStr => widget.todayDay['date'] as String? ?? '';

  int _qtyFor(Map<int, int> overrides, Map<String, dynamic> entry) {
    final id = entry['subscription_line_id'] as int;
    return overrides[id] ?? (entry['qty'] as num?)?.toInt() ?? 1;
  }

  Future<void> _saveTomorrow() async {
    setState(() => _savingTomorrow = true);
    try {
      for (final e in _tomorrowEntries) {
        final id = e['subscription_line_id'] as int;
        final newQty = _tomorrowQtys[id] ?? (e['qty'] as num?)?.toInt() ?? 1;
        final origQty = (e['qty'] as num?)?.toInt() ?? 1;
        if (newQty != origQty) {
          await widget.repository.updateQty(_tomorrowDateStr, id, newQty);
        }
      }
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _savingTomorrow = false);
    }
  }

  Future<void> _saveToday() async {
    setState(() => _savingToday = true);
    try {
      for (final e in _todayUnlockedEntries) {
        final id = e['subscription_line_id'] as int;
        final newQty = _todayQtys[id] ?? (e['qty'] as num?)?.toInt() ?? 1;
        final origQty = (e['qty'] as num?)?.toInt() ?? 1;
        if (newQty != origQty) {
          await widget.repository.updateQty(_todayDateStr, id, newQty);
        }
      }
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _savingToday = false);
    }
  }

  Future<void> _skipTomorrow() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip Tomorrow'),
        content: const Text('Skip all deliveries for tomorrow?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CustomerDetailColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _skipping = true);
    try {
      await widget.repository.skipDay(_tomorrowDateStr);
      if (mounted) {
        widget.onSaved();
        AppSnackBar.show(context, "Tomorrow's delivery skipped.");
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _skipping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasTomorrow = _tomorrowEntries.isNotEmpty;
    final hasToday = _todayUnlockedEntries.isNotEmpty;

    if (!hasTomorrow && !hasToday) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
        border: Border.all(color: CustomerDetailColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283C28).withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(LucideIcons.zap, size: 18, color: CustomerDetailColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: AppText.cardTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: CustomerDetailColors.divider),

          // Tomorrow's morning entries
          if (hasTomorrow) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: CustomerDetailColors.morningChipBg,
                      border: Border.all(color: CustomerDetailColors.morningChipBorder),
                      borderRadius: BorderRadius.circular(CustomerDetailMetrics.chipRadius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.sun, size: 13, color: CustomerDetailColors.morningChipInk),
                        const SizedBox(width: 4),
                        Text(
                          'Tomorrow — Morning',
                          style: AppText.meta.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: CustomerDetailColors.morningChipInk,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (final e in _tomorrowEntries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: _InlineStepperRow(
                  entry: e,
                  qty: _qtyFor(_tomorrowQtys, e),
                  onChanged: (v) => setState(
                    () => _tomorrowQtys[e['subscription_line_id'] as int] = v,
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: CustomerDetailColors.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size.fromHeight(40),
                      ),
                      onPressed: _savingTomorrow || _skipping ? null : _saveTomorrow,
                      child: _savingTomorrow
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CustomerDetailColors.danger,
                        side: BorderSide(color: CustomerDetailColors.dangerBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size.fromHeight(40),
                      ),
                      onPressed: _savingTomorrow || _skipping ? null : _skipTomorrow,
                      child: _skipping
                          ? SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: CustomerDetailColors.danger))
                          : const Text('Skip Tomorrow', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Today's evening entries
          if (hasToday) ...[
            if (hasTomorrow)
              const Divider(height: 24, indent: 20, endIndent: 20),
            Padding(
              padding: EdgeInsets.fromLTRB(20, hasTomorrow ? 0 : 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.nights_stay_outlined, size: 13, color: Color(0xFF4527A0)),
                        SizedBox(width: 4),
                        Text(
                          'Today — Evening',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4527A0)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            for (final e in _todayUnlockedEntries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: _InlineStepperRow(
                  entry: e,
                  qty: _qtyFor(_todayQtys, e),
                  onChanged: (v) => setState(
                    () => _todayQtys[e['subscription_line_id'] as int] = v,
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4527A0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(40),
                ),
                onPressed: _savingToday ? null : _saveToday,
                child: _savingToday
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Evening Qty', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InlineStepperRow extends StatelessWidget {
  const _InlineStepperRow({required this.entry, required this.qty, required this.onChanged});

  final Map<String, dynamic> entry;
  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final name = entry['product_name'] as String? ?? '';

    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: CustomerDetailColors.onSurface),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: CustomerDetailColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 16),
                onPressed: qty > 0 ? () => onChanged(qty - 1) : null,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: CustomerDetailColors.accent,
              ),
              SizedBox(
                width: 30,
                child: Text(
                  '$qty',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 16),
                onPressed: () => onChanged(qty + 1),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                color: CustomerDetailColors.accent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Order log list ────────────────────────────────────────────────────────────

class _OrderLogList extends StatelessWidget {
  const _OrderLogList({required this.days, required this.onTap});

  final List<Map<String, dynamic>> days;
  final void Function(Map<String, dynamic>) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
        border: Border.all(color: CustomerDetailColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF283C28).withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < days.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 20,
                endIndent: 20,
                color: CustomerDetailColors.border.withValues(alpha: 0.5),
              ),
            _OrderLogRow(day: days[i], onTap: () => onTap(days[i])),
          ],
        ],
      ),
    );
  }
}

class _OrderLogRow extends StatelessWidget {
  const _OrderLogRow({required this.day, required this.onTap});

  final Map<String, dynamic> day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = day['status'] as String? ?? 'no_record';
    final dateStr = day['date'] as String? ?? '';
    final entries = (day['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final isLocked = entries.every((e) => e['locked'] == true);
    final isEditable = status == 'expected' && !isLocked;

    String formattedDate = dateStr;
    try {
      formattedDate = DateFormat('d MMM, EEE').format(DateTime.parse(dateStr));
    } catch (_) {}

    final Color statusColor;
    final String statusLabel;
    final Color statusBg;
    switch (status) {
      case 'delivered':
        statusColor = CustomerDetailColors.success;
        statusBg = const Color(0xFFE6F4EE);
        statusLabel = 'Delivered';
      case 'skipped':
        statusColor = CustomerDetailColors.morningChipInk;
        statusBg = const Color(0xFFFFF3E0);
        statusLabel = 'Skipped';
      case 'vacation':
        statusColor = const Color(0xFF3D5896);
        statusBg = const Color(0xFFE3EDFC);
        statusLabel = 'Vacation';
      case 'expected':
        statusColor = isLocked ? CustomerDetailColors.onSurfaceVariant : CustomerDetailColors.accent;
        statusBg = isLocked ? const Color(0xFFF0F0F0) : CustomerDetailColors.accentLight;
        statusLabel = isLocked ? 'Locked' : 'Upcoming';
      default:
        statusColor = CustomerDetailColors.onSurfaceVariant;
        statusBg = const Color(0xFFF0F0F0);
        statusLabel = status;
    }

    // Build a short summary of entries (e.g. "Milk · 2L, Buffalo · 1L")
    String entrySummary = '';
    if (status != 'vacation' && entries.isNotEmpty) {
      entrySummary = entries.map((e) {
        final name = e['product_name'] as String? ?? '';
        final qty = (e['qty'] as num?)?.toInt() ?? 0;
        return '$name · ${qty}L';
      }).join(', ');
    }

    return InkWell(
      onTap: status != 'no_record' ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CustomerDetailColors.onSurface,
                    ),
                  ),
                  if (entrySummary.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      entrySummary,
                      style: TextStyle(
                        fontSize: 12,
                        color: status == 'skipped'
                            ? CustomerDetailColors.morningChipInk.withValues(alpha: 0.8)
                            : CustomerDetailColors.onSurfaceVariant,
                        decoration: status == 'skipped' ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
              child: Text(
                statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ),
            if (isEditable) ...[
              const SizedBox(width: 8),
              Icon(LucideIcons.pencil, size: 16, color: CustomerDetailColors.accent),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyOrdersCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CustomerDetailColors.surface,
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
        border: Border.all(color: CustomerDetailColors.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: const Center(
        child: Text(
          'No deliveries recorded for this month.',
          style: TextStyle(fontSize: 14, color: CustomerDetailColors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Day detail sheet (delivered / skipped / vacation / locked-expected) ───────

class _DayDetailSheet extends StatelessWidget {
  const _DayDetailSheet({required this.day, required this.activeSubs});

  final Map<String, dynamic> day;
  final List<Map<String, dynamic>> activeSubs;

  @override
  Widget build(BuildContext context) {
    final status = day['status'] as String? ?? 'no_record';
    final entries = (day['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final dateStr = day['date'] as String? ?? '';

    String formattedDate = dateStr;
    try {
      formattedDate = DateFormat('EEEE, d MMMM').format(DateTime.parse(dateStr));
    } catch (_) {}

    final lines = _buildLines(status, entries);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: CustomerDetailColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: CustomerDetailColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 20),
          if (lines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No delivery data for this day.',
                style: TextStyle(fontSize: 14, color: CustomerDetailColors.onSurfaceVariant),
              ),
            )
          else
            ...lines.map((line) => _DeliveryLine(line: line, dayStatus: status)),
        ],
      ),
    );
  }

  List<_LineData> _buildLines(String status, List<Map<String, dynamic>> entries) {
    if (status == 'delivered' && entries.isNotEmpty) {
      return entries.map((e) => _LineData(
        productName: e['product_name'] as String? ?? '',
        shift: e['shift'] as String? ?? '',
        qty: (e['qty'] as num?)?.toInt() ?? 0,
      )).toList();
    }
    return activeSubs.map((s) => _LineData(
      productName: s['product_name'] as String? ?? '',
      shift: s['shift'] as String? ?? '',
      qty: (s['qty'] as num?)?.toInt() ?? 0,
    )).toList();
  }
}

class _LineData {
  const _LineData({required this.productName, required this.shift, required this.qty});
  final String productName;
  final String shift;
  final int qty;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;
    switch (status) {
      case 'delivered':
        bg = const Color(0xFFE6F4EE); fg = CustomerDetailColors.success; label = 'Delivered';
      case 'skipped':
        bg = const Color(0xFFFFF3E0); fg = CustomerDetailColors.morningChipInk; label = 'Skipped';
      case 'vacation':
        bg = const Color(0xFFE3EDFC); fg = const Color(0xFF3D5896); label = 'Vacation';
      default:
        bg = const Color(0xFFF0F0F0); fg = CustomerDetailColors.onSurfaceVariant; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _DeliveryLine extends StatelessWidget {
  const _DeliveryLine({required this.line, required this.dayStatus});
  final _LineData line;
  final String dayStatus;

  @override
  Widget build(BuildContext context) {
    final isMorning = line.shift == 'morning';
    final shiftLabel = isMorning ? 'Morning' : 'Evening';
    final shiftIcon = isMorning ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined;
    final shiftBg = isMorning ? const Color(0xFFFFF8E1) : const Color(0xFFEDE7F6);
    final shiftFg = isMorning ? const Color(0xFFE65100) : const Color(0xFF4527A0);

    final String qtyText;
    final Color qtyColor;
    if (dayStatus == 'vacation') {
      qtyText = '—';
      qtyColor = const Color(0xFF3D5896);
    } else if (dayStatus == 'skipped') {
      qtyText = '0';
      qtyColor = CustomerDetailColors.morningChipInk;
    } else {
      qtyText = line.qty.toString();
      qtyColor = CustomerDetailColors.success;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: shiftBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(shiftIcon, size: 20, color: shiftFg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CustomerDetailColors.onSurface),
                ),
                Text(
                  shiftLabel,
                  style: const TextStyle(fontSize: 12, color: CustomerDetailColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            qtyText,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: qtyColor, height: 1),
          ),
        ],
      ),
    );
  }
}

// ── Day edit bottom sheet ─────────────────────────────────────────────────────

class _DayEditSheet extends StatefulWidget {
  const _DayEditSheet({
    required this.day,
    required this.repository,
    required this.onSaved,
  });

  final Map<String, dynamic> day;
  final CustomerOrderRepository repository;
  final VoidCallback onSaved;

  @override
  State<_DayEditSheet> createState() => _DayEditSheetState();
}

class _DayEditSheetState extends State<_DayEditSheet> {
  late final Map<int, int> _qtys;
  late final Map<int, int> _originalQtys;
  bool _isSaving = false;
  bool _isSkipping = false;

  @override
  void initState() {
    super.initState();
    final entries = (widget.day['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    _qtys = {
      for (final e in entries)
        (e['subscription_line_id'] as int): (e['qty'] as num?)?.toInt() ?? 1,
    };
    _originalQtys = Map.from(_qtys);
  }

  List<Map<String, dynamic>> get _entries =>
      (widget.day['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  String get _dateStr => widget.day['date'] as String? ?? '';

  String _formatDateTitle(String dateStr) {
    try {
      return DateFormat('EEEE, d MMMM').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _onSave() async {
    final changed = _entries.where((e) {
      final id = e['subscription_line_id'] as int;
      return _qtys[id] != _originalQtys[id];
    }).toList();

    if (changed.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSaving = true);
    try {
      for (final entry in changed) {
        final id = entry['subscription_line_id'] as int;
        await widget.repository.updateQty(_dateStr, id, _qtys[id] ?? 0);
      }
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.showError(context, e.toString());
      }
    }
  }

  Future<void> _onSkip() async {
    setState(() => _isSkipping = true);
    try {
      await widget.repository.skipDay(_dateStr);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        AppSnackBar.show(context, 'Day skipped.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSkipping = false);
        AppSnackBar.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CustomerDetailColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _formatDateTitle(_dateStr),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CustomerDetailColors.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          ..._entries.map(
            (e) => _StepperRow(
              entry: e,
              qty: _qtys[e['subscription_line_id'] as int] ?? 1,
              onChanged: (newQty) {
                setState(() => _qtys[e['subscription_line_id'] as int] = newQty);
              },
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: CustomerDetailColors.accent,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isSaving || _isSkipping ? null : _onSave,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: CustomerDetailColors.danger,
              side: BorderSide(color: CustomerDetailColors.danger.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isSaving || _isSkipping ? null : _onSkip,
            child: _isSkipping
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: CustomerDetailColors.danger),
                  )
                : const Text('Skip This Day', style: TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({required this.entry, required this.qty, required this.onChanged});

  final Map<String, dynamic> entry;
  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final name = entry['product_name'] as String? ?? '';
    final shift = entry['shift'] as String? ?? '';
    final shiftLabel = shift == 'morning' ? 'Morning' : 'Evening';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$name ($shiftLabel)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CustomerDetailColors.onSurface,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: CustomerDetailColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: qty > 0 ? () => onChanged(qty - 1) : null,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  color: CustomerDetailColors.accent,
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    qty.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CustomerDetailColors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: () => onChanged(qty + 1),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  color: CustomerDetailColors.accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CustomerDetailColors.border.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            message,
            style: const TextStyle(color: CustomerDetailColors.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CustomerDetailColors.accent),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
