import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_typography.dart';
import '../owner_action_sheets.dart';

/// Quick actions grid — frame 4 (4 columns).
class DashboardQuickActions extends ConsumerWidget {
  const DashboardQuickActions({super.key});

  static const _label = Color(0xFF46524A);
  static const _iconBg = Color(0xFFF4F6EE);
  static const _iconBorder = Color(0xFFE7EBE0);
  static const _green = Color(0xFF2E6E45);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 11),
          child: Text(
            AppStrings.dashboardQuickActions.toUpperCase(),
            style: AppText.meta.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: const Color(0xFF8C938A),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: LucideIcons.userPlus,
                label: AppStrings.dashboardFindCustomer,
                onTap: () => OwnerActionSheets.showFindCustomer(context, ref),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                icon: LucideIcons.receipt,
                label: AppStrings.dashboardGenBill,
                onTap: () => OwnerActionSheets.showGenerateBill(context, ref),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                icon: LucideIcons.creditCard,
                label: AppStrings.dashboardRecordPayment,
                onTap: () => OwnerActionSheets.showCollectPayment(context, ref),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                icon: LucideIcons.qrCode,
                label: AppStrings.dashboardViewQr,
                onTap: () => OwnerActionSheets.showFarmUpiQr(context, ref),
              ),
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFECEFE5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF283C28).withValues(alpha: 0.18),
                blurRadius: 14,
                spreadRadius: -10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 14, 6, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: DashboardQuickActions._iconBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: DashboardQuickActions._iconBorder,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: DashboardQuickActions._green,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: AppText.meta.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: DashboardQuickActions._label,
                    height: 1.15,
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
