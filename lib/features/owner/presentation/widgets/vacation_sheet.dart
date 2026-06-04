import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'owner_design_system.dart';

class VacationSheet extends StatefulWidget {
  const VacationSheet({
    super.key,
    required this.customerName,
    this.initialStart,
    this.initialEnd,
    required this.onUpdate,
  });

  final String customerName;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final Future<void> Function(DateTime? start, DateTime? end) onUpdate;

  static Future<void> show(
    BuildContext context, {
    required String customerName,
    DateTime? initialStart,
    DateTime? initialEnd,
    required Future<void> Function(DateTime? start, DateTime? end) onUpdate,
  }) {
    return showOwnerBottomSheet<void>(
      context: context,
      child: VacationSheet(
        customerName: customerName,
        initialStart: initialStart,
        initialEnd: initialEnd,
        onUpdate: onUpdate,
      ),
    );
  }

  @override
  State<VacationSheet> createState() => _VacationSheetState();
}

class _VacationSheetState extends State<VacationSheet> {
  late DateTime? _start;
  late DateTime? _end;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? (_start ?? DateTime.now()) : (_end ?? _start ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_end != null && _end!.isBefore(picked)) _end = picked;
      } else {
        _end = picked;
      }
    });
  }

  bool get _isActiveNow {
    if (_start == null || _end == null) return false;
    final today = DateTime.now();
    final start = DateTime(_start!.year, _start!.month, _start!.day);
    final end = DateTime(_end!.year, _end!.month, _end!.day);
    final now = DateTime(today.year, today.month, today.day);
    return !now.isBefore(start) && !now.isAfter(end);
  }

  Future<void> _submit({bool clear = false}) async {
    setState(() => _saving = true);
    try {
      await widget.onUpdate(clear ? null : _start, clear ? null : _end);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppStrings.vacationPickDate;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final inkMuted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkInkMuted
        : AppColors.inkMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OwnerSheetTitle(AppStrings.vacationSheetTitle, subtitle: widget.customerName),
        const SizedBox(height: AppSpace.sm),
        Text(AppStrings.vacationHint, style: AppText.meta.copyWith(color: inkMuted)),
        const SizedBox(height: AppSpace.lg),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(isStart: true),
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: AppStrings.vacationStartLabel,
                    isDense: true,
                  ),
                  child: Text(_formatDate(_start), style: AppText.label),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: InkWell(
                onTap: () => _pickDate(isStart: false),
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: AppStrings.vacationEndLabel,
                    isDense: true,
                  ),
                  child: Text(_formatDate(_end), style: AppText.label),
                ),
              ),
            ),
          ],
        ),
        if (_isActiveNow) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            AppStrings.vacationActiveNow,
            style: AppText.meta.copyWith(color: AppColors.inkMuted),
          ),
        ],
        const SizedBox(height: AppSpace.lg),
        OwnerSheetActions(
          primaryLabel: AppStrings.vacationUpdate,
          loading: _saving,
          onPrimary: (_saving || _start == null || _end == null) ? null : () => _submit(),
          secondaryLabel: (widget.initialStart != null || widget.initialEnd != null)
              ? AppStrings.vacationClear
              : null,
          onSecondary: _saving ? null : () => _submit(clear: true),
          secondaryLoading: _saving,
        ),
      ],
    );
  }
}
