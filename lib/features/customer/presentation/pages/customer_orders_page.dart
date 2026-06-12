import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/customer_order_repository.dart';
import '../providers/customer_dashboard_provider.dart';
import '../providers/customer_order_provider.dart';

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

  void _openDaySheet(BuildContext context, Map<String, dynamic> day) {
    final status = day['status'] as String? ?? 'no_record';
    final entries = (day['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final isLocked = entries.any((e) => e['locked'] == true);

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
    } else if (status == 'expected' && isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Changes are locked — order already submitted.')),
      );
    } else if (status == 'delivered' || status == 'skipped' || status == 'vacation') {
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
      backgroundColor: CusColors.surface,
      body: RefreshIndicator(
        color: CusColors.primaryContainer,
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
              backgroundColor: CusColors.surface,
              surfaceTintColor: Colors.transparent,
              floating: true,
              snap: true,
              elevation: 0,
              titleSpacing: 20,
              title: const Text(
                'Orders',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: CusColors.primary),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.beach_access_outlined, color: CusColors.primaryContainer),
                  tooltip: 'Manage Vacation',
                  onPressed: () => context.push('/customer/vacation'),
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 4),

                  // Active subscriptions
                  dashAsync.when(
                    data: (data) {
                      final rawSubs = data['active_subscriptions'];
                      final subs = rawSubs is List
                          ? rawSubs.cast<Map<String, dynamic>>()
                          : <Map<String, dynamic>>[];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Subscriptions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: CusColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _SubscriptionsCard(subs: subs),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Month navigation
                  _MonthSelector(
                    selectedMonth: _selectedMonth,
                    canGoBack: _canGoBack,
                    canGoForward: _canGoForward,
                    onPrevious: _previousMonth,
                    onNext: _nextMonth,
                  ),
                  const SizedBox(height: 12),

                  // Calendar
                  ordersAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: CusColors.primaryContainer,
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
                      final delivered = days.where((d) => d['status'] == 'delivered').length;
                      final skipped = days.where((d) => d['status'] == 'skipped').length;
                      final vacation = days.where((d) => d['status'] == 'vacation').length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CalendarGrid(
                            year: _selectedMonth.year,
                            month: _selectedMonth.month,
                            days: days,
                            onDayTap: (day) => _openDaySheet(context, day),
                          ),
                          const SizedBox(height: 12),
                          _CalendarLegend(),
                          const SizedBox(height: 24),
                          const Text(
                            'This Month',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: CusColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _MonthlySummaryCard(
                            delivered: delivered,
                            skipped: skipped,
                            vacationDays: vacation,
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

// ── Active subscriptions card ─────────────────────────────────────────────────

class _SubscriptionsCard extends StatelessWidget {
  const _SubscriptionsCard({required this.subs});
  final List<Map<String, dynamic>> subs;

  @override
  Widget build(BuildContext context) {
    if (subs.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CusColors.outlineVariant.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(20),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: CusColors.onSurfaceVariant),
            SizedBox(width: 10),
            Text('No active subscriptions',
                style: TextStyle(color: CusColors.onSurfaceVariant, fontSize: 14)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CusColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          for (int i = 0; i < subs.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 0.5, indent: 20, endIndent: 20, color: CusColors.outlineVariant),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: CusColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.water_drop_outlined, size: 20, color: CusColors.primaryContainer),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subs[i]['product_name']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CusColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_capitalise(subs[i]['shift']?.toString() ?? '')} · qty ${subs[i]['qty'] ?? ''}',
                          style: const TextStyle(fontSize: 12, color: CusColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
}

// ── Month selector ────────────────────────────────────────────────────────────

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.selectedMonth,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime selectedMonth;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(selectedMonth);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CusColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: canGoBack ? CusColors.primaryContainer : CusColors.outlineVariant,
            ),
            onPressed: canGoBack ? onPrevious : null,
          ),
          Expanded(
            child: Text(
              monthLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CusColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: canGoForward ? CusColors.primaryContainer : CusColors.outlineVariant,
            ),
            onPressed: canGoForward ? onNext : null,
          ),
        ],
      ),
    );
  }
}

// ── Calendar grid ─────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.days,
    required this.onDayTap,
  });

  final int year;
  final int month;
  final List<Map<String, dynamic>> days;
  final void Function(Map<String, dynamic>) onDayTap;

  static const _dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    // Build lookup: dayNumber → API data
    final Map<int, Map<String, dynamic>> dayMap = {};
    for (final d in days) {
      try {
        final date = DateTime.parse(d['date'] as String);
        if (date.year == year && date.month == month) {
          dayMap[date.day] = d;
        }
      } catch (_) {}
    }

    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Dart weekday: 1=Mon … 7=Sun, so offset = weekday-1
    final offset = DateTime(year, month, 1).weekday - 1;
    final numRows = ((offset + daysInMonth) / 7).ceil();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CusColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        children: [
          // Day-of-week headers
          Row(
            children: _dayHeaders
                .map((d) => Expanded(
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: CusColors.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar rows
          for (int row = 0; row < numRows; row++)
            Row(
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final dayNum = cellIndex - offset + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 56));
                }
                return Expanded(
                  child: _DayCell(
                    dayNum: dayNum,
                    dayData: dayMap[dayNum],
                    onTap: dayMap[dayNum] != null ? () => onDayTap(dayMap[dayNum]!) : null,
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.dayNum, required this.dayData, required this.onTap});

  final int dayNum;
  final Map<String, dynamic>? dayData;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = dayData?['status'] as String? ?? 'no_record';
    final entries = (dayData?['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final isLocked = entries.any((e) => e['locked'] == true);
    final isEditable = status == 'expected' && !isLocked;
    final isViewable = status == 'delivered' || status == 'skipped' || status == 'vacation';
    final isTappable = (isEditable || isViewable) && onTap != null;

    final dotColor = _dotColor(status);
    final numColor = _numColor(status);

    return GestureDetector(
      onTap: isTappable ? onTap : null,
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: isEditable
                  ? BoxDecoration(
                      color: CusColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              alignment: Alignment.center,
              child: Text(
                '$dayNum',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: status == 'no_record' ? FontWeight.w400 : FontWeight.w600,
                  color: numColor,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _numColor(String status) {
    switch (status) {
      case 'delivered': return CusColors.successGreen;
      case 'skipped': return CusColors.warningAmber;
      case 'vacation': return CusColors.vacationBlue;
      case 'expected': return CusColors.onSurface;
      default: return CusColors.onSurfaceVariant;
    }
  }

  Color _dotColor(String status) {
    switch (status) {
      case 'delivered': return CusColors.successGreen;
      case 'skipped': return CusColors.warningAmber;
      case 'vacation': return CusColors.vacationBlue;
      case 'expected': return CusColors.outlineVariant;
      default: return Colors.transparent;
    }
  }
}

// ── Calendar legend ───────────────────────────────────────────────────────────

class _CalendarLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: CusColors.successGreen, label: 'Delivered'),
        const SizedBox(width: 16),
        _LegendDot(color: CusColors.warningAmber, label: 'Skipped'),
        const SizedBox(width: 16),
        _LegendDot(color: CusColors.vacationBlue, label: 'Vacation'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: CusColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Day detail sheet (delivered / skipped / vacation) ────────────────────────

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

    // Build display lines
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
                color: CusColors.outlineVariant,
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
                    fontSize: 18, fontWeight: FontWeight.w700, color: CusColors.onSurface,
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
                style: TextStyle(fontSize: 14, color: CusColors.onSurfaceVariant),
              ),
            )
          else
            ...lines.map((line) => _DeliveryLine(line: line, dayStatus: status)),
        ],
      ),
    );
  }

  List<_LineData> _buildLines(String status, List<Map<String, dynamic>> entries) {
    // For delivered: use actual entries if available
    if (status == 'delivered' && entries.isNotEmpty) {
      return entries.map((e) => _LineData(
        productName: e['product_name'] as String? ?? '',
        shift: e['shift'] as String? ?? '',
        qty: (e['qty'] as num?)?.toInt() ?? 0,
      )).toList();
    }
    // For skipped/vacation (or delivered with empty entries): fall back to subscriptions
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
        bg = const Color(0xFFE6F4EE); fg = CusColors.successGreen; label = 'Delivered';
      case 'skipped':
        bg = const Color(0xFFFFF3E0); fg = CusColors.warningAmber; label = 'Skipped';
      case 'vacation':
        bg = const Color(0xFFE3EDFC); fg = CusColors.vacationBlue; label = 'Vacation';
      default:
        bg = const Color(0xFFF0F0F0); fg = CusColors.onSurfaceVariant; label = status;
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

    // qty display & color
    final String qtyText;
    final Color qtyColor;
    if (dayStatus == 'vacation') {
      qtyText = '—';
      qtyColor = CusColors.vacationBlue;
    } else if (dayStatus == 'skipped') {
      qtyText = '0';
      qtyColor = CusColors.warningAmber;
    } else {
      qtyText = line.qty.toString();
      qtyColor = CusColors.successGreen;
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
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CusColors.onSurface),
                ),
                Text(
                  shiftLabel,
                  style: const TextStyle(fontSize: 12, color: CusColors.onSurfaceVariant),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: CusColors.error),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Day skipped.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSkipping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: CusColors.error),
        );
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
                color: CusColors.outlineVariant,
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
              color: CusColors.onSurface,
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
              backgroundColor: CusColors.primaryContainer,
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
              foregroundColor: CusColors.error,
              side: BorderSide(color: CusColors.error.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isSaving || _isSkipping ? null : _onSkip,
            child: _isSkipping
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: CusColors.error),
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
                color: CusColors.onSurface,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: CusColors.surfaceContainerHigh,
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
                  color: CusColors.primaryContainer,
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    qty.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CusColors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: () => onChanged(qty + 1),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  color: CusColors.primaryContainer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Monthly summary card ──────────────────────────────────────────────────────

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({
    required this.delivered,
    required this.skipped,
    required this.vacationDays,
  });

  final int delivered;
  final int skipped;
  final int vacationDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CusColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                count: delivered,
                label: 'Delivered',
                color: CusColors.successGreen,
                icon: Icons.check_circle_outline,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 0.5,
              color: CusColors.outlineVariant.withValues(alpha: 0.5),
            ),
            Expanded(
              child: _StatItem(
                count: skipped,
                label: 'Skipped',
                color: CusColors.warningAmber,
                icon: Icons.remove_circle_outline,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 0.5,
              color: CusColors.outlineVariant.withValues(alpha: 0.5),
            ),
            Expanded(
              child: _StatItem(
                count: vacationDays,
                label: 'Vacation',
                color: CusColors.vacationBlue,
                icon: Icons.beach_access_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
  });

  final int count;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: CusColors.onSurface,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CusColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
        border: Border.all(color: CusColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            message,
            style: const TextStyle(color: CusColors.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CusColors.primaryContainer),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
