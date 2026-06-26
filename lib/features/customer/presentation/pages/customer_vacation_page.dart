import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../owner/presentation/widgets/customer_detail/customer_detail_styles.dart';
import '../../../owner/presentation/widgets/customer_detail/customer_detail_widgets.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/repositories/customer_vacation_repository.dart';
import '../providers/customer_vacation_provider.dart';
import '../providers/customer_dashboard_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';

class CustomerVacationPage extends ConsumerStatefulWidget {
  const CustomerVacationPage({super.key});

  @override
  ConsumerState<CustomerVacationPage> createState() => _CustomerVacationPageState();
}

class _CustomerVacationPageState extends ConsumerState<CustomerVacationPage> {
  DateTime? _vacationStart;
  DateTime? _vacationEnd;
  String? _startError;
  String? _endError;
  bool _isSetting = false;
  bool _isCancelling = false;

  final _startController = TextEditingController();
  final _endController = TextEditingController();

  static final _displayFmt = DateFormat('d MMM yyyy');
  static final _apiFmt = DateFormat('yyyy-MM-dd');

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final oneYearLater = DateTime.now().add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: _vacationStart ?? tomorrow,
      firstDate: tomorrow,
      lastDate: oneYearLater,
    );
    if (picked == null) return;
    setState(() {
      _vacationStart = picked;
      _startController.text = _displayFmt.format(picked);
      _startError = null;
      if (_vacationEnd != null && _vacationEnd!.isBefore(picked)) {
        _vacationEnd = null;
        _endController.clear();
      }
    });
  }

  Future<void> _pickEndDate() async {
    final minDate = _vacationStart ?? DateTime.now().add(const Duration(days: 1));
    final oneYearLater = DateTime.now().add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: _vacationEnd ?? minDate,
      firstDate: minDate,
      lastDate: oneYearLater,
    );
    if (picked == null) return;
    setState(() {
      _vacationEnd = picked;
      _endController.text = _displayFmt.format(picked);
      _endError = null;
    });
  }

  Future<void> _onSetVacation() async {
    if (_vacationStart == null || _vacationEnd == null) return;
    setState(() {
      _isSetting = true;
      _startError = null;
      _endError = null;
    });
    final error = await ref.read(customerVacationProvider.notifier).setVacation(
          _apiFmt.format(_vacationStart!),
          _apiFmt.format(_vacationEnd!),
        );
    if (!mounted) return;
    setState(() => _isSetting = false);
    if (error == null) {
      setState(() {
        _vacationStart = null;
        _vacationEnd = null;
        _startController.clear();
        _endController.clear();
      });
      AppSnackBar.show(context, "Vacation set. You'll receive a WhatsApp confirmation.");
    } else if (error.contains('vacation_end') || error.toLowerCase().contains('end must be on or after')) {
      setState(() => _endError = error);
    } else {
      AppSnackBar.showError(context, error);
    }
  }

  Future<void> _onCancelVacation() async {
    setState(() => _isCancelling = true);
    final error = await ref.read(customerVacationProvider.notifier).cancel();
    if (!mounted) return;
    setState(() => _isCancelling = false);
    if (error == null) {
      AppSnackBar.show(context, 'Vacation cancelled.');
    } else {
      AppSnackBar.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vacationAsync = ref.watch(customerVacationProvider);

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      appBar: AppBar(
        backgroundColor: CustomerDetailColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: CustomerDetailColors.accent),
        title: Text(
          'Vacation',
          style: AppText.screenTitle.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: CustomerDetailColors.accent,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: CustomerDetailColors.accent,
        onRefresh: () => ref.read(customerVacationProvider.notifier).load(),
        child: vacationAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: CustomerDetailColors.accent),
          ),
          error: (error, _) => _ErrorBody(
            message: error.toString(),
            onRetry: () => ref.read(customerVacationProvider.notifier).load(),
          ),
          data: (vacation) {
            if (vacation != null && vacation.hasVacation) {
              return _VacationActiveBody(
                vacation: vacation,
                isCancelling: _isCancelling,
                onCancel: _onCancelVacation,
              );
            }
            final dashData = ref.watch(customerDashboardProvider).valueOrNull;
            final subs = (dashData?['active_subscriptions'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
            final shift = subs.isNotEmpty
                ? (subs.first['shift'] as String? ?? 'morning')
                : 'morning';
            final shiftLabel = shift == 'evening' ? 'evening' : 'morning';
            return _NoVacationBody(
              startController: _startController,
              endController: _endController,
              vacationStart: _vacationStart,
              vacationEnd: _vacationEnd,
              startError: _startError,
              endError: _endError,
              isSetting: _isSetting,
              deliveryShiftLabel: shiftLabel,
              onPickStart: _pickStartDate,
              onPickEnd: _pickEndDate,
              onSetVacation: _onSetVacation,
            );
          },
        ),
      ),
    );
  }
}

class _NoVacationBody extends StatelessWidget {
  const _NoVacationBody({
    required this.startController,
    required this.endController,
    required this.vacationStart,
    required this.vacationEnd,
    required this.startError,
    required this.endError,
    required this.isSetting,
    required this.deliveryShiftLabel,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onSetVacation,
  });

  final TextEditingController startController;
  final TextEditingController endController;
  final DateTime? vacationStart;
  final DateTime? vacationEnd;
  final String? startError;
  final String? endError;
  final bool isSetting;
  final String deliveryShiftLabel;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onSetVacation;

  bool get _canSubmit => vacationStart != null && vacationEnd != null;

  String? get _nextDeliveryNote {
    if (vacationEnd == null) return null;
    final resume = vacationEnd!.add(const Duration(days: 1));
    final fmt = DateFormat('d MMM yyyy');
    return 'Next delivery: ${fmt.format(resume)} ($deliveryShiftLabel shift)';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CustomerDetailColors.surface,
              borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
              border: Border.all(color: CustomerDetailColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: CustomerDetailColors.successBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(LucideIcons.truck, color: CustomerDetailColors.success, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deliveries active',
                        style: AppText.cardTitle.copyWith(color: CustomerDetailColors.onSurface),
                      ),
                      Text(
                        'Pause when away — billing stops automatically.',
                        style: AppText.meta.copyWith(color: CustomerDetailColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Plan a vacation',
                  style: AppText.cardTitle.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pause deliveries for a date range. No milk is delivered on the days you select.',
                  style: AppText.meta.copyWith(color: CustomerDetailColors.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: onPickStart,
                  child: AbsorbPointer(
                    child: AppTextField(
                      label: 'Pause deliveries from',
                      hint: 'First day without delivery',
                      controller: startController,
                      errorText: startError,
                      suffixIcon: LucideIcons.calendar,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onPickEnd,
                  child: AbsorbPointer(
                    child: AppTextField(
                      label: 'Last day without delivery',
                      hint: 'Last paused day (inclusive)',
                      controller: endController,
                      errorText: endError,
                      suffixIcon: LucideIcons.calendar,
                    ),
                  ),
                ),
                if (_nextDeliveryNote != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _nextDeliveryNote!,
                    style: AppText.meta.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CustomerDetailColors.accent,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: (_canSubmit && !isSetting) ? onSetVacation : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: CustomerDetailColors.accent,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: isSetting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Set vacation'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VacationActiveBody extends StatelessWidget {
  const _VacationActiveBody({
    required this.vacation,
    required this.isCancelling,
    required this.onCancel,
  });

  final VacationData vacation;
  final bool isCancelling;
  final VoidCallback onCancel;

  static final _displayFmt = DateFormat('d MMM yyyy');

  String get _formattedRange {
    final start = _displayFmt.format(DateTime.parse(vacation.start!));
    final end = _displayFmt.format(DateTime.parse(vacation.end!));
    return '$start – $end';
  }

  String get _resumeLabel {
    final end = DateTime.parse(vacation.end!);
    final resume = end.add(const Duration(days: 1));
    return 'Next delivery from ${_displayFmt.format(resume)}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
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
                Row(
                  children: [
                    Icon(LucideIcons.plane, color: CustomerDetailColors.accent, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'On vacation',
                      style: AppText.cardTitle.copyWith(color: CustomerDetailColors.onSurface),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_formattedRange, style: AppText.body.copyWith(color: CustomerDetailColors.bodyInk)),
                const SizedBox(height: 4),
                Text(
                  'No deliveries on these dates.',
                  style: AppText.meta.copyWith(color: CustomerDetailColors.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  _resumeLabel,
                  style: AppText.meta.copyWith(
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CustomerDetailVacationCard(
            isOnVacation: true,
            onPauseTap: isCancelling ? () {} : onCancel,
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message, style: AppText.body, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: CustomerDetailColors.accent),
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
