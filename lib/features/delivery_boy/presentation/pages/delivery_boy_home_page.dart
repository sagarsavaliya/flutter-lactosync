import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../providers/delivery_boy_auth_provider.dart';

class DeliveryBoyHomePage extends ConsumerWidget {
  const DeliveryBoyHomePage({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showAppConfirmDialog(
      context: context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      cancelLabel: 'Cancel',
      destructive: true,
    );
    if (ok != true || !context.mounted) return;
    await ref.read(deliveryBoyAuthRepositoryProvider).logout();
    if (context.mounted) context.go('/delivery-boy/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(today);

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Dashboard',
                      style: AppText.screenTitle.copyWith(
                        fontSize: 22,
                        color: CustomerDetailColors.accent,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(LucideIcons.moreVertical, color: CustomerDetailColors.onSurface),
                    color: CustomerDetailColors.surface,
                    onSelected: (v) {
                      if (v == 'change-pin') context.push('/delivery-boy/change-pin');
                      if (v == 'logout') _logout(context, ref);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'change-pin',
                        child: Text('Change PIN', style: AppText.label),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: Text(
                          'Logout',
                          style: AppText.label.copyWith(color: CustomerDetailColors.danger),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _HeroDateCard(dateStr: dateStr),
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    'QUICK ACTIONS',
                    style: AppText.meta.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: CustomerDetailColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: LucideIcons.sun,
                          label: 'Morning\nRoute Sheet',
                          bg: CustomerDetailColors.morningChipBg,
                          iconColor: CustomerDetailColors.morningChipInk,
                          onTap: () => context.go('/delivery-boy/route-sheet'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: LucideIcons.moon,
                          label: 'Evening\nRoute Sheet',
                          bg: const Color(0xFFE0E4F5),
                          iconColor: const Color(0xFF5C6BC0),
                          onTap: () => context.go('/delivery-boy/route-sheet'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroDateCard extends StatelessWidget {
  const _HeroDateCard({required this.dateStr});
  final String dateStr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E6E45), Color(0xFF3C8557)],
        ),
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.cardRadius),
        boxShadow: [
          BoxShadow(
            color: CustomerDetailColors.accent.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.calendar,
              color: Color(0xFFEAF7EC),
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today',
                  style: AppText.meta.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFBFE6C8),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateStr,
                  style: AppText.cardTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEAF7EC),
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.bg,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RedesignSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.cardTitle.copyWith(
              fontWeight: FontWeight.w700,
              color: CustomerDetailColors.onSurface,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
