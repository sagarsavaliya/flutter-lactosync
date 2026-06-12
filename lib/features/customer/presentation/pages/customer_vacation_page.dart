import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/repositories/customer_vacation_repository.dart';
import '../providers/customer_vacation_provider.dart';

/// CA-14 — Vacation management screen.
/// Pushed from the Profile tab via context.push('/customer/vacation').
class CustomerVacationPage extends ConsumerStatefulWidget {
  const CustomerVacationPage({super.key});

  @override
  ConsumerState<CustomerVacationPage> createState() =>
      _CustomerVacationPageState();
}

class _CustomerVacationPageState extends ConsumerState<CustomerVacationPage> {
  // ── "Set vacation" form state ──────────────────────────────────────────────
  DateTime? _vacationStart;
  DateTime? _vacationEnd;
  String? _startError;
  String? _endError;
  bool _isSetting = false;
  bool _isCancelling = false;

  final _startController = TextEditingController();
  final _endController   = TextEditingController();

  static final _displayFmt = DateFormat('d MMM yyyy'); // "15 Jun 2026"
  static final _apiFmt     = DateFormat('yyyy-MM-dd'); // "2026-06-15"

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  // ── Date picker helpers ───────────────────────────────────────────────────

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
      // Reset end if it's now before start.
      if (_vacationEnd != null && _vacationEnd!.isBefore(picked)) {
        _vacationEnd = null;
        _endController.clear();
      }
    });
  }

  Future<void> _pickEndDate() async {
    final minDate = _vacationStart != null
        ? _vacationStart!
        : DateTime.now().add(const Duration(days: 1));
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

  // ── Set vacation ─────────────────────────────────────────────────────────

  Future<void> _onSetVacation() async {
    if (_vacationStart == null || _vacationEnd == null) return;

    setState(() {
      _isSetting = true;
      _startError = null;
      _endError   = null;
    });

    final error = await ref
        .read(customerVacationProvider.notifier)
        .setVacation(
          _apiFmt.format(_vacationStart!),
          _apiFmt.format(_vacationEnd!),
        );

    if (!mounted) return;
    setState(() => _isSetting = false);

    if (error == null) {
      // Success — reset form state and show snackbar.
      setState(() {
        _vacationStart = null;
        _vacationEnd   = null;
        _startController.clear();
        _endController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Vacation set. You'll receive a WhatsApp confirmation."),
        ),
      );
    } else {
      // Map specific API messages to inline field errors or snackbar.
      if (error.contains('vacation_end') ||
          error.toLowerCase().contains('end must be on or after')) {
        setState(() => _endError = error);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // ── Cancel vacation ───────────────────────────────────────────────────────

  Future<void> _onCancelVacation() async {
    setState(() => _isCancelling = true);

    final error =
        await ref.read(customerVacationProvider.notifier).cancel();

    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vacation cancelled.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vacationAsync = ref.watch(customerVacationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacation'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(customerVacationProvider.notifier).load(),
        child: vacationAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorBody(
            message: error.toString(),
            onRetry: () =>
                ref.read(customerVacationProvider.notifier).load(),
          ),
          data: (vacation) {
            if (vacation != null && vacation.hasVacation) {
              return _VacationActiveBody(
                vacation: vacation,
                isCancelling: _isCancelling,
                onCancel: _onCancelVacation,
              );
            }
            return _NoVacationBody(
              startController: _startController,
              endController: _endController,
              vacationStart: _vacationStart,
              vacationEnd: _vacationEnd,
              startError: _startError,
              endError: _endError,
              isSetting: _isSetting,
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

// ── State A — No vacation set ─────────────────────────────────────────────────

class _NoVacationBody extends StatelessWidget {
  const _NoVacationBody({
    required this.startController,
    required this.endController,
    required this.vacationStart,
    required this.vacationEnd,
    required this.startError,
    required this.endError,
    required this.isSetting,
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
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onSetVacation;

  bool get _canSubmit => vacationStart != null && vacationEnd != null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Allow pull-to-refresh to work even with short content.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Text('Plan a vacation', style: AppText.sectionTitle),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Pause your deliveries for a date range.',
            style: AppText.meta.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: AppSpace.xl),

          // From field
          GestureDetector(
            onTap: onPickStart,
            child: AbsorbPointer(
              child: AppTextField(
                label: 'From',
                hint: 'Select date',
                controller: startController,
                errorText: startError,
                suffixIcon: Icons.calendar_today_outlined,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // Until field
          GestureDetector(
            onTap: onPickEnd,
            child: AbsorbPointer(
              child: AppTextField(
                label: 'Until',
                hint: 'Select date',
                controller: endController,
                errorText: endError,
                suffixIcon: Icons.calendar_today_outlined,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xl),

          // Set vacation button
          FilledButton(
            onPressed: (_canSubmit && !isSetting) ? onSetVacation : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: isSetting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Set vacation'),
          ),
        ],
      ),
    );
  }
}

// ── State B — Vacation active ─────────────────────────────────────────────────

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
    final end   = _displayFmt.format(DateTime.parse(vacation.end!));
    return '$start – $end';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading row
                const Row(
                  children: [
                    Icon(
                      Icons.beach_access_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    SizedBox(width: AppSpace.sm),
                    Text('On vacation', style: AppText.cardTitle),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),

                // Date range
                Text(_formattedRange, style: AppText.body),
                const SizedBox(height: AppSpace.xs),

                // Explanation
                Text(
                  'Deliveries paused during this period.',
                  style: AppText.meta.copyWith(color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),

          // Cancel vacation button
          isCancelling
              ? const Center(child: CircularProgressIndicator())
              : TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  child: const Text('Cancel vacation'),
                ),
        ],
      ),
    );
  }
}

// ── Error body ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: AppText.body, textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.sm),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
