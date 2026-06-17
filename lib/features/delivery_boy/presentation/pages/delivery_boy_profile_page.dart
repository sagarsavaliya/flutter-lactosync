import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/widgets/app_dialogs.dart';
import '../providers/delivery_boy_auth_provider.dart';
import '../providers/delivery_boy_route_provider.dart';
import '../providers/delivery_boy_session_provider.dart';
import '../widgets/delivery_boy_styles.dart';

class DeliveryBoyProfilePage extends ConsumerWidget {
  const DeliveryBoyProfilePage({super.key});

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
    final session = ref.watch(deliveryBoySessionProvider);
    final sheetKey = DbRouteSheetKey.today(session.shift);
    final sheetAsync = ref.watch(deliveryBoyRouteSheetProvider(sheetKey));
    final boyName = sheetAsync.valueOrNull?.deliveryBoyName.trim() ?? '';

    return Scaffold(
      backgroundColor: DbBoyColors.background,
      body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text('Profile', style: DbBoyText.screenTitle),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: DbBoyText.whiteCard(),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: DbBoyColors.accentLight,
                    child: Icon(LucideIcons.user, color: DbBoyColors.accent, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          boyName.isNotEmpty ? boyName : 'Delivery staff',
                          style: DbBoyText.cardTitle,
                        ),
                        Text('LactoSync delivery app', style: DbBoyText.meta),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _MenuTile(
              icon: LucideIcons.lock,
              label: 'Change PIN',
              onTap: () => context.push('/delivery-boy/change-pin'),
            ),
            _MenuTile(
              icon: LucideIcons.logOut,
              label: 'Logout',
              danger: true,
              onTap: () => _logout(context, ref),
            ),
          ],
        ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? DbBoyColors.danger : DbBoyColors.ink;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: DbBoyText.whiteCard(radius: DbBoyMetrics.innerRadius),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: DbBoyText.cardTitle.copyWith(color: color, fontSize: 15)),
        trailing: Icon(LucideIcons.chevronRight, size: 18, color: DbBoyColors.labelMuted),
        onTap: onTap,
      ),
    );
  }
}
