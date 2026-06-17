import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../owner/presentation/widgets/packing_groups_panel.dart';
import '../../../owner/domain/entities/owner_models.dart';
import '../providers/delivery_boy_route_provider.dart';
import 'delivery_boy_styles.dart';

class DbBoyNavBar extends StatelessWidget {
  const DbBoyNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const tabs = [
    (icon: LucideIcons.package, label: 'Pickup'),
    (icon: LucideIcons.mapPin, label: 'Stops'),
    (icon: LucideIcons.wallet, label: 'Cash'),
    (icon: LucideIcons.user, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DbBoyColors.surface,
        border: Border(top: BorderSide(color: DbBoyColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final selected = currentIndex == i;
              final color = selected ? DbBoyColors.accent : DbBoyColors.labelMuted;
              return InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tabs[i].icon, size: 22, color: color),
                      const SizedBox(height: 4),
                      Text(
                        tabs[i].label,
                        style: DbBoyText.navLabel.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class DbBoyGreetingHeader extends StatelessWidget {
  const DbBoyGreetingHeader({
    super.key,
    required this.name,
    this.trailing,
  });

  final String name;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: DbBoyColors.accentLight,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'D',
              style: DbBoyText.cardTitle.copyWith(
                color: DbBoyColors.accent,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: DbBoyText.meta),
                Text(
                  name.isNotEmpty ? name : 'Delivery',
                  style: DbBoyText.greeting.copyWith(fontSize: 22),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class DbRouteHeroCard extends StatelessWidget {
  const DbRouteHeroCard({
    super.key,
    required this.routeName,
    required this.shiftLabel,
    required this.stopCount,
  });

  final String routeName;
  final String shiftLabel;
  final int stopCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: DbBoyText.heroCard(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shiftLabel.toUpperCase(),
                  style: DbBoyText.sectionLabel.copyWith(color: DbBoyColors.heroMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  routeName,
                  style: DbBoyText.cardTitle.copyWith(
                    color: DbBoyColors.heroInk,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  '$stopCount',
                  style: DbBoyText.cardTitle.copyWith(
                    color: DbBoyColors.heroInk,
                    fontSize: 22,
                  ),
                ),
                Text(
                  'STOPS',
                  style: DbBoyText.sectionLabel.copyWith(
                    color: DbBoyColors.heroMuted,
                    fontSize: 9,
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

class DbLoadSummaryCard extends StatelessWidget {
  const DbLoadSummaryCard({
    super.key,
    required this.totalLiters,
    required this.bottles,
    required this.bags,
  });

  final double totalLiters;
  final int bottles;
  final int bags;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: DbBoyText.heroCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Load on your cart',
            style: DbBoyText.meta.copyWith(
              color: DbBoyColors.heroMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(
                value: '${totalLiters.toStringAsFixed(0)} L',
                label: 'Total milk',
              ),
              _Stat(value: '$bottles', label: 'Bottles'),
              _Stat(value: '$bags', label: 'Bags'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: DbBoyText.cardTitle.copyWith(
                color: DbBoyColors.heroInk,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: DbBoyText.meta.copyWith(
                color: DbBoyColors.heroMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DbPickupManifestCard extends StatelessWidget {
  const DbPickupManifestCard({
    super.key,
    required this.cards,
    this.customerCount = 0,
    this.totalLiters = 0,
  });
  final List<MilkPreparationContainerCard> cards;
  final int customerCount;
  final double totalLiters;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: DbBoyText.whiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PICKUP MANIFEST', style: DbBoyText.sectionLabel),
          const SizedBox(height: 12),
          if (cards.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                customerCount > 0
                    ? '$customerCount stops · ${totalLiters.toStringAsFixed(1)} L total'
                    : 'No deliveries scheduled for this shift',
                style: DbBoyText.meta,
              ),
            )
          else
            PackingContainerGroups(cards: cards, chipBackground: DbBoyColors.background),
        ],
      ),
    );
  }
}

class DbRouteProgressBar extends StatelessWidget {
  const DbRouteProgressBar({
    super.key,
    required this.delivered,
    required this.skipped,
    required this.remaining,
    required this.total,
  });

  final int delivered;
  final int skipped;
  final int remaining;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? delivered / total : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$delivered of $total delivered',
                  style: DbBoyText.cardTitle.copyWith(fontSize: 15),
                ),
              ),
              Text(
                '${(pct * 100).round()}%',
                style: DbBoyText.meta.copyWith(
                  fontWeight: FontWeight.w800,
                  color: DbBoyColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0, 1),
              minHeight: 8,
              backgroundColor: DbBoyColors.pendingBg,
              color: DbBoyColors.accent,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _Pill(label: '$delivered done', color: DbBoyColors.done, bg: DbBoyColors.doneBg),
              const SizedBox(width: 8),
              _Pill(label: '$skipped skipped', color: DbBoyColors.skipped, bg: DbBoyColors.skippedBg),
              const SizedBox(width: 8),
              _Pill(label: '$remaining left', color: DbBoyColors.labelMuted, bg: DbBoyColors.pendingBg),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, required this.bg});
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: DbBoyText.meta.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class DbStopCard extends StatelessWidget {
  const DbStopCard({
    super.key,
    required this.stopNumber,
    required this.customer,
    required this.isActive,
    this.onDeliver,
    this.onSkip,
  });

  final int stopNumber;
  final DbRouteCustomer customer;
  final bool isActive;
  final VoidCallback? onDeliver;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final delivered = customer.isDelivered;
    final skipped = customer.isSkipped && !delivered;

    Color borderColor = DbBoyColors.border;
    double borderWidth = 1;
    List<BoxShadow> shadows = [
      BoxShadow(
        color: const Color(0xFF283C28).withValues(alpha: 0.05),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ];

    if (isActive) {
      borderColor = DbBoyColors.activeBorder;
      borderWidth = 2;
      shadows = [
        BoxShadow(
          color: DbBoyColors.activeGlow,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skipped ? DbBoyColors.pendingBg : DbBoyColors.surface,
        borderRadius: BorderRadius.circular(DbBoyMetrics.innerRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StopBadge(number: stopNumber, delivered: delivered),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            style: DbBoyText.cardTitle.copyWith(fontSize: 15),
                          ),
                        ),
                        if (delivered)
                          _StatusChip(label: 'Delivered', color: DbBoyColors.done, bg: DbBoyColors.doneBg)
                        else if (skipped)
                          _StatusChip(label: 'Skipped', color: DbBoyColors.skipped, bg: DbBoyColors.skippedBg),
                      ],
                    ),
                    if (customer.address.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(customer.address, style: DbBoyText.meta),
                    ],
                    if (customer.primaryProductLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        customer.primaryProductLabel,
                        style: DbBoyText.meta.copyWith(
                          fontWeight: FontWeight.w800,
                          color: DbBoyColors.accent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!delivered && !skipped && onDeliver != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onSkip != null)
                  IconButton.outlined(
                    onPressed: onSkip,
                    icon: const Icon(LucideIcons.ban, size: 18),
                    style: IconButton.styleFrom(
                      foregroundColor: DbBoyColors.skipped,
                      side: const BorderSide(color: DbBoyColors.border),
                    ),
                  ),
                if (onSkip != null) const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onDeliver,
                    style: FilledButton.styleFrom(
                      backgroundColor: DbBoyColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Deliver'),
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

class _StopBadge extends StatelessWidget {
  const _StopBadge({required this.number, required this.delivered});
  final int number;
  final bool delivered;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: delivered ? DbBoyColors.doneBg : DbBoyColors.accentLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: delivered ? DbBoyColors.done : DbBoyColors.accentBorder,
        ),
      ),
      child: delivered
          ? const Icon(LucideIcons.check, size: 16, color: DbBoyColors.done)
          : Text(
              '$number',
              style: DbBoyText.meta.copyWith(
                fontWeight: FontWeight.w800,
                color: DbBoyColors.accent,
              ),
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.bg,
  });
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: DbBoyText.meta.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class DbPrimaryButton extends StatelessWidget {
  const DbPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: enabled && !loading ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: DbBoyColors.accent,
          disabledBackgroundColor: DbBoyColors.accent.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: DbBoyText.cardTitle.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class DbCashSummaryHero extends StatelessWidget {
  const DbCashSummaryHero({
    super.key,
    required this.total,
    required this.customerCount,
    required this.onHandOver,
    this.handedOver = false,
  });

  final double total;
  final int customerCount;
  final VoidCallback onHandOver;
  final bool handedOver;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: DbBoyText.heroCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To hand over to dairy',
            style: DbBoyText.meta.copyWith(color: DbBoyColors.heroMuted),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${total.toStringAsFixed(0)}',
            style: DbBoyText.greeting.copyWith(
              color: DbBoyColors.heroInk,
              fontSize: 36,
            ),
          ),
          Text(
            'from $customerCount customer${customerCount == 1 ? '' : 's'}',
            style: DbBoyText.meta.copyWith(color: DbBoyColors.heroMuted),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: handedOver || total <= 0 ? null : onHandOver,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: DbBoyColors.accent,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    handedOver ? LucideIcons.checkCircle2 : LucideIcons.wallet,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    handedOver ? 'Handed over' : 'Hand over to dairy',
                    style: DbBoyText.cardTitle.copyWith(
                      color: DbBoyColors.accent,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DbCashCollectionRow extends StatelessWidget {
  const DbCashCollectionRow({
    super.key,
    required this.name,
    required this.amount,
    this.stopNumber,
    this.timeLabel,
  });

  final String name;
  final double amount;
  final int? stopNumber;
  final String? timeLabel;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0]).join().toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: DbBoyText.whiteCard(radius: DbBoyMetrics.innerRadius),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: DbBoyColors.accentLight,
            child: Text(
              initials,
              style: DbBoyText.meta.copyWith(
                fontWeight: FontWeight.w800,
                color: DbBoyColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: DbBoyText.cardTitle.copyWith(fontSize: 15)),
                if (stopNumber != null || timeLabel != null)
                  Text(
                    [
                      if (stopNumber != null) 'Stop $stopNumber',
                      if (timeLabel != null) timeLabel!,
                    ].join(' · '),
                    style: DbBoyText.meta,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: DbBoyText.cardTitle.copyWith(
                  fontSize: 16,
                  color: DbBoyColors.accent,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.checkCircle2, size: 14, color: DbBoyColors.done),
                  const SizedBox(width: 4),
                  Text(
                    'Recorded',
                    style: DbBoyText.meta.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: DbBoyColors.done,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DbShiftToggle extends StatelessWidget {
  const DbShiftToggle({
    super.key,
    required this.shift,
    required this.onChanged,
  });

  final String shift;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DbBoyColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DbBoyColors.border),
        ),
        child: Row(
          children: [
            _Tab(
              label: 'Morning',
              selected: shift == 'morning',
              onTap: () => onChanged('morning'),
            ),
            _Tab(
              label: 'Evening',
              selected: shift == 'evening',
              onTap: () => onChanged('evening'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? DbBoyColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: DbBoyText.cardTitle.copyWith(
              fontSize: 14,
              color: selected ? Colors.white : DbBoyColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
