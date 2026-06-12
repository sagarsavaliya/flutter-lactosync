import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/delivery_provider.dart';

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
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _showAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RouteSheet(existing: null),
    );
    ref.invalidate(deliveryRoutesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(deliveryRoutesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Routes'),
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddSheet),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.inkMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Morning'),
            Tab(text: 'Evening'),
          ],
        ),
      ),
      body: routesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (all) {
          final morning = all.where((r) => r.shift == 'morning').toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final evening = all.where((r) => r.shift == 'evening').toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return TabBarView(
            controller: _tabs,
            children: [
              _RouteList(routes: morning, onRefresh: () => ref.invalidate(deliveryRoutesProvider), ref: ref),
              _RouteList(routes: evening, onRefresh: () => ref.invalidate(deliveryRoutesProvider), ref: ref),
            ],
          );
        },
      ),
    );
  }
}

class _RouteList extends StatelessWidget {
  const _RouteList({
    required this.routes,
    required this.onRefresh,
    required this.ref,
  });

  final List<DeliveryRouteModel> routes;
  final VoidCallback onRefresh;
  final WidgetRef ref;

  Future<void> _showEditSheet(BuildContext context, DeliveryRouteModel route) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RouteSheet(existing: route),
    );
    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    if (routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No routes yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: routes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final route = routes[i];
          return AppCard(
            padding: EdgeInsets.zero,
            onTap: () => context.push('/owner/routes/${route.id}'),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: route.shift == 'morning'
                    ? Colors.amber.withValues(alpha: 0.15)
                    : Colors.indigo.withValues(alpha: 0.15),
                child: Icon(
                  route.shift == 'morning' ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                  color: route.shift == 'morning' ? Colors.amber[700] : Colors.indigo,
                  size: 20,
                ),
              ),
              title: Text(route.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                route.shift[0].toUpperCase() + route.shift.substring(1),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!route.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Inactive',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _showEditSheet(context, route),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Add / Edit Route Sheet ────────────────────────────────────────────────────

class _RouteSheet extends ConsumerStatefulWidget {
  const _RouteSheet({required this.existing});
  final DeliveryRouteModel? existing;

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
        await dio.post('/api/v1/owner/routes', data: payload);
      } else {
        await dio.patch('/api/v1/owner/routes/${widget.existing!.id}', data: payload);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
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
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Route' : 'New Route',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Route Name *'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _shift,
              decoration: const InputDecoration(labelText: 'Shift'),
              items: const [
                DropdownMenuItem(value: 'morning', child: Text('Morning')),
                DropdownMenuItem(value: 'evening', child: Text('Evening')),
              ],
              onChanged: (v) => setState(() => _shift = v!),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEdit ? 'Save Changes' : 'Create Route',
                      style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
