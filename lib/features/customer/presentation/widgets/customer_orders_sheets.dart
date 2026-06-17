import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/milk_qty.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/repositories/customer_order_repository.dart';
import '../widgets/customer_dashboard_styles.dart';

// ── Day detail sheet ──────────────────────────────────────────────────────────

void showCustomerOrderDayDetailSheet({
  required BuildContext context,
  required Map<String, dynamic> day,
  required List<Map<String, dynamic>> activeSubs,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: CusDashColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => CustomerOrderDayDetailSheet(day: day, activeSubs: activeSubs),
  );
}

class CustomerOrderDayDetailSheet extends StatelessWidget {
  const CustomerOrderDayDetailSheet({
    super.key,
    required this.day,
    required this.activeSubs,
  });

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
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CusDashColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(formattedDate, style: CusDashText.cardTitle)),
              const SizedBox(width: 12),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 20),
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No delivery data for this day.',
                style: AppText.body.copyWith(color: CusDashColors.inkMuted),
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
      return entries
          .map(
            (e) => _LineData(
              productName: e['product_name'] as String? ?? '',
              shift: e['shift'] as String? ?? '',
              qty: (e['qty'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList();
    }
    return activeSubs
        .map(
          (s) => _LineData(
            productName: s['product_name'] as String? ?? '',
            shift: s['shift'] as String? ?? '',
            qty: (s['qty'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
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
        bg = CusDashColors.accentLight;
        fg = CusDashColors.activeInk;
        label = 'Delivered';
      case 'skipped':
        bg = CusDashColors.calSkippedBg;
        fg = CusDashColors.inkMuted;
        label = 'Skipped';
      case 'vacation':
        bg = const Color(0xFFE3EDFC);
        fg = const Color(0xFF3D5896);
        label = 'Vacation';
      default:
        bg = CusDashColors.background;
        fg = CusDashColors.inkMuted;
        label = status;
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

    final String qtyText;
    final Color qtyColor;
    if (dayStatus == 'vacation') {
      qtyText = '—';
      qtyColor = const Color(0xFF3D5896);
    } else if (dayStatus == 'skipped') {
      qtyText = '0';
      qtyColor = CusDashColors.todayInk;
    } else {
      qtyText = line.qty.toString();
      qtyColor = CusDashColors.accent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: CusDashColors.accentLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isMorning ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
              size: 20,
              color: CusDashColors.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName,
                  style: AppText.cardTitle.copyWith(fontSize: 14, color: CusDashColors.ink),
                ),
                Text(shiftLabel, style: AppText.meta.copyWith(color: CusDashColors.inkMuted)),
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

// ── Day edit sheet ────────────────────────────────────────────────────────────

void showCustomerOrderDayEditSheet({
  required BuildContext context,
  required Map<String, dynamic> day,
  required CustomerOrderRepository repository,
  required VoidCallback onSaved,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: CusDashColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => CustomerOrderDayEditSheet(
      day: day,
      repository: repository,
      onSaved: onSaved,
    ),
  );
}

class CustomerOrderDayEditSheet extends StatefulWidget {
  const CustomerOrderDayEditSheet({
    super.key,
    required this.day,
    required this.repository,
    required this.onSaved,
  });

  final Map<String, dynamic> day;
  final CustomerOrderRepository repository;
  final VoidCallback onSaved;

  @override
  State<CustomerOrderDayEditSheet> createState() => _CustomerOrderDayEditSheetState();
}

class _CustomerOrderDayEditSheetState extends State<CustomerOrderDayEditSheet> {
  late final Map<int, double> _qtys;
  late final Map<int, double> _originalQtys;
  bool _isSaving = false;
  bool _isSkipping = false;

  @override
  void initState() {
    super.initState();
    final entries = (widget.day['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    _qtys = {
      for (final e in entries)
        (e['subscription_line_id'] as int): nearestMilkQty(
          (e['qty'] as num?)?.toDouble() ?? 0.5,
          allowZero: true,
        ),
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
      return !milkQtysEqual(_qtys[id] ?? 0, _originalQtys[id] ?? 0);
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
                color: CusDashColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_formatDateTitle(_dateStr), style: CusDashText.cardTitle),
          const SizedBox(height: 20),
          ..._entries.map(
            (e) => _StepperRow(
              entry: e,
              qty: _qtys[e['subscription_line_id'] as int] ?? 0.5,
              onChanged: (newQty) {
                setState(() => _qtys[e['subscription_line_id'] as int] = newQty);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CusDashColors.inkMuted,
                    side: const BorderSide(color: CusDashColors.border),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving || _isSkipping
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CusDashColors.payButton,
                    side: BorderSide(color: CusDashColors.payButton.withValues(alpha: 0.5)),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving || _isSkipping ? null : _onSkip,
                  child: _isSkipping
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: CusDashColors.payButton,
                          ),
                        )
                      : const Text('Skip'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: CusDashColors.accent,
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
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({required this.entry, required this.qty, required this.onChanged});

  final Map<String, dynamic> entry;
  final double qty;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final name = entry['product_name'] as String? ?? '';
    final shift = entry['shift'] as String? ?? '';
    final shiftLabel = shift == 'morning' ? 'Morning' : 'Evening';
    final idx = kMilkQtyStepperOptions.indexWhere((v) => milkQtysEqual(v, qty));
    final canDecrease = idx > 0;
    final canIncrease = idx >= 0 && idx < kMilkQtyStepperOptions.length - 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$name ($shiftLabel)',
              style: AppText.cardTitle.copyWith(fontSize: 14, color: CusDashColors.ink),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: CusDashColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed: canDecrease ? () => onChanged(stepMilkQty(qty, -1)) : null,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  color: CusDashColors.accent,
                ),
                SizedBox(
                  width: 52,
                  child: Text(
                    milkQtyLabel(qty),
                    textAlign: TextAlign.center,
                    style: AppText.cardTitle.copyWith(fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  onPressed: canIncrease ? () => onChanged(stepMilkQty(qty, 1)) : null,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  color: CusDashColors.accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
