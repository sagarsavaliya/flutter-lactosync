import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_typography.dart';
import 'customer_dashboard_styles.dart';

// ── Header ────────────────────────────────────────────────────────────────────

class CusProfileHeader extends StatelessWidget {
  const CusProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CusDashMetrics.horizontalPad,
        16,
        CusDashMetrics.horizontalPad,
        8,
      ),
      child: Text('Profile', style: CusDashText.greeting.copyWith(fontSize: 28)),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────

class CusProfileUserCard extends StatelessWidget {
  const CusProfileUserCard({
    super.key,
    required this.initials,
    required this.fullName,
    required this.mobile,
    required this.address,
    required this.onEdit,
  });

  final String initials;
  final String fullName;
  final String mobile;
  final String address;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CusDashText.whiteCard(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: CusDashColors.accentLight,
                child: Text(
                  initials,
                  style: AppText.cardTitle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: CusDashColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: AppText.cardTitle.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: CusDashColors.ink,
                      ),
                    ),
                    if (mobile.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(LucideIcons.phone, size: 13, color: CusDashColors.inkMuted),
                          const SizedBox(width: 5),
                          Text(
                            mobile,
                            style: AppText.meta.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CusDashColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Material(
                color: CusDashColors.accentLight,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onEdit,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(LucideIcons.pencil, size: 16, color: CusDashColors.accent),
                  ),
                ),
              ),
            ],
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: CusDashColors.border),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.mapPin, size: 16, color: CusDashColors.inkMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: AppText.body.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: CusDashColors.inkMuted,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Subscription ──────────────────────────────────────────────────────────────

class CusProfileSubscriptionCard extends StatelessWidget {
  const CusProfileSubscriptionCard({
    super.key,
    required this.productLabel,
    required this.shiftLabel,
    required this.isMorning,
    required this.qtyPerDay,
    required this.isActive,
    required this.onManage,
  });

  final String productLabel;
  final String shiftLabel;
  final bool isMorning;
  final double qtyPerDay;
  final bool isActive;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final qtyLabel = qtyPerDay == qtyPerDay.roundToDouble()
        ? '${qtyPerDay.toInt()} L / day'
        : '${qtyPerDay.toStringAsFixed(1)} L / day';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CusDashText.whiteCard(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: CusDashColors.accentLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(LucideIcons.milk, size: 22, color: CusDashColors.accent),
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
                      '$shiftLabel · $qtyLabel',
                      style: AppText.meta.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CusDashColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: CusDashColors.activeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: CusDashColors.activeInk,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Active',
                        style: AppText.meta.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CusDashColors.activeInk,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onManage,
              style: FilledButton.styleFrom(
                backgroundColor: CusDashColors.accentLight,
                foregroundColor: CusDashColors.ink,
                elevation: 0,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Manage plan',
                style: AppText.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: CusDashColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings list card ────────────────────────────────────────────────────────

class CusProfileSettingsCard extends StatelessWidget {
  const CusProfileSettingsCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: CusDashText.whiteCard(radius: CusDashMetrics.innerRadius),
      child: Column(children: children),
    );
  }
}

class CusProfileToggleRow extends StatelessWidget {
  const CusProfileToggleRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isWhatsApp = false,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CusDashColors.accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isWhatsApp ? FontAwesomeIcons.whatsapp : icon,
              size: isWhatsApp ? 18 : 18,
              color: isWhatsApp ? const Color(0xFF25D366) : CusDashColors.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: AppText.body.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: CusDashColors.ink,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: CusDashColors.accent,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class CusProfileNavRow extends StatelessWidget {
  const CusProfileNavRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: CusDashColors.accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: CusDashColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppText.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: CusDashColors.ink,
                ),
              ),
            ),
            trailing ??
                Icon(LucideIcons.chevronRight, size: 18, color: CusDashColors.labelMuted),
          ],
        ),
      ),
    );
  }
}

class CusProfileDivider extends StatelessWidget {
  const CusProfileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 16,
      endIndent: 16,
      color: CusDashColors.border,
    );
  }
}

class CusProfileSectionLabel extends StatelessWidget {
  const CusProfileSectionLabel({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(title, style: CusDashText.sectionLabel),
    );
  }
}

class CusProfileLogoutButton extends StatelessWidget {
  const CusProfileLogoutButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CusDashColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CusDashColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.logOut, size: 18, color: CusDashColors.payBrown),
              const SizedBox(width: 8),
              Text(
                'Log out',
                style: AppText.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CusDashColors.payBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CusProfileFooter extends StatelessWidget {
  const CusProfileFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'LactoSync · v4.11.1',
        style: AppText.meta.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CusDashColors.labelMuted,
        ),
      ),
    );
  }
}
