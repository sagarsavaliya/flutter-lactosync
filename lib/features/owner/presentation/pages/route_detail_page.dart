import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/delivery_provider.dart';
import '../providers/owner_provider.dart';
import '../widgets/customer_detail/customer_detail_styles.dart';
import '../widgets/dashboard/dashboard_styles.dart';
import '../widgets/owner_design_system.dart';
import '../widgets/owner_screen_widgets.dart';
import '../widgets/route_customer_tile.dart';
import '../../../../core/widgets/app_snackbar.dart';

class RouteDetailPage extends ConsumerStatefulWidget {
  const RouteDetailPage({super.key, required this.routeId});
  final int routeId;

  @override
  ConsumerState<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends ConsumerState<RouteDetailPage> {
  DeliveryRouteModel? _route;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      final routes = await ref.read(deliveryRoutesProvider.future);
      if (!mounted) return;
      DeliveryRouteModel? found;
      for (final r in routes) {
        if (r.id == widget.routeId) {
          found = r;
          break;
        }
      }
      setState(() => _route = found);
    } catch (_) {}
  }

  Future<void> _updateQty(int orderId, double qty) async {
    try {
      await ref.read(ownerRepositoryProvider).updateDailyOrder(
            orderId,
            quantity: qty,
          );
      ref.invalidate(routeCustomersProvider(widget.routeId));
      ref.invalidate(deliveryRoutesProvider);
    } on ApiException catch (e) {
      if (mounted) {
        AppSnackBar.show(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error: $e');
      }
    }
  }

  String _litersLabel(double liters) {
    if (liters == liters.roundToDouble()) return '${liters.toInt()} L';
    return '${liters.toStringAsFixed(1)} L';
  }

  String get _shiftLabel {
    final shift = _route?.shift ?? '';
    if (shift.isEmpty) return '';
    return shift[0].toUpperCase() + shift.substring(1);
  }

  String get _today =>
      DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _skipCustomer(RouteCustomerModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Skip delivery'),
        content: Text('Skip ${c.name} for today?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Skip',
                style: TextStyle(color: Color(0xFFE07A2F))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final dio = ref.read(dioProvider);
    try {
      await dio.post('/owner/skip-delivery', data: {
        'customer_id': c.customerId,
        'date': _today,
      });
      ref.invalidate(routeCustomersProvider(widget.routeId));
      ref.invalidate(deliveryRoutesProvider);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error: $e');
      }
    }
  }

  Future<void> _undoSkip(RouteCustomerModel c) async {
    final orderId = c.primaryOrderId;
    if (orderId == null) return;
    try {
      await ref.read(ownerRepositoryProvider).updateDailyOrder(
            orderId,
            status: 'pending',
          );
      ref.invalidate(routeCustomersProvider(widget.routeId));
      ref.invalidate(deliveryRoutesProvider);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error: $e');
      }
    }
  }

  Future<void> _assignBoy(int? boyId) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.put('/owner/routes/${widget.routeId}/assignments', data: {
        'delivery_boy_id': boyId,
        'date': '1970-01-01',
      });
      ref.invalidate(routeCustomersProvider(widget.routeId));
      ref.invalidate(deliveryRoutesProvider);
      await _loadRoute();
      if (mounted) {
        AppSnackBar.show(context, 'Delivery boy assigned');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error: $e');
      }
    }
  }

  Future<void> _removeCustomer(int assignmentId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Customer'),
        content: const Text('Remove this customer from the route?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final dio = ref.read(dioProvider);
    try {
      await dio.delete(
          '/owner/routes/${widget.routeId}/customers/$assignmentId');
      ref.invalidate(routeCustomersProvider(widget.routeId));
      ref.invalidate(routeAvailableCustomersProvider(widget.routeId));
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Error: $e');
      }
    }
  }

  Future<void> _moveCustomer(RouteCustomerModel c) async {
    List<DeliveryRouteModel> routes;
    try {
      routes = await ref.read(deliveryRoutesProvider.future);
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(context, 'Could not load routes: $e');
      }
      return;
    }

    final others =
        routes.where((r) => r.id != widget.routeId && r.isActive).toList();
    if (others.isEmpty) {
      if (mounted) {
        AppSnackBar.show(context, 'No other routes available.');
      }
      return;
    }

    if (!mounted) return;
    final target = await showModalBottomSheet<DeliveryRouteModel>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Move to Route',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...others.map((r) => ListTile(
                leading: Icon(
                  r.shift == 'morning'
                      ? Icons.wb_sunny_outlined
                      : Icons.nights_stay_outlined,
                  color: r.shift == 'morning'
                      ? Colors.amber[700]
                      : Colors.indigo,
                ),
                title: Text(r.name),
                subtitle: Text(
                    r.shift[0].toUpperCase() + r.shift.substring(1)),
                onTap: () => Navigator.pop(ctx, r),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
    if (target == null || !mounted) return;

    final dio = ref.read(dioProvider);
    try {
      await dio.delete(
          '/owner/routes/${widget.routeId}/customers/${c.assignmentId}');
      await dio.post('/owner/routes/${target.id}/customers',
          data: {'customer_id': c.customerId});
      ref.invalidate(routeCustomersProvider(widget.routeId));
      ref.invalidate(routeAvailableCustomersProvider(widget.routeId));
      if (mounted) {
        AppSnackBar.show(context, '${c.name} moved to ${target.name}');
      }
    } catch (e) {
      ref.invalidate(routeCustomersProvider(widget.routeId));
      if (mounted) {
        AppSnackBar.show(context, 'Move failed: $e');
      }
    }
  }

  Future<void> _showCustomerActions(RouteCustomerModel c) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Move to another route'),
              onTap: () => Navigator.pop(ctx, 'move'),
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
              title: const Text('Remove from route',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (action == 'move') {
      await _moveCustomer(c);
    } else if (action == 'remove') {
      await _removeCustomer(c.assignmentId);
    }
  }

  Future<void> _showAddCustomerSheet() async {
    await showOwnerBottomSheet<void>(
      context: context,
      child: _AddCustomerSheet(
        routeId: widget.routeId,
        shiftLabel: _shiftLabel,
      ),
    );
    ref.invalidate(routeCustomersProvider(widget.routeId));
    ref.invalidate(routeAvailableCustomersProvider(widget.routeId));
  }

  Future<void> _showAssignBoySheet() async {
    final boys = await ref.read(deliveryBoysProvider.future);
    if (!mounted) return;
    final picked = await showModalBottomSheet<int?>(
      context: context,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Assign Delivery Boy',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...boys.map(
            (b) => ListTile(
              title: Text(b.name),
              onTap: () => Navigator.pop(ctx, b.id),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.clear, color: Colors.red),
            title:
                const Text('Unassign', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(ctx, -1),
          ),
        ],
      ),
    );
    if (picked == null) return;
    await _assignBoy(picked == -1 ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(routeCustomersProvider(widget.routeId));
    final routeTitle = _route?.name ?? 'Route';
    final totalLiters = _route?.totalLiters ?? 0;

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DashboardSpace.page - 4,
                AppSpace.sm,
                DashboardSpace.page - 4,
                AppSpace.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      size: 22,
                      color: CustomerDetailColors.onSurface,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routeTitle,
                          style: AppText.cardTitle.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: CustomerDetailColors.accent,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        customersAsync.maybeWhen(
                          data: (customers) => Text(
                            '${_shiftLabel.isNotEmpty ? '$_shiftLabel · ' : ''}${customers.length} stops · ${_litersLabel(totalLiters)}',
                            style: AppText.meta.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: CustomerDetailColors.iconMuted,
                            ),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.bike,
                      color: CustomerDetailColors.accent,
                      size: 22,
                    ),
                    tooltip: 'Assign delivery boy',
                    visualDensity: VisualDensity.compact,
                    onPressed: _showAssignBoySheet,
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.userPlus,
                      color: CustomerDetailColors.accent,
                      size: 22,
                    ),
                    tooltip: 'Add customer',
                    visualDensity: VisualDensity.compact,
                    onPressed: _showAddCustomerSheet,
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: DashboardColors.surfaceContainer,
                border: Border(
                  top: BorderSide(color: CustomerDetailColors.border),
                  bottom: BorderSide(color: CustomerDetailColors.border),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DashboardSpace.page,
                  vertical: AppSpace.sm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.gripHorizontal,
                      size: 18,
                      color: CustomerDetailColors.iconMuted,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Drag to set delivery order',
                        style: AppText.meta.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: CustomerDetailColors.iconMuted,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: Text(
                        'Done',
                        style: AppText.meta.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: CustomerDetailColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: customersAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: CustomerDetailColors.accent,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: AppText.body.copyWith(
                      color: CustomerDetailColors.labelMuted,
                    ),
                  ),
                ),
                data: (customers) {
                  if (customers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(DashboardSpace.page),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.users,
                              size: 48,
                              color: CustomerDetailColors.iconMuted
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: AppSpace.sm),
                            Text(
                              'No customers on this route',
                              style: AppText.body.copyWith(
                                color: CustomerDetailColors.labelMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpace.md),
                            OutlinedButton.icon(
                              onPressed: _showAddCustomerSheet,
                              icon: const Icon(
                                LucideIcons.userPlus,
                                size: 18,
                              ),
                              label: const Text('Add Customer'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: CustomerDetailColors.accent,
                                side: const BorderSide(
                                  color: CustomerDetailColors.accentBorder,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      DashboardSpace.page,
                      12,
                      DashboardSpace.page,
                      AppSpace.md,
                    ),
                    buildDefaultDragHandles: false,
                    onReorder: (oldIdx, newIdx) async {
                      if (newIdx > oldIdx) newIdx--;
                      final reordered = [...customers];
                      final moved = reordered.removeAt(oldIdx);
                      reordered.insert(newIdx, moved);
                      final dio = ref.read(dioProvider);
                      try {
                        await dio.put(
                          '/owner/routes/${widget.routeId}/customers/reorder',
                          data: {
                            'order': reordered
                                .map((e) => e.assignmentId)
                                .toList(),
                          },
                        );
                        ref.invalidate(routeCustomersProvider(widget.routeId));
                      } catch (e) {
                        if (mounted) {
                          AppSnackBar.show(context, 'Reorder failed: $e');
                        }
                      }
                    },
                    itemCount: customers.length,
                    itemBuilder: (context, i) {
                      final c = customers[i];
                      return Padding(
                        key: ValueKey(c.assignmentId),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DecoratedBox(
                          decoration: ownerWhiteCardDecoration(),
                          child: GestureDetector(
                            onLongPress: () => _showCustomerActions(c),
                            child: RouteCustomerTile(
                              customer: c,
                              index: i + 1,
                              dragHandle: ReorderableDragStartListener(
                                index: i,
                                child: const Icon(
                                  LucideIcons.gripVertical,
                                  size: 20,
                                  color: CustomerDetailColors.iconMuted,
                                ),
                              ),
                              onSkip: c.onVacation || c.isSkipped
                                  ? null
                                  : () => _skipCustomer(c),
                              onUndo: c.isSkipped && !c.onVacation
                                  ? () => _undoSkip(c)
                                  : null,
                              onQtyChanged: _updateQty,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Customer to Route Sheet ───────────────────────────────────────────────

class _AddCustomerSheet extends ConsumerStatefulWidget {
  const _AddCustomerSheet({
    required this.routeId,
    required this.shiftLabel,
  });

  final int routeId;
  final String shiftLabel;

  @override
  ConsumerState<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends ConsumerState<_AddCustomerSheet> {
  final _searchCtrl = TextEditingController();
  final Set<int> _selected = {};
  bool _adding = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RouteEligibleCustomer> _filter(List<RouteEligibleCustomer> all) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q);
    }).toList();
  }

  void _toggle(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _addSelected() async {
    if (_selected.isEmpty) return;
    setState(() => _adding = true);
    final dio = ref.read(dioProvider);
    int failed = 0;
    for (final id in _selected.toList()) {
      try {
        await dio.post('/owner/routes/${widget.routeId}/customers',
            data: {'customer_id': id});
      } catch (_) {
        failed++;
      }
    }
    if (mounted) {
      if (failed > 0) {
        AppSnackBar.show(context, 
                '$failed customer(s) could not be added (already on route?)');
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final eligibleAsync =
        ref.watch(routeAvailableCustomersProvider(widget.routeId));
    final subtitle = widget.shiftLabel.isNotEmpty
        ? '${widget.shiftLabel} shift subscribers not on any route'
        : 'Subscribers not on any route';

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerSheetTitle('Add Customers to Route', subtitle: subtitle),
          const SizedBox(height: AppSpace.md),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name or area…',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: AppSpace.sm),
          Expanded(
            child: eligibleAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load: $e')),
              data: (all) {
                final filtered = _filter(all);
                if (all.isEmpty) {
                  return Center(
                    child: Text(
                      'No eligible customers.\nAll ${widget.shiftLabel.toLowerCase()} subscribers may already be on routes.',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: CustomerDetailColors.labelMuted),
                    ),
                  );
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No matches for "$_searchQuery"',
                      style: AppText.body.copyWith(color: CustomerDetailColors.labelMuted),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (ctx, i) {
                    final c = filtered[i];
                    return CheckboxListTile(
                      value: _selected.contains(c.id),
                      onChanged: (_) => _toggle(c.id),
                      title: Text(c.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: c.address.isNotEmpty ? Text(c.address) : null,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: CustomerDetailColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: CustomerDetailColors.surface,
                    );
                  },
                );
              },
            ),
          ),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            AppButton(
              label:
                  'Add ${_selected.length} customer${_selected.length == 1 ? '' : 's'}',
              loading: _adding,
              onPressed: _adding ? null : _addSelected,
            ),
          ],
        ],
      ),
    );
  }
}
