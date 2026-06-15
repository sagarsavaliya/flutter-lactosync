import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/owner_models.dart';
import 'customer_list_styles.dart';

/// Customer row — frame 5: subs badge, PAUSE/RESUME, vacation styling.
class CustomerListTile extends StatelessWidget {
  const CustomerListTile({
    super.key,
    required this.name,
    required this.address,
    required this.status,
    this.subscriptionCount = 0,
    this.vacationEnd,
    this.onTap,
    this.onVacationTap,
  });

  final String name;
  final String address;
  final CustomerDisplayStatus status;
  final int subscriptionCount;
  final DateTime? vacationEnd;
  final VoidCallback? onTap;
  final VoidCallback? onVacationTap;

  bool get _isInactive => status == CustomerDisplayStatus.inactive;
  bool get _isVacation => status == CustomerDisplayStatus.vacation;
  bool get _isActive => status == CustomerDisplayStatus.active;

  Color get _cardBg =>
      _isVacation ? CustomerListColors.vacationCardBg : CustomerListColors.surface;

  Color get _cardBorder =>
      _isVacation ? CustomerListColors.vacationCardBorder : CustomerListColors.border;

  ({Color bg, Color fg}) get _avatarColors {
    if (_isVacation) {
      return (bg: CustomerListColors.vacationAvatarBg, fg: CustomerListColors.vacationBlue);
    }
    if (_isInactive) {
      return (bg: CustomerListColors.inactiveAvatarBg, fg: CustomerListColors.inactiveOrange);
    }
    return (bg: CustomerListColors.activeAvatarBg, fg: CustomerListColors.accent);
  }

  String? get _vacationMeta {
    if (!_isVacation || vacationEnd == null) return null;
    final back = DateFormat('d MMM').format(vacationEnd!);
    return 'On vacation · Back $back';
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatarColors;
    final initials = customerInitials(name);

    return Opacity(
      opacity: _isInactive ? 0.7 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(CustomerListMetrics.cardRadius),
          border: Border.all(color: _cardBorder),
          boxShadow: const [CustomerListMetrics.cardShadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                    splashColor: CustomerListColors.accent.withValues(alpha: 0.08),
                    highlightColor: CustomerListColors.accent.withValues(alpha: 0.04),
                    child: Row(
                      children: [
                        _AvatarStack(
                          initials: initials,
                          avatarBg: avatar.bg,
                          avatarFg: avatar.fg,
                          subscriptionCount: subscriptionCount,
                          showInactiveDot: _isInactive,
                          showVacationIcon: _isVacation,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _NameBlock(
                          name: name,
                          address: address,
                          isVacation: _isVacation,
                          vacationMeta: _vacationMeta,
                        )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _TrailingAction(
                  isActive: _isActive,
                  isVacation: _isVacation,
                  isInactive: _isInactive,
                  onVacationTap: onVacationTap,
                ),
              ],
            ),
          ),
        ),
    );
  }
}

class _NameBlock extends StatelessWidget {
  const _NameBlock({
    required this.name,
    required this.address,
    required this.isVacation,
    this.vacationMeta,
  });

  final String name;
  final String address;
  final bool isVacation;
  final String? vacationMeta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.cardTitle.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: CustomerListColors.nameInk,
            height: 1.15,
          ),
        ),
        if (isVacation && vacationMeta != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: CustomerListColors.vacationChipBg,
              border: Border.all(color: CustomerListColors.vacationChipBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.flight_takeoff_rounded,
                  size: 12,
                  color: CustomerListColors.vacationBlue,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    vacationMeta!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.meta.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: CustomerListColors.vacationChipInk,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (address.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 13,
                color: CustomerListColors.addressMuted.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.meta.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CustomerListColors.addressMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({
    required this.initials,
    required this.avatarBg,
    required this.avatarFg,
    required this.subscriptionCount,
    required this.showInactiveDot,
    required this.showVacationIcon,
  });

  final String initials;
  final Color avatarBg;
  final Color avatarFg;
  final int subscriptionCount;
  final bool showInactiveDot;
  final bool showVacationIcon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: avatarBg,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            initials,
            style: AppText.cardTitle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: avatarFg,
            ),
          ),
        ),
        if (subscriptionCount > 0)
          Positioned(
            top: -6,
            left: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CustomerListColors.accent,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: CustomerListColors.surface, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF283C28).withValues(alpha: 0.25),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$subscriptionCount',
                style: AppText.cardTitle.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
        if (showInactiveDot)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFFE08A2B),
                shape: BoxShape.circle,
                border: Border.all(color: CustomerListColors.surface, width: 2.5),
              ),
            ),
          ),
        if (showVacationIcon)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                color: CustomerListColors.vacationBlue,
                shape: BoxShape.circle,
                border: Border.all(color: CustomerListColors.vacationCardBg, width: 2.5),
              ),
              child: const Icon(
                Icons.flight_takeoff_rounded,
                size: 10,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class _TrailingAction extends StatelessWidget {
  const _TrailingAction({
    required this.isActive,
    required this.isVacation,
    required this.isInactive,
    this.onVacationTap,
  });

  final bool isActive;
  final bool isVacation;
  final bool isInactive;
  final VoidCallback? onVacationTap;

  @override
  Widget build(BuildContext context) {
    if (isInactive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: CustomerListColors.inactiveBadgeBg,
          border: Border.all(color: CustomerListColors.inactiveBadgeBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Inactive',
          style: AppText.meta.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
            color: CustomerListColors.inactiveOrange,
          ),
        ),
      );
    }

    if (isVacation) {
      return _VacationActionButton(
        label: 'RESUME',
        icon: Icons.login_rounded,
        filled: true,
        onTap: onVacationTap,
      );
    }

    if (isActive && onVacationTap != null) {
      return _VacationActionButton(
        label: 'PAUSE',
        icon: Icons.logout_rounded,
        filled: false,
        onTap: onVacationTap,
      );
    }

    return const SizedBox.shrink();
  }
}

class _VacationActionButton extends StatelessWidget {
  const _VacationActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? CustomerListColors.accent : CustomerListColors.pauseBg,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: filled ? 11 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: filled ? null : Border.all(color: CustomerListColors.searchBorder),
            boxShadow: filled
                ? [
                    BoxShadow(
                      color: CustomerListColors.accent.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled ? Colors.white : const Color(0xFF6E8A72),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppText.meta.copyWith(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: filled ? const Color(0xFFEAF7EC) : CustomerListColors.pauseInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
