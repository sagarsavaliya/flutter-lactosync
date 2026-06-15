import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_typography.dart';
import 'customer_dashboard_styles.dart';

// ── Header ────────────────────────────────────────────────────────────────────

class CusOrdersHeader extends StatelessWidget {
  const CusOrdersHeader({
    super.key,
    required this.month,
    required this.onMonthTap,
  });

  final DateTime month;
  final VoidCallback onMonthTap;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CusDashMetrics.horizontalPad,
        12,
        CusDashMetrics.horizontalPad,
        8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('My orders', style: CusDashText.greeting.copyWith(fontSize: 28)),
          const Spacer(),
          Material(
            color: CusDashColors.surface,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: onMonthTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: CusDashColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF283C28).withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      monthLabel,
                      style: AppText.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CusDashColors.ink,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(LucideIcons.chevronDown, size: 16, color: CusDashColors.inkMuted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class CusOrdersStatsRow extends StatelessWidget {
  const CusOrdersStatsRow({
    super.key,
    required this.delivered,
    required this.skipped,
    required this.totalLiters,
  });

  final int delivered;
  final int skipped;
  final double totalLiters;

  @override
  Widget build(BuildContext context) {
    final litersLabel = totalLiters == totalLiters.roundToDouble()
        ? '${totalLiters.toInt()} L'
        : '${totalLiters.toStringAsFixed(1)} L';

    return Row(
      children: [
        Expanded(child: _StatCard(value: '$delivered', label: 'delivered', valueColor: CusDashColors.accent)),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '$skipped',
            label: 'skipped',
            valueColor: CusDashColors.todayBorder,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: litersLabel,
            label: 'total',
            valueColor: CusDashColors.ink,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: CusDashText.whiteCard(radius: CusDashMetrics.innerRadius),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppText.meta.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CusDashColors.labelMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class CusOrdersSectionLabel extends StatelessWidget {
  const CusOrdersSectionLabel({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
      child: Text(title, style: CusDashText.sectionLabel),
    );
  }
}

// ── Order day card ────────────────────────────────────────────────────────────

enum CusOrderCardMode { upcoming, history }

class CusOrderDayCard extends StatelessWidget {
  const CusOrderDayCard({
    super.key,
    required this.day,
    required this.productLabel,
    required this.subtitle,
    required this.qtyLabel,
    required this.mode,
    this.status,
    this.isToday = false,
    this.onTap,
    this.onSkip,
    this.skipping = false,
  });

  final Map<String, dynamic> day;
  final String productLabel;
  final String subtitle;
  final String qtyLabel;
  final CusOrderCardMode mode;
  final String? status;
  final bool isToday;
  final VoidCallback? onTap;
  final VoidCallback? onSkip;
  final bool skipping;

  @override
  Widget build(BuildContext context) {
    final dateStr = day['date'] as String? ?? '';
    DateTime? date;
    try {
      date = DateTime.parse(dateStr);
    } catch (_) {}

    final dayNum = date != null ? '${date.day}' : '';
    final dow = date != null ? DateFormat('EEE').format(date).toUpperCase() : '';

    final showSkip = mode == CusOrderCardMode.upcoming && onSkip != null;
    final showStatus = mode == CusOrderCardMode.history && !isToday && status != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: CusDashColors.surface,
        borderRadius: BorderRadius.circular(CusDashMetrics.innerRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CusDashMetrics.innerRadius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CusDashMetrics.innerRadius),
              border: Border.all(color: CusDashColors.border),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF283C28).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 72,
                  decoration: BoxDecoration(
                    color: CusDashColors.accent,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(CusDashMetrics.innerRadius)),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 36,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayNum,
                        style: GoogleFonts.quicksand(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: CusDashColors.accent,
                          height: 1,
                        ),
                      ),
                      Text(
                        dow,
                        style: AppText.meta.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: CusDashColors.labelMuted,
                        ),
                      ),
                    ],
                  ),
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
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppText.body.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CusDashColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showSkip)
                  _SkipButton(onTap: onSkip!, loading: skipping)
                else if (showStatus)
                  _StatusPill(status: status!)
                else if (mode == CusOrderCardMode.history && isToday)
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Text(
                      qtyLabel,
                      style: AppText.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CusDashColors.inkMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap, required this.loading});
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: CusDashColors.background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CusDashColors.border),
            ),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: CusDashColors.accent),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.skipForward, size: 16, color: CusDashColors.labelMuted),
                      const SizedBox(height: 2),
                      Text(
                        'SKIP',
                        style: AppText.meta.copyWith(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: CusDashColors.labelMuted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isDelivered = status == 'delivered';
    final bg = isDelivered ? CusDashColors.accentLight : CusDashColors.calSkippedBg;
    final dot = isDelivered ? CusDashColors.activeInk : CusDashColors.labelMuted;
    final label = isDelivered ? 'Delivered' : (status == 'vacation' ? 'Vacation' : 'Skipped');
    final textColor = isDelivered ? CusDashColors.activeInk : CusDashColors.inkMuted;

    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppText.meta.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty / error ─────────────────────────────────────────────────────────────

class CusOrdersEmptyCard extends StatelessWidget {
  const CusOrdersEmptyCard({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: CusDashText.whiteCard(radius: CusDashMetrics.innerRadius),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppText.body.copyWith(color: CusDashColors.inkMuted),
      ),
    );
  }
}

class CusOrdersErrorCard extends StatelessWidget {
  const CusOrdersErrorCard({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: CusDashText.whiteCard(radius: CusDashMetrics.innerRadius),
      child: Column(
        children: [
          Text(
            'Could not load orders.',
            style: AppText.body.copyWith(color: CusDashColors.inkMuted),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CusDashColors.accent),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ── Month picker sheet ────────────────────────────────────────────────────────

Future<DateTime?> showCusOrdersMonthPicker({
  required BuildContext context,
  required DateTime selected,
}) {
  final now = DateTime.now();
  final months = <DateTime>[];
  for (var i = 0; i < 13; i++) {
    final d = DateTime(now.year, now.month - i);
    months.add(d);
  }

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: CusDashColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: CusDashColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Select month', style: CusDashText.cardTitle),
          const SizedBox(height: 8),
          ...months.map((m) {
            final label = DateFormat('MMMM yyyy').format(m);
            final isSelected = m.year == selected.year && m.month == selected.month;
            return ListTile(
              title: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? CusDashColors.accent : CusDashColors.ink,
                ),
              ),
              trailing: isSelected ? Icon(LucideIcons.check, color: CusDashColors.accent, size: 18) : null,
              onTap: () => Navigator.pop(ctx, m),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ── Data helpers ──────────────────────────────────────────────────────────────

class CusOrdersMonthStats {
  const CusOrdersMonthStats({
    required this.delivered,
    required this.skipped,
    required this.totalLiters,
  });

  final int delivered;
  final int skipped;
  final double totalLiters;
}

CusOrdersMonthStats cusOrdersMonthStats(List<Map<String, dynamic>> days) {
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  var delivered = 0;
  var skipped = 0;
  var liters = 0.0;

  for (final day in days) {
    final parsed = DateTime.tryParse(day['date'] as String? ?? '');
    if (parsed == null) continue;
    final d = DateTime(parsed.year, parsed.month, parsed.day);
    if (d.isAfter(today)) continue;

    final status = day['status'] as String? ?? 'no_record';
    if (status == 'delivered') {
      delivered++;
      liters += cusOrderDayQty(day);
    } else if (status == 'skipped' || status == 'vacation') {
      skipped++;
    }
  }

  return CusOrdersMonthStats(
    delivered: delivered,
    skipped: skipped,
    totalLiters: liters,
  );
}

double cusOrderDayQty(Map<String, dynamic> day) {
  final entries = (day['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  var total = 0.0;
  for (final e in entries) {
    total += (e['qty'] as num?)?.toDouble() ?? 0;
  }
  return total;
}

String cusOrderProductLabel(
  Map<String, dynamic> day,
  List<Map<String, dynamic>> consumptionRows,
) {
  final entries = (day['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  if (entries.isEmpty) return 'Delivery';

  final name = entries.first['product_name'] as String? ?? 'Product';
  for (final row in consumptionRows) {
    final pName = row['product_name'] as String? ?? '';
    if (pName.toLowerCase().contains(name.toLowerCase().split(' ').first)) {
      final rate = (row['unit_rate'] as num?)?.toDouble() ?? 0;
      return '$pName – ₹${rate.round()}';
    }
  }
  final rate = consumptionRows.isNotEmpty
      ? ((consumptionRows.first['unit_rate'] as num?)?.toDouble() ?? 0)
      : 0.0;
  return rate > 0 ? '$name – ₹${rate.round()}' : name;
}
String cusOrderQtyLabel(Map<String, dynamic> day) {
  final qty = cusOrderDayQty(day);
  if (qty <= 0) return '—';
  return qty == qty.roundToDouble() ? '${qty.toInt()} L' : '${qty.toStringAsFixed(1)} L';
}

List<Map<String, dynamic>> cusUpcomingDays(List<Map<String, dynamic>> days) {
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  return days.where((day) {
    final parsed = DateTime.tryParse(day['date'] as String? ?? '');
    if (parsed == null) return false;
    final d = DateTime(parsed.year, parsed.month, parsed.day);
    if (d.isBefore(today)) return false;
    final status = day['status'] as String? ?? '';
    return status == 'expected';
  }).toList();
}

List<Map<String, dynamic>> cusHistoryDays(List<Map<String, dynamic>> days) {
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final list = days.where((day) {
    final parsed = DateTime.tryParse(day['date'] as String? ?? '');
    if (parsed == null) return false;
    final d = DateTime(parsed.year, parsed.month, parsed.day);
    if (d.isAfter(today)) return false;
    final status = day['status'] as String? ?? '';
    return status != 'no_record';
  }).toList();
  list.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
  return list;
}
