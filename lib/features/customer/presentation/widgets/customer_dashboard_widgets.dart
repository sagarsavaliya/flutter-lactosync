import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../owner/domain/entities/owner_models.dart';
import '../../../owner/presentation/widgets/customer_detail/customer_detail_widgets.dart';
import '../providers/customer_auth_provider.dart';
import '../providers/customer_dashboard_provider.dart';
import '../providers/customer_order_provider.dart';
import 'customer_orders_sheets.dart';
import '../../data/repositories/customer_vacation_repository.dart';
import '../providers/customer_vacation_provider.dart';
import 'customer_dashboard_styles.dart';

// ── Header ────────────────────────────────────────────────────────────────────

class CusDashHeader extends StatelessWidget {
  const CusDashHeader({
    super.key,
    required this.farmName,
    required this.firstName,
  });

  final String farmName;
  final String firstName;

  @override
  Widget build(BuildContext context) {
    final greeting = firstName.isNotEmpty ? 'Hello, $firstName' : 'Hello';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CusDashMetrics.horizontalPad,
        8,
        CusDashMetrics.horizontalPad,
        4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (farmName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: CusDashColors.accentLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: CusDashColors.accentBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.home, size: 14, color: CusDashColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        farmName,
                        style: AppText.meta.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: CusDashColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: CusDashColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: CusDashColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF283C28).withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(LucideIcons.bell, size: 20, color: CusDashColors.ink),
                    Positioned(
                      top: 10,
                      right: 11,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(greeting, style: CusDashText.greeting),
        ],
      ),
    );
  }
}

// ── Next delivery ─────────────────────────────────────────────────────────────

class CusDashNextDeliveryCard extends ConsumerStatefulWidget {
  const CusDashNextDeliveryCard({
    super.key,
    required this.date,
    required this.dateLabel,
    required this.shiftLabel,
    required this.isMorning,
    required this.productLine,
    this.day,
    this.canEdit = false,
  });

  final DateTime date;
  final String dateLabel;
  final String shiftLabel;
  final bool isMorning;
  final String productLine;
  final Map<String, dynamic>? day;
  final bool canEdit;

  @override
  ConsumerState<CusDashNextDeliveryCard> createState() =>
      _CusDashNextDeliveryCardState();
}

class _CusDashNextDeliveryCardState extends ConsumerState<CusDashNextDeliveryCard> {
  bool _editing = false;

  Future<void> _edit() async {
    final day = widget.day;
    if (day == null) return;
    setState(() => _editing = true);
    try {
      final repo = ref.read(customerOrderRepositoryProvider);
      final monthKey =
          '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}';
      showCustomerOrderDayEditSheet(
        context: context,
        day: day,
        repository: repo,
        onSaved: () {
          ref.invalidate(customerDashboardProvider);
          ref.invalidate(customerOrdersProvider(monthKey));
        },
      );
    } finally {
      if (mounted) setState(() => _editing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: CusDashText.whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: CusDashColors.accentLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(LucideIcons.truck, size: 22, color: CusDashColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _ShiftChip(label: widget.shiftLabel, isMorning: widget.isMorning),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: CusDashColors.accentLight,
                            borderRadius: BorderRadius.circular(CusDashMetrics.chipRadius),
                          ),
                          child: Text(
                            'NEXT DELIVERY',
                            style: AppText.meta.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: CusDashColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(widget.dateLabel, style: CusDashText.cardTitle),
                    const SizedBox(height: 4),
                    Text(
                      widget.productLine,
                      style: AppText.body.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: CusDashColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.canEdit && widget.day != null)
                Material(
                  color: CusDashColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _editing ? null : _edit,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CusDashColors.border),
                      ),
                      child: _editing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: CusDashColors.accent,
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.pencil,
                                  size: 16,
                                  color: CusDashColors.accent,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'EDIT',
                                  style: AppText.meta.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: CusDashColors.accent,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  const _ShiftChip({required this.label, required this.isMorning});
  final String label;
  final bool isMorning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: CusDashColors.morningChipBg,
        border: Border.all(color: CusDashColors.morningChipBorder),
        borderRadius: BorderRadius.circular(CusDashMetrics.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMorning ? LucideIcons.sun : LucideIcons.moon,
            size: 12,
            color: CusDashColors.morningChipInk,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppText.meta.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: CusDashColors.morningChipInk,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Monthly summary ───────────────────────────────────────────────────────────

class CusDashMonthlySummaryCard extends StatelessWidget {
  const CusDashMonthlySummaryCard({
    super.key,
    required this.month,
    required this.deliveredLiters,
    required this.billAmount,
    required this.daysLabel,
    required this.progress,
    required this.footerText,
    this.isLoading = false,
  });

  final DateTime month;
  final double deliveredLiters;
  final double billAmount;
  final String daysLabel;
  final double progress;
  final String footerText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    final monthLabel = DateFormat('MMMM yyyy').format(month);
    final litersLabel = deliveredLiters == deliveredLiters.roundToDouble()
        ? '${deliveredLiters.toInt()} L'
        : '${deliveredLiters.toStringAsFixed(1)} L';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CusDashColors.monthCard,
        borderRadius: BorderRadius.circular(CusDashMetrics.cardRadius),
        boxShadow: [
          BoxShadow(
            color: CusDashColors.monthCard.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel,
            style: AppText.cardTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _MonthStat(
                    value: litersLabel,
                    label: 'Delivered',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MonthStat(
                    value: '₹${fmt.format(billAmount.round())}',
                    label: 'Bill amount',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MonthStat(value: daysLabel, label: 'Days'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: CusDashColors.progressTrack,
                valueColor: const AlwaysStoppedAnimation(CusDashColors.progressFill),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                footerText,
                style: AppText.meta.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MonthStat extends StatelessWidget {
  const _MonthStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: CusDashColors.monthStatBg,
        borderRadius: BorderRadius.circular(CusDashMetrics.innerRadius),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppText.meta.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delivery calendar ─────────────────────────────────────────────────────────

class CusDashDeliveryCalendar extends ConsumerStatefulWidget {
  const CusDashDeliveryCalendar({
    super.key,
    required this.month,
    required this.days,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final List<Map<String, dynamic>> days;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  ConsumerState<CusDashDeliveryCalendar> createState() =>
      _CusDashDeliveryCalendarState();
}

class _CusDashDeliveryCalendarState extends ConsumerState<CusDashDeliveryCalendar> {
  static const _dow = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _crossSpacing = 6.0;
  static const _mainSpacing = 6.0;

  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _dragging = false;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _minSelectable => _today.add(const Duration(days: 1));

  String get _monthKey =>
      '${widget.month.year}-${widget.month.month.toString().padLeft(2, '0')}';

  bool _canSelect(DateTime date) => !date.isBefore(_minSelectable);

  bool _isInSelection(DateTime date) {
    if (_rangeStart == null || _rangeEnd == null) return false;
    final lo = _rangeStart!.isBefore(_rangeEnd!) ? _rangeStart! : _rangeEnd!;
    final hi = _rangeStart!.isBefore(_rangeEnd!) ? _rangeEnd! : _rangeStart!;
    return !date.isBefore(lo) && !date.isAfter(hi);
  }

  DateTime? _posToDate(
    Offset pos,
    double cellSize,
    int leading,
    int daysInMonth,
    int rowCount,
  ) {
    final strideX = cellSize + _crossSpacing;
    final strideY = cellSize + _mainSpacing;
    final col = (pos.dx / strideX).floor().clamp(0, 6);
    final row = (pos.dy / strideY).floor().clamp(0, rowCount - 1);
    // Ignore taps in the vertical gap between rows.
    final yInStride = pos.dy - row * strideY;
    if (yInStride > cellSize) return null;
    final index = row * 7 + col;
    if (index < leading || index >= leading + daysInMonth) return null;
    final d = index - leading + 1;
    return DateTime(widget.month.year, widget.month.month, d);
  }

  void _clearSelection() {
    _rangeStart = null;
    _rangeEnd = null;
    _dragging = false;
  }

  void _onPointerDown(
    Offset pos,
    double cellSize,
    int leading,
    int daysInMonth,
    int rowCount,
  ) {
    final vacation = ref.read(customerVacationProvider).valueOrNull;
    if (vacation?.hasVacation == true) {
      AppSnackBar.show(
        context,
        'Clear your current vacation before setting a new one.',
      );
      return;
    }

    final date = _posToDate(pos, cellSize, leading, daysInMonth, rowCount);
    if (date == null || !_canSelect(date)) return;
    setState(() {
      _dragging = true;
      _rangeStart = date;
      _rangeEnd = date;
    });
  }

  void _onPointerMove(
    Offset pos,
    double cellSize,
    int leading,
    int daysInMonth,
    int rowCount,
  ) {
    if (!_dragging) return;
    final date = _posToDate(pos, cellSize, leading, daysInMonth, rowCount);
    if (date == null || !_canSelect(date)) return;
    if (_sameDay(_rangeEnd, date)) return;
    setState(() => _rangeEnd = date);
  }

  bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isVacationDay(DateTime date, VacationData? vacation, String? apiStatus) {
    if (apiStatus == 'vacation') return true;
    if (vacation == null || !vacation.hasVacation) return false;
    final start = DateTime.parse(vacation.start!);
    final end = DateTime.parse(vacation.end!);
    final d = DateTime(date.year, date.month, date.day);
    final lo = DateTime(start.year, start.month, start.day);
    final hi = DateTime(end.year, end.month, end.day);
    return !d.isBefore(lo) && !d.isAfter(hi);
  }

  Future<void> _refreshAfterVacationChange() async {
    ref.invalidate(customerVacationProvider);
    ref.invalidate(customerDashboardProvider);
    ref.invalidate(customerOrdersProvider(_monthKey));
    await ref.read(customerOrdersProvider(_monthKey).future);
  }

  Future<void> _cancelVacation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear vacation',
          style: AppText.cardTitle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: CusDashColors.ink,
          ),
        ),
        content: Text(
          'Remove your vacation dates and resume regular deliveries?',
          style: AppText.body.copyWith(color: CusDashColors.inkMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppText.body.copyWith(color: CusDashColors.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Clear vacation',
              style: AppText.body.copyWith(
                fontWeight: FontWeight.w700,
                color: CusDashColors.calVacationInk,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await ref.read(customerVacationProvider.notifier).cancel();
    if (!mounted) return;
    if (error != null) {
      AppSnackBar.showError(context, error);
      return;
    }

    AppSnackBar.show(context, 'Vacation cleared.');
    await _refreshAfterVacationChange();
  }

  Future<void> _onPointerUp() async {
    if (!_dragging) return;
    final start = _rangeStart;
    final end = _rangeEnd;
    setState(() => _dragging = false);

    if (start == null || end == null) {
      setState(() => _clearSelection());
      return;
    }

    final stopFrom = start.isBefore(end) ? start : end;
    final stopUntil = start.isBefore(end) ? end : start;
    final resumeOn = stopUntil.add(const Duration(days: 1));

    final confirmed = await showCusVacationConfirmDialog(
      context: context,
      stopFrom: stopFrom,
      resumeOn: resumeOn,
    );

    if (!mounted) return;
    setState(() => _clearSelection());

    if (confirmed != true) return;

    final apiFmt = DateFormat('yyyy-MM-dd');
    final error = await ref.read(customerVacationProvider.notifier).setVacation(
          apiFmt.format(stopFrom),
          apiFmt.format(stopUntil),
        );

    if (!mounted) return;
    if (error != null) {
      AppSnackBar.showError(context, error);
      return;
    }

    AppSnackBar.show(context, 'Vacation set for selected dates.');
    await _refreshAfterVacationChange();
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;
    final vacation = ref.watch(customerVacationProvider).valueOrNull;
    final hasVacation = vacation?.hasVacation == true;
    final daysInMonth = DateUtils.getDaysInMonth(widget.month.year, widget.month.month);
    final leading = DateTime(widget.month.year, widget.month.month, 1).weekday - 1;
    final monthShort = DateFormat('MMM').format(widget.month);

    final byDate = <int, Map<String, dynamic>>{};
    for (final day in widget.days) {
      final parsed = DateTime.tryParse(day['date'] as String? ?? '');
      if (parsed != null &&
          parsed.year == widget.month.year &&
          parsed.month == widget.month.month) {
        byDate[parsed.day] = day;
      }
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: CusDashText.whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Delivery calendar', style: CusDashText.cardTitle),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: CusDashColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CusDashColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MonthNavBtn(
                      icon: LucideIcons.chevronLeft,
                      enabled: widget.canGoBack,
                      onTap: widget.onPrevious,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        monthShort,
                        style: AppText.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: CusDashColors.ink,
                        ),
                      ),
                    ),
                    _MonthNavBtn(
                      icon: LucideIcons.chevronRight,
                      enabled: widget.canGoForward,
                      onTap: widget.onNext,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasVacation
                ? 'Vacation is active — clear it below to set new dates'
                : 'Drag across future dates to mark vacation',
            style: AppText.meta.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CusDashColors.labelMuted,
            ),
          ),
          if (hasVacation) ...[
            const SizedBox(height: 10),
            _CusDashActiveVacationBanner(
              vacation: vacation!,
              onClear: _cancelVacation,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: _dow
                .map(
                  (w) => Expanded(
                    child: Text(
                      w,
                      textAlign: TextAlign.center,
                      style: AppText.meta.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: CusDashColors.labelMuted,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = (constraints.maxWidth - _crossSpacing * 6) / 7;
              final rowCount = ((leading + daysInMonth + 6) / 7).ceil();
              final gridHeight =
                  cellSize * rowCount + _mainSpacing * (rowCount - 1);

              return SizedBox(
                height: gridHeight,
                child: Stack(
                  children: [
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: _mainSpacing,
                        crossAxisSpacing: _crossSpacing,
                        childAspectRatio: 1,
                      ),
                      itemCount: leading + daysInMonth,
                      itemBuilder: (_, index) {
                        if (index < leading) return const SizedBox.shrink();
                        final d = index - leading + 1;
                        final date = DateTime(widget.month.year, widget.month.month, d);
                        final apiStatus = byDate[d]?['status'] as String?;
                        return _CusDashCalCell(
                          day: d,
                          date: date,
                          today: today,
                          dayData: byDate[d],
                          isVacation: _isVacationDay(date, vacation, apiStatus),
                          isSelected: _isInSelection(date),
                        );
                      },
                    ),
                    Positioned.fill(
                      child: Listener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: (e) => _onPointerDown(
                          e.localPosition,
                          cellSize,
                          leading,
                          daysInMonth,
                          rowCount,
                        ),
                        onPointerMove: (e) => _onPointerMove(
                          e.localPosition,
                          cellSize,
                          leading,
                          daysInMonth,
                          rowCount,
                        ),
                        onPointerUp: (_) => _onPointerUp(),
                        onPointerCancel: (_) => setState(() => _clearSelection()),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          const _CusDashCalLegend(),
        ],
      ),
    );
  }
}

class _CusDashActiveVacationBanner extends StatelessWidget {
  const _CusDashActiveVacationBanner({
    required this.vacation,
    required this.onClear,
  });

  final VacationData vacation;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM');
    final start = DateTime.parse(vacation.start!);
    final end = DateTime.parse(vacation.end!);
    final rangeLabel = start.month == end.month && start.year == end.year
        ? '${fmt.format(start)} – ${fmt.format(end)}'
        : '${fmt.format(start)} – ${DateFormat('d MMM yyyy').format(end)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CusDashColors.calVacationBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CusDashColors.calVacationBorder),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.plane, size: 16, color: CusDashColors.calVacationInk),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Vacation: $rangeLabel',
              style: AppText.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CusDashColors.calVacationInk,
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Clear',
              style: AppText.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: CusDashColors.calVacationInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirms a vacation range picked on the dashboard calendar.
Future<bool?> showCusVacationConfirmDialog({
  required BuildContext context,
  required DateTime stopFrom,
  required DateTime resumeOn,
}) {
  final fmt = DateFormat('d MMM yyyy');
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Set vacation',
        style: AppText.cardTitle.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: CusDashColors.ink,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CusVacationDateRow(
            label: 'Delivery stop from',
            value: fmt.format(stopFrom),
          ),
          const SizedBox(height: 12),
          _CusVacationDateRow(
            label: 'Start delivery on',
            value: fmt.format(resumeOn),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: const BorderSide(color: CusDashColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: CusDashColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: CusDashColors.accent,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CusVacationDateRow extends StatelessWidget {
  const _CusVacationDateRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: AppText.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CusDashColors.inkMuted,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppText.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: CusDashColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthNavBtn extends StatelessWidget {
  const _MonthNavBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? CusDashColors.inkMuted : CusDashColors.calFutureBorder,
        ),
      ),
    );
  }
}

class _CusDashCalCell extends StatelessWidget {
  const _CusDashCalCell({
    required this.day,
    required this.date,
    required this.today,
    required this.dayData,
    this.isVacation = false,
    this.isSelected = false,
  });

  final int day;
  final DateTime date;
  final DateTime today;
  final Map<String, dynamic>? dayData;
  final bool isVacation;
  final bool isSelected;

  double _totalQty() {
    final entries = (dayData?['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    var total = 0.0;
    for (final e in entries) {
      total += (e['qty'] as num?)?.toDouble() ?? 0;
    }
    return total;
  }

  String _qtyLabel(double qty) {
    if (qty <= 0) return '';
    return qty == qty.roundToDouble() ? qty.toInt().toString() : qty.toStringAsFixed(1);
  }

  bool _showsConsumption(String status, double qty, bool isFuture, bool isToday) {
    if (qty <= 0) return false;
    if (status == 'skipped' || status == 'vacation') return false;
    if (isFuture) return false;
    if (status == 'delivered' || status == 'pending') return true;
    if (status == 'expected' && isToday) return true;
    // Before pending day-status is deployed, billable logs still carry qty in entries.
    if (status == 'no_record') return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isFuture = date.isAfter(today);
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    final status = dayData?['status'] as String? ?? 'no_record';
    final qty = _totalQty();
    final qtyLabel = _qtyLabel(qty);
    final showQty = _showsConsumption(status, qty, isFuture, isToday);
    final skipped = !isFuture && status == 'skipped';

    late Color bg;
    late Color borderColor;
    late String center;
    late Color centerColor;
    late Color numColor;
    var borderWidth = 1.0;

    if (isVacation || status == 'vacation') {
      bg = CusDashColors.calVacationBg;
      borderColor = CusDashColors.calVacationBorder;
      center = 'V';
      centerColor = CusDashColors.calVacationInk;
      numColor = CusDashColors.calVacationInk;
    } else if (isFuture) {
      bg = CusDashColors.surface;
      borderColor = CusDashColors.calFutureBorder;
      center = '';
      centerColor = CusDashColors.calFutureBorder;
      numColor = CusDashColors.calFutureBorder;
    } else if (isToday && (status == 'expected' || status == 'pending' || status == 'delivered')) {
      bg = CusDashColors.todayBg;
      borderColor = CusDashColors.todayBorder;
      borderWidth = 1.5;
      center = qtyLabel.isEmpty ? '·' : qtyLabel;
      centerColor = CusDashColors.todayInk;
      numColor = CusDashColors.todayInk;
    } else if (skipped) {
      bg = CusDashColors.calSkippedBg;
      borderColor = CusDashColors.calSkippedBorder;
      center = '–';
      centerColor = CusDashColors.labelMuted;
      numColor = CusDashColors.labelMuted;
    } else if (showQty) {
      bg = CusDashColors.calDelivered;
      borderColor = CusDashColors.calDelivered;
      center = qtyLabel;
      centerColor = Colors.white;
      numColor = const Color(0xFF9FCBAC);
    } else if (!isFuture) {
      bg = CusDashColors.calSkippedBg;
      borderColor = CusDashColors.calSkippedBorder;
      center = '–';
      centerColor = CusDashColors.labelMuted;
      numColor = CusDashColors.labelMuted;
    } else {
      bg = CusDashColors.surface;
      borderColor = CusDashColors.calFutureBorder;
      center = '';
      centerColor = CusDashColors.calFutureBorder;
      numColor = CusDashColors.calFutureBorder;
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF5C7EAE) : borderColor,
          width: isSelected ? 2 : borderWidth,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isSelected)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF5C7EAE).withValues(alpha: 0.22),
                ),
              ),
            ),
          if (day <= 31)
            Positioned(
              top: 4,
              left: 6,
              child: Text(
                '$day',
                style: AppText.meta.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: numColor,
                  height: 1,
                ),
              ),
            ),
          if (center.isNotEmpty)
            Text(
              center,
              style: AppText.cardTitle.copyWith(
                fontSize: center.length > 2 ? 11 : 15,
                fontWeight: FontWeight.w800,
                color: centerColor,
                height: 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _CusDashCalLegend extends StatelessWidget {
  const _CusDashCalLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: const [
        _LegendDot(color: CusDashColors.calDelivered, label: 'Delivered'),
        _LegendDot(color: CusDashColors.todayBorder, label: 'Today', hollow: true, fill: CusDashColors.todayBg),
        _LegendDot(color: CusDashColors.calSkippedBorder, label: 'Skipped', hollow: true, fill: CusDashColors.calSkippedBg),
        _LegendDot(color: CusDashColors.calVacationBorder, label: 'Vacation', hollow: true, fill: CusDashColors.calVacationBg),
        _LegendDot(color: CusDashColors.calFutureBorder, label: 'Upcoming', dashed: true),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.hollow = false,
    this.fill,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool hollow;
  final Color? fill;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: hollow ? (fill ?? CusDashColors.surface) : color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color,
              width: dashed ? 1.2 : 1,
              style: dashed ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.meta.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CusDashColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

// ── Payment ───────────────────────────────────────────────────────────────────

class CusDashPaymentCard extends StatelessWidget {
  const CusDashPaymentCard({
    super.key,
    required this.balance,
    required this.billLabel,
    required this.dueLabel,
    required this.upiVpa,
    required this.upiPayeeName,
  });

  final double balance;
  final String billLabel;
  final String dueLabel;
  final String? upiVpa;
  final String? upiPayeeName;

  Future<void> _payNow() async {
    if (upiVpa == null || upiVpa!.isEmpty) return;
    final payee = Uri.encodeComponent(upiPayeeName ?? 'Dairy');
    final vpa = Uri.encodeComponent(upiVpa!);
    final amount = balance.toStringAsFixed(2);
    final uri = Uri.parse('upi://pay?pa=$vpa&pn=$payee&am=$amount&cu=INR&tn=Dairy+Payment');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en_IN');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: CusDashText.whiteCard(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CusDashColors.payIconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(LucideIcons.wallet, size: 20, color: CusDashColors.payBrown),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending balance',
                      style: AppText.meta.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CusDashColors.payBrownMuted,
                      ),
                    ),
                    Text(
                      '₹${fmt.format(balance.round())}',
                      style: GoogleFonts.quicksand(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: CusDashColors.payBrown,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    billLabel,
                    style: AppText.meta.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CusDashColors.labelMuted,
                    ),
                  ),
                  Text(
                    dueLabel,
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: CusDashColors.payBrown,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: upiVpa != null && upiVpa!.isNotEmpty ? _payNow : null,
              style: FilledButton.styleFrom(
                backgroundColor: CusDashColors.payButton,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                elevation: 4,
                shadowColor: CusDashColors.payButton.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(LucideIcons.wallet, size: 18),
              label: Text(
                'Pay now',
                style: AppText.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subscription ──────────────────────────────────────────────────────────────

class CusDashSubscriptionCard extends StatelessWidget {
  const CusDashSubscriptionCard({
    super.key,
    required this.productLabel,
    required this.shiftLabel,
    required this.isMorning,
    required this.qtyPerDay,
    required this.isActive,
  });

  final String productLabel;
  final String shiftLabel;
  final bool isMorning;
  final double qtyPerDay;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final qtyLabel = qtyPerDay == qtyPerDay.roundToDouble()
        ? '${qtyPerDay.toInt()} L / day'
        : '${qtyPerDay.toStringAsFixed(1)} L / day';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CusDashText.whiteCard(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: CusDashColors.accentLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(LucideIcons.milk, size: 22, color: CusDashColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productLabel,
                  style: AppText.cardTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CusDashColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ShiftChip(label: shiftLabel, isMorning: isMorning),
                    const SizedBox(width: 8),
                    Text(
                      qtyLabel,
                      style: AppText.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CusDashColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: CusDashColors.activeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: CusDashColors.activeInk,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Active',
                    style: AppText.meta.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: CusDashColors.activeInk,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class CusDashQuickActions extends ConsumerStatefulWidget {
  const CusDashQuickActions({super.key, this.ownerMobile});
  final String? ownerMobile;

  @override
  ConsumerState<CusDashQuickActions> createState() => _CusDashQuickActionsState();
}

class _CusDashQuickActionsState extends ConsumerState<CusDashQuickActions> {
  bool _skipping = false;

  Future<void> _skipTomorrow() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final dateStr = DateFormat('yyyy-MM-dd').format(tomorrow);
    setState(() => _skipping = true);
    try {
      await ref.read(customerOrderRepositoryProvider).skipDay(dateStr);
      ref.invalidate(customerDashboardProvider);
      if (mounted) AppSnackBar.show(context, "Tomorrow's delivery skipped");
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _skipping = false);
    }
  }

  Future<void> _whatsApp() async {
    final mobile = widget.ownerMobile;
    if (mobile == null || mobile.isEmpty) return;
    final cleaned = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    final number = cleaned.length == 10 ? '91$cleaned' : cleaned;
    final uri = Uri.parse('https://wa.me/$number');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) AppSnackBar.show(context, 'Could not open WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(icon: LucideIcons.skipForward, label: 'Skip\ntomorrow', loading: _skipping, onTap: _skipTomorrow),
      _QuickAction(icon: LucideIcons.plane, label: 'Vacation\nmode', onTap: () => context.push('/customer/vacation')),
      _QuickAction(icon: LucideIcons.pencil, label: 'Change\nplan', onTap: () => context.go('/customer/orders')),
      _QuickAction(icon: LucideIcons.messageCircle, label: 'WhatsApp\ndairy', onTap: _whatsApp),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 18, 2, 11),
          child: Text('QUICK ACTIONS', style: CusDashText.sectionLabel),
        ),
        Row(
          children: actions
              .map(
                (a) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: actions.indexOf(a) < actions.length - 1 ? 8 : 0),
                    child: _QuickActionTile(action: a),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});
  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CusDashColors.surface,
      borderRadius: BorderRadius.circular(CusDashMetrics.innerRadius),
      child: InkWell(
        onTap: action.loading ? null : action.onTap,
        borderRadius: BorderRadius.circular(CusDashMetrics.innerRadius),
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CusDashMetrics.innerRadius),
            border: Border.all(color: CusDashColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (action.loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: CusDashColors.accent),
                )
              else
                Icon(action.icon, size: 22, color: CusDashColors.accent),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: AppText.meta.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CusDashColors.ink,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Branding footer ───────────────────────────────────────────────────────────

class CusDashBrandingFooter extends StatelessWidget {
  const CusDashBrandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 5),
      child: Center(
        child: Text.rich(
          TextSpan(
            style: AppText.meta.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CusDashColors.labelMuted,
              height: 1.4,
            ),
            children: [
              const TextSpan(text: 'Made with '),
              const TextSpan(
                text: 'love',
                style: TextStyle(
                  color: Color(0xFFD95858),
                  fontWeight: FontWeight.w700,
                ),
              ), 
               const TextSpan(text: ' by '),
              const TextSpan(text: 'Akshara Technologies', 
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD95858),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Section label wrapper ─────────────────────────────────────────────────────

class CusDashSectionLabel extends StatelessWidget {
  const CusDashSectionLabel({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 11),
      child: Text(title, style: CusDashText.sectionLabel),
    );
  }
}

// Re-export consumption card styling via owner widget with section label.
Widget cusDashConsumptionSection({
  required List<ConsumptionRow> rows,
  required double grandTotal,
}) {
  if (rows.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'No consumption recorded this month.',
        style: AppText.body.copyWith(color: CusDashColors.inkMuted),
      ),
    );
  }
  return CustomerDetailConsumptionCard(rows: rows, grandTotal: grandTotal);
}
