// Full-screen gate shown imperatively (via Navigator.push) when the tenant's
// subscription is suspended.  Pushed by the ref.listen in LactoSyncApp;
// auto-popped when SubscriptionStatusNotifier transitions back to active.
//
// "Pay Now" opens a UPI deep link if the farm has a UPI VPA configured.
// "Refresh" re-fetches /owner/settings — if it succeeds, the interceptor
// sets the state to active and the ref.listen here pops the page.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/subscription_status.dart';
import '../../../../core/providers/subscription_status_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/owner/presentation/providers/owner_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';

class SubscriptionSuspendedPage extends ConsumerStatefulWidget {
  const SubscriptionSuspendedPage({super.key});

  @override
  ConsumerState<SubscriptionSuspendedPage> createState() =>
      _SubscriptionSuspendedPageState();
}

class _SubscriptionSuspendedPageState
    extends ConsumerState<SubscriptionSuspendedPage> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Listen for re-activation so we can auto-pop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(subscriptionStatusProvider, (previous, next) {
        if (next.status == SubscriptionStatus.active &&
            previous?.status == SubscriptionStatus.suspended) {
          if (mounted) Navigator.of(context).pop();
        }
      });
    });
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      // Any successful owner call clears the suspended state via the interceptor.
      await ref.read(ownerRepositoryProvider).fetchSettings();
    } catch (_) {
      // If the call is still 403, the interceptor will keep the suspended state.
      // Show feedback to the user.
      if (mounted) {
        AppSnackBar.show(
          context,
          'Subscription is still suspended. Please contact support.',
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _payNow(SubscriptionSuspension suspension) async {
    // Try to get UPI VPA from settings (cached or re-fetched).
    final settingsAsync = ref.read(ownerSettingsProvider);
    final upiVpa = settingsAsync.valueOrNull?.farm.upiVpa;
    final payeeName =
        settingsAsync.valueOrNull?.farm.upiPayeeName ?? 'LactoSync';

    if (upiVpa != null && upiVpa.isNotEmpty) {
      final uri = Uri.parse(
        'upi://pay'
        '?pa=${Uri.encodeComponent(upiVpa)}'
        '&pn=${Uri.encodeComponent(payeeName)}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent('Subscription Fee')}',
      );
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        AppSnackBar.show(context, 'Could not open UPI app. Please pay manually.');
      }
    } else {
      // No UPI VPA — ask the user to contact support.
      if (mounted) {
        AppSnackBar.show(
          context,
          'Please contact LactoSync support to clear your dues.',
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionStatusProvider);
    final suspension = state.suspension;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.xl,
            vertical: AppSpace.xxl,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Icon
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.dangerFaint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.credit_card_off_outlined,
                    color: AppColors.danger,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xl),

              // Title
              Text(
                'Subscription Suspended',
                textAlign: TextAlign.center,
                style: AppText.screenTitle.copyWith(
                  fontSize: 22,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: AppSpace.md),

              // Subtitle
              Text(
                'Your subscription has been suspended due to an overdue payment.',
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: AppColors.inkMuted),
              ),

              if (suspension != null && suspension.dueDate.isNotEmpty) ...[
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Payment was due on ${suspension.dueDate}',
                  textAlign: TextAlign.center,
                  style: AppText.label.copyWith(color: AppColors.inkMuted),
                ),
              ],

              const Spacer(),

              // Pay Now CTA
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: AppColors.surface,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed:
                    suspension != null ? () => _payNow(suspension) : null,
                child: const Text(
                  'Pay Now',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: AppSpace.md),

              // Refresh button
              TextButton(
                onPressed: _isRefreshing ? null : _refresh,
                child: _isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.inkMuted,
                        ),
                      )
                    : Text(
                        'Refresh — check if payment was processed',
                        style: AppText.label.copyWith(color: AppColors.inkMuted),
                      ),
              ),
              const SizedBox(height: AppSpace.lg),
            ],
          ),
        ),
      ),
    );
  }
}
