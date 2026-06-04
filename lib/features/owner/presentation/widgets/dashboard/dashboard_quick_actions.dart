import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../owner_action_sheets.dart';
import 'dashboard_styles.dart';

class DashboardQuickActions extends ConsumerWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.dashboardQuickActions.toUpperCase(), style: DashboardText.overviewLabel),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: DashboardSpace.sm,
          crossAxisSpacing: DashboardSpace.sm,
          childAspectRatio: 1.35,
          children: [
            _QuickActionTile(
              icon: Icons.person_search_outlined,
              label: AppStrings.dashboardFindCustomer,
              iconColor: DashboardColors.primary,
              onTap: () => OwnerActionSheets.showFindCustomer(context, ref),
            ),
            _QuickActionTile(
              icon: Icons.receipt_long_outlined,
              label: AppStrings.dashboardGenBill,
              iconColor: DashboardColors.tertiary,
              onTap: () => OwnerActionSheets.showGenerateBill(context, ref),
            ),
            _QuickActionTile(
              icon: Icons.payments_outlined,
              label: AppStrings.dashboardRecordPayment,
              iconColor: DashboardColors.secondary,
              onTap: () => OwnerActionSheets.showCollectPayment(context, ref),
            ),
            _QuickActionTile(
              icon: Icons.qr_code_2_outlined,
              label: AppStrings.dashboardViewQr,
              iconColor: DashboardColors.primary,
              onTap: () => OwnerActionSheets.showFarmUpiQr(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DashboardColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: DashboardColors.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: DashboardText.quickActionLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
