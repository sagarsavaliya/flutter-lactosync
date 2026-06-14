import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/delivery_provider.dart';

class DeliveryBoysPage extends ConsumerStatefulWidget {
  const DeliveryBoysPage({super.key});

  @override
  ConsumerState<DeliveryBoysPage> createState() => _DeliveryBoysPageState();
}

class _DeliveryBoysPageState extends ConsumerState<DeliveryBoysPage> {
  Future<void> _showAddSheet() => _showEditSheet(null);

  Future<void> _showEditSheet(DeliveryBoyModel? existing) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeliveryBoySheet(existing: existing),
    );
    ref.invalidate(deliveryBoysProvider);
  }

  Future<void> _resetPin(DeliveryBoyModel boy) async {
    final dio = ref.read(dioProvider);
    try {
      final res = await dio.post('/owner/delivery-boys/${boy.id}/reset-pin');
      final pin = res.data['data']['temporary_pin'] as String;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Temporary PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Share this PIN with ${boy.name}:'),
              const SizedBox(height: 16),
              Text(pin,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 12,
                  )),
              const SizedBox(height: 8),
              const Text(
                'The delivery boy can change it after logging in.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reset PIN: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final boys = ref.watch(deliveryBoysProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Delivery Boys'),
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddSheet,
          ),
        ],
      ),
      body: boys.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('No delivery boys yet',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _showAddSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Delivery Boy'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(deliveryBoysProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final boy = list[i];
                    return AppCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: boy.isActive
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.15),
                          child: Text(
                            boy.name.isNotEmpty
                                ? boy.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: boy.isActive
                                  ? AppColors.primary
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(boy.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${boy.salaryType.replaceAll('_', ' ').toUpperCase()}'
                          '${boy.phone != null ? " · ${boy.phone}" : ""}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') _showEditSheet(boy);
                            if (v == 'pin') _resetPin(boy);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(
                                value: 'pin', child: Text('Reset PIN')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

// ── Add / Edit Sheet ──────────────────────────────────────────────────────────

class _DeliveryBoySheet extends ConsumerStatefulWidget {
  const _DeliveryBoySheet({this.existing});
  final DeliveryBoyModel? existing;

  @override
  ConsumerState<_DeliveryBoySheet> createState() => _DeliveryBoySheetState();
}

class _DeliveryBoySheetState extends ConsumerState<_DeliveryBoySheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _salaryType = 'monthly';
  final _salaryCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final b = widget.existing!;
      _nameCtrl.text = b.name;
      _phoneCtrl.text = b.phone ?? '';
      _salaryType = b.salaryType;
      _salaryCtrl.text = b.salaryAmount?.toStringAsFixed(0) ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final dio = ref.read(dioProvider);
    final payload = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'salary_type': _salaryType,
      'salary_amount': _salaryCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_salaryCtrl.text.trim()),
    };
    try {
      if (widget.existing == null) {
        await dio.post('/owner/delivery-boys', data: payload);
      } else {
        await dio.patch(
            '/owner/delivery-boys/${widget.existing!.id}',
            data: payload);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
        child: ListView(
          controller: controller,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEdit ? 'Edit Delivery Boy' : 'Add Delivery Boy',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _salaryType,
              decoration: const InputDecoration(labelText: 'Salary Type'),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'per_delivery', child: Text('Per Delivery')),
                DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                DropdownMenuItem(value: 'part_time', child: Text('Part Time')),
              ],
              onChanged: (v) => setState(() => _salaryType = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _salaryCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Salary Amount (optional)', prefixText: '₹ '),
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
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEdit ? 'Save Changes' : 'Add Delivery Boy',
                      style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
