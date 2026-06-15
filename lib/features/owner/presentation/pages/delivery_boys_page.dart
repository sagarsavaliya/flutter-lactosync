import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/delivery_provider.dart';
import '../widgets/customer_detail/customer_detail_styles.dart';
import '../widgets/owner_design_system.dart';
import '../widgets/owner_screen_widgets.dart';
import '../../../../core/widgets/app_snackbar.dart';

class DeliveryBoysPage extends ConsumerStatefulWidget {
  const DeliveryBoysPage({super.key});

  @override
  ConsumerState<DeliveryBoysPage> createState() => _DeliveryBoysPageState();
}

class _DeliveryBoysPageState extends ConsumerState<DeliveryBoysPage> {
  Future<void> _showAddSheet() => _showEditSheet(null);

  Future<void> _showEditSheet(DeliveryBoyModel? existing) async {
    await showOwnerBottomSheet<void>(
      context: context,
      child: _DeliveryBoySheet(existing: existing),
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
      AppSnackBar.showError(context, 'Failed to reset PIN: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final boys = ref.watch(deliveryBoysProvider);

    return Scaffold(
      backgroundColor: CustomerDetailColors.background,
      appBar: AppBar(
        title: Text(
          'Delivery Boys',
          style: AppText.screenTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: CustomerDetailColors.accent,
          ),
        ),
        backgroundColor: CustomerDetailColors.background,
        foregroundColor: CustomerDetailColors.accent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            onPressed: _showAddSheet,
          ),
        ],
      ),
      body: boys.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: CustomerDetailColors.accent),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.users, size: 64, color: CustomerDetailColors.iconMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No delivery boys yet',
                      style: AppText.body.copyWith(color: CustomerDetailColors.labelMuted),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: CustomerDetailColors.accent),
                      onPressed: _showAddSheet,
                      icon: const Icon(LucideIcons.userPlus),
                      label: const Text('Add Delivery Boy'),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: CustomerDetailColors.accent,
                onRefresh: () async => ref.invalidate(deliveryBoysProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (context, i) {
                    final boy = list[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: ownerWhiteCardDecoration(),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: boy.isActive
                                  ? CustomerDetailColors.avatarBg
                                  : CustomerDetailColors.statBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              boy.name.isNotEmpty ? boy.name[0].toUpperCase() : '?',
                              style: AppText.cardTitle.copyWith(
                                color: boy.isActive
                                    ? CustomerDetailColors.accent
                                    : CustomerDetailColors.labelMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  boy.name,
                                  style: AppText.cardTitle.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: CustomerDetailColors.onSurface,
                                  ),
                                ),
                                Text(
                                  '${boy.salaryType.replaceAll('_', ' ').toUpperCase()}'
                                  '${boy.phone != null ? " · ${boy.phone}" : ""}',
                                  style: AppText.meta.copyWith(color: CustomerDetailColors.labelMuted),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(LucideIcons.moreVertical, color: CustomerDetailColors.iconMuted),
                            onSelected: (v) {
                              if (v == 'edit') _showEditSheet(boy);
                              if (v == 'pin') _resetPin(boy);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'pin', child: Text('Reset PIN')),
                            ],
                          ),
                        ],
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
        AppSnackBar.show(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerSheetHeader(
            title: isEdit ? 'Edit Delivery Boy' : 'Add Delivery Boy',
            icon: LucideIcons.userPlus,
          ),
          const SizedBox(height: AppSpace.lg),
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
              labelText: 'Salary Amount (optional)',
              prefixText: '₹ ',
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          OwnerSheetActions(
            primaryLabel: isEdit ? 'Save Changes' : 'Add Delivery Boy',
            loading: _saving,
            onPrimary: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
