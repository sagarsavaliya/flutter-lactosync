// Persistent amber banner displayed at the top of every owner screen during
// the grace period (PAYMENT_OVERDUE but not yet suspended).
//
// Usage — drop into the OwnerShell body above the main content:
//
//   Consumer(builder: (context, ref, _) {
//     final subState = ref.watch(subscriptionStatusProvider);
//     if (subState.status == SubscriptionStatus.gracePeriod) {
//       return SubscriptionWarningBanner(warning: subState.warning!);
//     }
//     return const SizedBox.shrink();
//   })

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/models/subscription_status.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../features/owner/presentation/providers/owner_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';

class SubscriptionWarningBanner extends ConsumerWidget {
  const SubscriptionWarningBanner({super.key, required this.warning});

  final SubscriptionWarning warning;

  Future<void> _payNow(BuildContext context, WidgetRef ref) async {
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
      if (!launched && context.mounted) {
        AppSnackBar.show(context, 'Could not open UPI app. Please pay manually.');
      }
    } else {
      if (context.mounted) {
        AppSnackBar.show(
          context,
          'Please contact LactoSync support to clear your dues.',
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = warning.graceDaysRemaining;
    final label = daysLeft == 1
        ? 'Payment overdue — 1 day left to clear dues'
        : 'Payment overdue — $daysLeft day(s) left to clear dues';

    return Container(
      height: 48,
      color: AppColors.warning,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppText.label.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _payNow(context, ref),
            child: const Text(
              'Pay Now',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
