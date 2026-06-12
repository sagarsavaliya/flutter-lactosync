import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/delivery_provider.dart';

class RouteDetailPage extends ConsumerStatefulWidget {
  const RouteDetailPage({super.key, required this.routeId});
  final int routeId;

  @override
  ConsumerState<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends ConsumerState<RouteDetailPage> {
  // Assign delivery boy for today
  Future<void> _assignBoy(int? boyId) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.put('/api/v1/owner/routes/${widget.routeId}/assignments', data: {
        'delivery_boy_id': boyId,
        'assigned_date': DateTime.now().toIso8601String().substring(0, 10),
      });
      ref.invalidate(routeCustomersProvider(widget.routeId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delivery boy assigned')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final dio = ref.read(dioProvider);
    try {
      await dio.delete(
          '/api/v1/owner/routes/${widget.routeId}/customers/$assignmentId');
      ref.invalidate(routeCustomersProvider(widget.routeId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showAddCustomerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCustomerSheet(routeId: widget.routeId),
    );
    ref.invalidate(routeCustomersProvider(widget.routeId));
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...boys.map(
            (b) => ListTile(
              title: Text(b.name),
              onTap: () => Navigator.pop(ctx, b.id),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.clear, color: Colors.red),
            title: const Text('Unassign', style: TextStyle(color: Colors.red)),
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Route Detail'),
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_pin_outlined),
            tooltip: 'Assign Delivery Boy',
            onPressed: _showAssignBoySheet,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Customer',
            onPressed: _showAddCustomerSheet,
          ),
        ],
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (customers) {
          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group_add_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No customers on this route',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddCustomerSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Customer'),
                  ),
                ],
              ),
            );
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            onReorder: (oldIdx, newIdx) async {
              if (newIdx > oldIdx) newIdx--;
              final reordered = [...customers];
              final moved = reordered.removeAt(oldIdx);
              reordered.insert(newIdx, moved);
              // Optimistic update — then persist
              final dio = ref.read(dioProvider);
              try {
                await dio.put(
                  '/api/v1/owner/routes/${widget.routeId}/customers/reorder',
                  data: {
                    'order': reordered
                        .asMap()
                        .entries
                        .map((e) => {
                              'assignment_id': e.value.assignmentId,
                              'sort_order': e.key + 1,
                            })
                        .toList(),
                  },
                );
                ref.invalidate(routeCustomersProvider(widget.routeId));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Reorder failed: $e')));
                }
              }
            },
            itemCount: customers.length,
            itemBuilder: (context, i) {
              final c = customers[i];
              return AppCard(
                key: ValueKey(c.assignmentId),
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(c.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: c.address.isNotEmpty ? Text(c.address) : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red, size: 20),
                    onPressed: () => _removeCustomer(c.assignmentId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Add Customer to Route Sheet ───────────────────────────────────────────────

class _AddCustomerSheet extends ConsumerStatefulWidget {
  const _AddCustomerSheet({required this.routeId});
  final int routeId;

  @override
  ConsumerState<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends ConsumerState<_AddCustomerSheet> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final dio = ref.read(dioProvider);
    try {
      final res = await dio.get('/api/v1/owner/customers',
          queryParameters: {'q': q.trim(), 'limit': 20});
      final list = (res.data['data'] as List<dynamic>?) ?? [];
      setState(() {
        _results = list.cast<Map<String, dynamic>>();
        _searching = false;
      });
    } catch (_) {
      setState(() => _searching = false);
    }
  }

  Future<void> _add(int customerId) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.post('/api/v1/owner/routes/${widget.routeId}/customers',
          data: {'customer_id': customerId});
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
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
        child: Column(
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
            const Text('Add Customer to Route',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search customers…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 16, width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: _results.length,
                itemBuilder: (ctx, i) {
                  final c = _results[i];
                  return ListTile(
                    title: Text(c['name'] as String? ?? ''),
                    subtitle: Text(c['address'] as String? ?? ''),
                    trailing: const Icon(Icons.add_circle_outline,
                        color: Colors.green),
                    onTap: () => _add(c['id'] as int),
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
