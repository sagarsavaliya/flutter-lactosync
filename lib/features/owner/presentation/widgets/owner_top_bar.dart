import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/module_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/dashboard/dashboard_styles.dart';
import '../widgets/owner_design_system.dart';



class OwnerTopBar extends ConsumerWidget implements PreferredSizeWidget {

  const OwnerTopBar({
    super.key,
    required this.screenTitle,
    this.dashboardMode = false,
    this.titleColor,
  });

  final String screenTitle;
  final bool dashboardMode;
  final Color? titleColor;



  @override

  Size get preferredSize => const Size.fromHeight(kToolbarHeight);



  String _initials(String name) {

    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty || parts.first.isEmpty) return '?';

    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();

  }



  void _showProfileDialog(BuildContext context, WidgetRef ref) {

    final session = ref.read(authSessionProvider).value;

    if (session == null) return;



    showAppAlert(
      context: context,
      title: AppStrings.profileMenuTitle,
      message: '${session.ownerName}\n${AppStrings.mobileLabel}: ${session.mobile}\n'
          '${AppStrings.farmNameLabel}: ${session.farmName}',
    );

  }



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final sessionAsync = ref.watch(authSessionProvider);

    final farmName = sessionAsync.value?.farmName ?? AppStrings.appName;

    final ownerName = sessionAsync.value?.ownerName ?? '';

    final initials = _initials(ownerName);



    return AppBar(

      automaticallyImplyLeading: false,

      backgroundColor: dashboardMode ? DashboardColors.background : OwnerTheme.background,

      surfaceTintColor: Colors.transparent,

      foregroundColor: dashboardMode ? null : OwnerTheme.primary,

      elevation: 0,

      scrolledUnderElevation: 0,

      bottom: dashboardMode
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color: AppColors.border.withValues(alpha: 0.6),
              ),
            ),

      titleSpacing: DashboardSpace.page,

      title: dashboardMode

          ? Row(

              children: [

                Expanded(

                  child: Text(

                    farmName.toUpperCase(),

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: DashboardText.farmName,

                  ),

                ),

                _ProfileAvatar(
                  initials: initials,
                  ref: ref,
                  dashboardMode: true,
                  onProfile: () => _showProfileDialog(context, ref),
                ),

              ],

            )

          : Row(

              children: [

                Expanded(

                  flex: 2,

                  child: Text(

                    farmName,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF46524A),
                      height: 1.1,
                    ),

                  ),

                ),

                Expanded(

                  flex: 3,

                  child: Text(

                    screenTitle,

                    textAlign: TextAlign.center,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: AppText.screenTitle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: titleColor ?? OwnerTheme.primary,
                    ),

                  ),

                ),

                Expanded(

                  flex: 2,

                  child: Align(

                    alignment: Alignment.centerRight,

                    child: _ProfileAvatar(

                      initials: initials,

                      ref: ref,

                      dashboardMode: false,

                      onProfile: () => _showProfileDialog(context, ref),

                    ),

                  ),

                ),

              ],

            ),

    );

  }

}



class _ProfileAvatar extends StatelessWidget {

  const _ProfileAvatar({

    required this.initials,

    required this.ref,

    required this.dashboardMode,

    required this.onProfile,

  });



  final String initials;

  final WidgetRef ref;

  final bool dashboardMode;

  final VoidCallback onProfile;



  @override

  Widget build(BuildContext context) {

    return PopupMenuButton<String>(

      tooltip: AppStrings.profileMenuTitle,

      offset: const Offset(0, 40),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

      itemBuilder: (context) => [

        const PopupMenuItem(value: 'profile', child: Text(AppStrings.profileMyProfile)),

        const PopupMenuItem(value: 'activity', child: Text(AppStrings.profileActivity)),

        const PopupMenuItem(value: 'communications', child: Text(AppStrings.profileCommunications)),

        const PopupMenuItem(value: 'settings', child: Text(AppStrings.navSettings)),

        const PopupMenuItem(value: 'signout', child: Text(AppStrings.signOut)),

      ],

      onSelected: (value) async {

        switch (value) {

          case 'profile':

            onProfile();

          case 'activity':

            context.push('/owner/activity');

          case 'communications':

            context.push('/owner/communications');

          case 'settings':

            context.go('/owner/settings');

          case 'signout':

            await ref.read(authRepositoryProvider).logout();

            ref.invalidate(authSessionProvider);

            if (context.mounted) context.go('/sign-in');

        }

      },

      child: CircleAvatar(

        radius: 19,

        backgroundColor: const Color(0xFFA7E0B0),

        child: Text(

          initials,

          style: AppText.meta.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E5233),
          ),

        ),

      ),

    );

  }

}


