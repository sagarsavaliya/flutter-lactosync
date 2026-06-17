import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/delivery_provider.dart';
import '../widgets/customer_detail/customer_detail_styles.dart';
import '../widgets/dashboard/dashboard_styles.dart';
import '../widgets/owner_design_system.dart';
import '../widgets/owner_screen_widgets.dart';
import '../widgets/route_customer_tile.dart';
import '../widgets/route_milk_prep_compact.dart';
import '../widgets/routes_today_hero.dart';
import '../../../../core/widgets/app_snackbar.dart';

/// Routes overview — matches briefs/redesign app screen lactosync frame 1.
class RoutesPage extends ConsumerStatefulWidget {
  const RoutesPage({super.key});

  @override
  ConsumerState<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends ConsumerState<RoutesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _isMorning => _tabs.index == 0;

  Future<void> _showAddSheet() async {
    final shift = _isMorning ? 'morning' : 'evening';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RouteSheet(existing: null, initialShift: shift),
    );
    ref.invalidate(deliveryRoutesProvider);
  }

  String _ownerFirstName() {
    final name = ref.read(authSessionProvider).value?.ownerName ?? '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '';
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(deliveryRoutesProvider);

    return routesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: DashboardColors.primary),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (all) {
        final morning = all.where((r) => r.shift == 'morning').toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final evening = all.where((r) => r.shift == 'evening').toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final activeRoutes = _isMorning ? morning : evening;
        final totals = routesShiftTotals(activeRoutes);

        return ColoredBox(
          color: CustomerDetailColors.background,
          child: RefreshIndicator(
            color: DashboardColors.primary,
            onRefresh: () async =>
                ref.invalidate(deliveryRoutesProvider),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: [
                RoutesTodayHeroCard(
                  ownerFirstName: _ownerFirstName(),
                  isMorning: _isMorning,
                  routeCount: totals.routeCount,
                  stops: totals.stops,
                  liters: totals.liters,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DashboardSpace.page,
                    0,
                    DashboardSpace.page,
                    AppSpace.sm,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Routes',
                        style: AppText.cardTitle.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: CustomerDetailColors.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.users,
                          color: CustomerDetailColors.bodyInk,
                          size: 22,
                        ),
                        tooltip: 'Delivery boys',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => context.push('/owner/delivery-boys'),
                      ),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.plus,
                          color: CustomerDetailColors.bodyInk,
                          size: 22,
                        ),
                        tooltip: 'Add route',
                        visualDensity: VisualDensity.compact,
                        onPressed: _showAddSheet,
                      ),
                    ],
                  ),
                ),
                _RoutesShiftTabs(controller: _tabs),
                const SizedBox(height: 12),
                if (activeRoutes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DashboardSpace.page,
                    ),
                    child: Text(
                      _isMorning
                          ? 'No morning routes yet.'
                          : 'No evening routes yet.',
                      textAlign: TextAlign.center,
                      style: AppText.meta.copyWith(
                        color: CustomerDetailColors.iconMuted,
                      ),
                    ),
                  )
                else
                  ...activeRoutes.map(
                    (route) => _RouteCard(
                      route: route,
                      onRefresh: () => ref.invalidate(deliveryRoutesProvider),
                      onEdit: () => _showEditSheet(route),
                      onDelete: () => _confirmDeleteRoute(route),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DashboardSpace.page,
                    AppSpace.xs,
                    DashboardSpace.page,
                    AppSpace.md,
                  ),
                  child: _DashedAddRouteButton(onTap: _showAddSheet),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditSheet(DeliveryRouteModel route) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RouteSheet(existing: route),
    );
    ref.invalidate(deliveryRoutesProvider);
  }

  Future<void> _confirmDeleteRoute(DeliveryRouteModel route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete route?'),
        content: Text(
          'Remove "${route.name}" and unassign all customers from this route?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await deleteDeliveryRoute(ref, route.id);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, mapDioError(e).message);
    }
  }
}

class _RoutesShiftTabs extends StatelessWidget {
  const _RoutesShiftTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DashboardSpace.page),
      child: SizedBox(
        height: 32,
        child: TabBar(
          controller: controller,
          tabAlignment: TabAlignment.fill,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: CustomerDetailColors.accent,
          indicatorWeight: 2.5,
          labelColor: CustomerDetailColors.accent,
          unselectedLabelColor: CustomerDetailColors.iconMuted,
          labelStyle: AppText.cardTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: AppText.cardTitle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: CustomerDetailColors.iconMuted,
          ),
          dividerColor: CustomerDetailColors.border,
          labelPadding: const EdgeInsets.only(bottom: 4),
          tabs: const [
            Tab(text: 'Morning'),
            Tab(text: 'Evening'),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatefulWidget {
  const _RouteCard({
    required this.route,
    required this.onRefresh,
    required this.onEdit,
    required this.onDelete,
  });

  final DeliveryRouteModel route;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final isMorning = route.shift == 'morning';
    final riderName = route.deliveryBoyName?.trim();
    final hasRider = riderName != null && riderName.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DashboardSpace.page,
        0,
        DashboardSpace.page,
        12,
      ),
      child: DecoratedBox(
        decoration: ownerWhiteCardDecoration(
          radius: _expanded ? 22 : OwnerScreenMetrics.cardRadius,
        ).copyWith(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF283C28).withValues(
                alpha: _expanded ? 0.12 : 0.08,
              ),
              blurRadius: _expanded ? 22 : 18,
              offset: Offset(0, _expanded ? 8 : 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 15, 10, _expanded ? 14 : 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push('/owner/routes/${route.id}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isMorning
                                  ? CustomerDetailColors.morningChipBg
                                  : const Color(0xFFE0E4F5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isMorning
                                  ? Icons.wb_sunny_rounded
                                  : Icons.nights_stay_rounded,
                              color: isMorning
                                  ? const Color(0xFFE89A2E)
                                  : const Color(0xFF5C6BC0),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  route.name,
                                  style: AppText.cardTitle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: CustomerDetailColors.onSurface,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.two_wheeler_outlined,
                                      size: 16,
                                      color: hasRider
                                          ? CustomerDetailColors.accent
                                          : CustomerDetailColors.iconMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        hasRider
                                            ? (_expanded
                                                ? '$riderName · ${route.customerCount} stops'
                                                : riderName)
                                            : 'Unassigned',
                                        style: AppText.meta.copyWith(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: hasRider
                                              ? (_expanded
                                                  ? CustomerDetailColors.iconMuted
                                                  : CustomerDetailColors.accent)
                                              : CustomerDetailColors.iconMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: widget.onEdit,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            LucideIcons.pencil,
                            size: 18,
                            color: CustomerDetailColors.morningChipInk,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: widget.onDelete,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: CustomerDetailColors.morningChipInk,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _expanded = !_expanded),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              LucideIcons.chevronDown,
                              size: 18,
                              color: _expanded
                                  ? CustomerDetailColors.accent
                                  : CustomerDetailColors.morningChipInk,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 15),
                child: InkWell(
                  onTap: () => context.push('/owner/routes/${route.id}'),
                  borderRadius: BorderRadius.circular(14),
                  child: RouteStatBoxes(
                    stops: route.customerCount,
                    liters: route.totalLiters,
                    offCount: route.offCount,
                  ),
                ),
              ),
            if (_expanded) ...[
              RouteMilkPrepCompact(
                cards: route.milkPreparation,
                isMorning: isMorning,
                totalLiters: route.totalLiters,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
                child: Align(
                  alignment: Alignment.center,
                  child: FilledButton(
                    onPressed: () => context.push('/owner/routes/${route.id}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: CustomerDetailColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open route',
                          style: AppText.cardTitle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashedAddRouteButton extends StatelessWidget {
  const _DashedAddRouteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CustomerDetailMetrics.sectionCardRadius),
        child: OwnerDashedOutline(
          radius: CustomerDetailMetrics.sectionCardRadius,
          color: CustomerDetailColors.accentBorder,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.plus,
                  size: 18,
                  color: CustomerDetailColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add a route',
                  style: AppText.meta.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CustomerDetailColors.accent,
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

// ── Add / Edit Route Sheet ────────────────────────────────────────────────────

class _RouteSheet extends ConsumerStatefulWidget {
  const _RouteSheet({required this.existing, this.initialShift = 'morning'});
  final DeliveryRouteModel? existing;
  final String initialShift;

  @override
  ConsumerState<_RouteSheet> createState() => _RouteSheetState();
}

class _RouteSheetState extends ConsumerState<_RouteSheet> {
  final _nameCtrl = TextEditingController();
  String _shift = 'morning';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _shift = widget.existing!.shift;
    } else {
      _shift = widget.initialShift;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final dio = ref.read(dioProvider);
    final payload = {'name': _nameCtrl.text.trim(), 'shift': _shift};
    try {
      if (widget.existing == null) {
        await dio.post<Map<String, dynamic>>('/owner/routes', data: payload);
      } else {
        await dio.patch<Map<String, dynamic>>(
            '/owner/routes/${widget.existing!.id}',
            data: payload);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
        ),
        child: ListView(
          controller: controller,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE1D6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEdit ? 'Edit Route' : 'New Route',
              style: AppText.screenTitle.copyWith(
                fontSize: 20,
                color: const Color(0xFF1E2A1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isEdit ? 'Update the route name or shift.' : 'Create a new delivery route.',
              style: AppText.body.copyWith(color: const Color(0xFF8C938A)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              style: AppText.body.copyWith(
                color: const Color(0xFF1E2A1E),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Route Name',
                hintText: 'e.g. Punitnagar Road',
                filled: true,
                fillColor: const Color(0xFFF6F8F1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFECEFE5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFECEFE5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E6E45), width: 1.5),
                ),
                labelStyle: AppText.meta.copyWith(color: const Color(0xFF8C938A)),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _shift,
              decoration: InputDecoration(
                labelText: 'Shift',
                filled: true,
                fillColor: const Color(0xFFF6F8F1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFECEFE5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFECEFE5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E6E45), width: 1.5),
                ),
                labelStyle: AppText.meta.copyWith(color: const Color(0xFF8C938A)),
              ),
              items: const [
                DropdownMenuItem(value: 'morning', child: Text('Morning')),
                DropdownMenuItem(value: 'evening', child: Text('Evening')),
              ],
              onChanged: (v) => setState(() => _shift = v!),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E6E45),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isEdit ? 'Save Changes' : 'Create Route',
                      style: AppText.body.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
