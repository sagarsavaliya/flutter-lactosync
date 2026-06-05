import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form_layout.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/settings_models.dart';
import '../providers/owner_provider.dart';
import '../widgets/owner_design_system.dart';

class OwnerSettingsPage extends ConsumerStatefulWidget {
  const OwnerSettingsPage({super.key});

  @override
  ConsumerState<OwnerSettingsPage> createState() => _OwnerSettingsPageState();
}

class _OwnerSettingsPageState extends ConsumerState<OwnerSettingsPage> {
  // Order schedule state (kept on page level — no bottom sheet)
  bool _includeFarmHeader = true;
  TimeOfDay _morningOrderTime = const TimeOfDay(hour: 5, minute: 0);
  TimeOfDay _eveningOrderTime = const TimeOfDay(hour: 15, minute: 0);
  bool _loaded = false;

  // Per-sheet loading flags
  bool _savingFarm = false;
  bool _savingOwner = false;

  // Cached settings reference so sheets can read current values
  OwnerSettings? _settings;

  @override
  void dispose() {
    super.dispose();
  }

  void _load(OwnerSettings settings) {
    if (_loaded) return;
    _settings = settings;
    _includeFarmHeader = settings.documentSettings.includeFarmHeader;
    _morningOrderTime = _parseTime(settings.farm.morningOrderTime);
    _eveningOrderTime = _parseTime(settings.farm.eveningOrderTime);
    _loaded = true;
  }

  TimeOfDay _parseTime(String? value) {
    final parts = (value ?? '05:00').split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 5,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// 12-hour display e.g. "5:00 AM", "3:00 PM"
  String _displayTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute;
    final ampm = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${h.toString()}:${minute.toString().padLeft(2, '0')} $ampm';
  }

  Future<void> _pickOrderTime({required bool morning}) async {
    final initial = morning ? _morningOrderTime : _eveningOrderTime;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (morning) {
        _morningOrderTime = picked;
      } else {
        _eveningOrderTime = picked;
      }
    });
    // Auto-save schedule change
    await _saveSchedule();
  }

  Future<void> _saveSchedule() async {
    final settings = _settings;
    if (settings == null) return;
    try {
      await ref.read(ownerRepositoryProvider).updateSettings(
            OwnerSettingsUpdate(
              farm: SettingsFarm(
                id: settings.farm.id,
                name: settings.farm.name,
                addressLine: settings.farm.addressLine,
                city: settings.farm.city,
                state: settings.farm.state,
                zip: settings.farm.zip,
                upiVpa: settings.farm.upiVpa,
                upiPayeeName: settings.farm.upiPayeeName,
                morningOrderTime: _formatTime(_morningOrderTime),
                eveningOrderTime: _formatTime(_eveningOrderTime),
              ),
            ),
          );
      ref.invalidate(ownerSettingsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Farm edit bottom sheet
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _openFarmEditSheet() async {
    final settings = _settings;
    if (settings == null) return;

    final farmName = TextEditingController(text: settings.farm.name ?? '');
    final address = TextEditingController(text: settings.farm.addressLine ?? '');
    final zip = TextEditingController(text: settings.farm.zip ?? '');
    final city = TextEditingController(text: settings.farm.city ?? '');
    final state = TextEditingController(text: settings.farm.state ?? '');
    final upiVpa = TextEditingController(text: settings.farm.upiVpa ?? '');
    final upiPayeeName = TextEditingController(text: settings.farm.upiPayeeName ?? '');

    await showOwnerBottomSheet<void>(
      context: context,
      child: _FarmEditSheet(
        farmName: farmName,
        address: address,
        zip: zip,
        city: city,
        state: state,
        upiVpa: upiVpa,
        upiPayeeName: upiPayeeName,
        currentFarm: settings.farm,
        onSave: (updatedFarm) async {
          setState(() => _savingFarm = true);
          try {
            await ref.read(ownerRepositoryProvider).updateSettings(
                  OwnerSettingsUpdate(farm: updatedFarm),
                );
            ref.invalidate(ownerSettingsProvider);
            _loaded = false; // allow re-load on next build
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.settingsSaved)),
              );
            }
          } on ApiException catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
            }
          } finally {
            if (mounted) setState(() => _savingFarm = false);
          }
        },
        repository: ref.read(ownerRepositoryProvider),
      ),
    );

    farmName.dispose();
    address.dispose();
    zip.dispose();
    city.dispose();
    state.dispose();
    upiVpa.dispose();
    upiPayeeName.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Owner edit bottom sheet
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _openOwnerEditSheet() async {
    final settings = _settings;
    if (settings == null) return;

    final firstName = TextEditingController(text: settings.owner.firstName ?? '');
    final lastName = TextEditingController(text: settings.owner.lastName ?? '');

    await showOwnerBottomSheet<void>(
      context: context,
      child: _OwnerEditSheet(
        firstName: firstName,
        lastName: lastName,
        mobile: settings.owner.mobile,
        onSave: (fn, ln) async {
          setState(() => _savingOwner = true);
          try {
            await ref.read(ownerRepositoryProvider).updateSettings(
                  OwnerSettingsUpdate(
                    owner: SettingsOwner(
                      firstName: fn,
                      lastName: ln,
                      fullName: '',
                      mobile: '',
                    ),
                  ),
                );
            ref.invalidate(ownerSettingsProvider);
            _loaded = false;
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.settingsSaved)),
              );
            }
          } on ApiException catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
            }
          } finally {
            if (mounted) setState(() => _savingOwner = false);
          }
        },
      ),
    );

    firstName.dispose();
    lastName.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Product actions (unchanged)
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _editProduct(SettingsProduct product) async {
    final name = TextEditingController(text: product.name);
    final rate = TextEditingController(text: product.rate.toStringAsFixed(0));

    // Prefer ID-based selection for dynamic dropdowns (S6-15)
    int? milkTypeId = product.milkTypeId;
    int? containerTypeId = product.containerTypeId;

    // Legacy slug fallback (still sent for backward compat)
    var milkType = product.milkType;
    var containerType = product.containerType;

    final milkTypesAsync = ref.read(milkTypesProvider);
    final containerTypesAsync = ref.read(containerTypesProvider);

    final milkTypes = milkTypesAsync.valueOrNull ?? <MilkTypeItem>[];
    final containerTypes = containerTypesAsync.valueOrNull ?? <ContainerTypeItem>[];

    final saved = await showOwnerBottomSheet<bool>(
      context: context,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OwnerSheetTitle(AppStrings.settingsEditProduct),
              const SizedBox(height: AppSpace.sm),
              AppTextField(controller: name, label: AppStrings.productNameLabel),
              const SizedBox(height: AppSpace.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      controller: rate,
                      label: AppStrings.rateLabel,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  // Dynamic milk type dropdown
                  Expanded(
                    flex: 3,
                    child: milkTypes.isEmpty
                        ? DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: milkType,
                            decoration:
                                InputDecoration(labelText: AppStrings.milkTypeLabel),
                            items: const [
                              DropdownMenuItem(value: 'gir_cow', child: Text('Gir Cow')),
                              DropdownMenuItem(value: 'cow', child: Text('Cow')),
                              DropdownMenuItem(value: 'buffalo', child: Text('Buffalo')),
                            ],
                            onChanged: (v) =>
                                setModalState(() => milkType = v ?? milkType),
                          )
                        : DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: milkTypeId,
                            decoration:
                                InputDecoration(labelText: AppStrings.milkTypeLabel),
                            items: milkTypes
                                .where((t) => t.isActive && !t.isHidden)
                                .map((t) => DropdownMenuItem(
                                      value: t.id,
                                      child: Text(t.name),
                                    ))
                                .toList(),
                            onChanged: (v) => setModalState(() => milkTypeId = v),
                          ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  // Dynamic container type dropdown
                  Expanded(
                    flex: 3,
                    child: containerTypes.isEmpty
                        ? DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: containerType,
                            decoration:
                                InputDecoration(labelText: AppStrings.containerLabel),
                            items: const [
                              DropdownMenuItem(
                                  value: 'glass_bottle', child: Text('Glass')),
                              DropdownMenuItem(
                                  value: 'plastic_bag', child: Text('Plastic')),
                            ],
                            onChanged: (v) =>
                                setModalState(() => containerType = v ?? containerType),
                          )
                        : DropdownButtonFormField<int>(
                            isExpanded: true,
                            value: containerTypeId,
                            decoration:
                                InputDecoration(labelText: AppStrings.containerLabel),
                            items: containerTypes
                                .where((t) => t.isActive && !t.isHidden)
                                .map((t) => DropdownMenuItem(
                                      value: t.id,
                                      child: Text(t.name),
                                    ))
                                .toList(),
                            onChanged: (v) => setModalState(() => containerTypeId = v),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              OwnerSheetActions(
                primaryLabel: AppStrings.settingsSave,
                onPrimary: () => Navigator.pop(context, true),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true || !mounted) {
      name.dispose();
      rate.dispose();
      return;
    }

    try {
      await ref.read(ownerRepositoryProvider).updateProduct(product.id, {
        'name': name.text.trim(),
        'rate': double.parse(rate.text.trim()),
        // Send both legacy slug and new ID fields for backward compat
        'milk_type': milkType,
        'container_type': containerType,
        if (milkTypeId != null) 'milk_type_id': milkTypeId,
        if (containerTypeId != null) 'container_type_id': containerTypeId,
      });
      ref.invalidate(ownerSettingsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      name.dispose();
      rate.dispose();
    }
  }

  Future<void> _confirmDeleteProduct(SettingsProduct product) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: AppStrings.deleteProductTitle,
      message: AppStrings.deleteProductConfirm,
      confirmLabel: AppStrings.deleteLabel,
      cancelLabel: AppStrings.cancelLabel,
      destructive: true,
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(ownerRepositoryProvider).deleteProduct(product.id);
      ref.invalidate(ownerSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.deleteProductDone)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        final message =
            e.code == 'PRODUCT_IN_USE' ? AppStrings.deleteProductBlocked : e.message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _addProduct() async {
    await context.push('/onboarding/products');
    if (mounted) ref.invalidate(ownerSettingsProvider);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(ownerSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(ownerSettingsProvider),
          child: const Text('Retry'),
        ),
      ),
      data: (settings) {
        _load(settings);

        return ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            // ── Farm profile card ────────────────────────────────────────
            OwnerSectionHeader(title: AppStrings.settingsFarmSection),
            const SizedBox(height: AppSpace.sm),
            _FarmProfileCard(
              farm: settings.farm,
              onEdit: _openFarmEditSheet,
              isDark: isDark,
            ),

            // ── Daily order schedule ─────────────────────────────────────
            const SizedBox(height: AppSpace.lg),
            OwnerSectionHeader(title: AppStrings.settingsOrderScheduleSection),
            const SizedBox(height: AppSpace.xs),
            Text(
              AppStrings.settingsOrderScheduleHint,
              style: AppText.meta.copyWith(color: inkMuted),
            ),
            const SizedBox(height: AppSpace.sm),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppStrings.settingsMorningOrderTime, style: AppText.label),
                    trailing:
                        Text(_displayTime(_morningOrderTime), style: AppText.body),
                    onTap: () => _pickOrderTime(morning: true),
                  ),
                  const Divider(height: AppSpace.lg),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppStrings.settingsEveningOrderTime, style: AppText.label),
                    trailing:
                        Text(_displayTime(_eveningOrderTime), style: AppText.body),
                    onTap: () => _pickOrderTime(morning: false),
                  ),
                ],
              ),
            ),

            // ── Owner profile card ───────────────────────────────────────
            const SizedBox(height: AppSpace.lg),
            OwnerSectionHeader(title: AppStrings.settingsOwnerSection),
            const SizedBox(height: AppSpace.sm),
            _OwnerProfileCard(
              owner: settings.owner,
              onEdit: _openOwnerEditSheet,
              isDark: isDark,
            ),

            // ── Milk products ────────────────────────────────────────────
            const SizedBox(height: AppSpace.lg),
            OwnerSectionHeader(
              title: AppStrings.settingsProductsSection,
              trailing: AppSoftIconButton(
                icon: Icons.add,
                tooltip: AppStrings.settingsAddProduct,
                onPressed: _addProduct,
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            AppCard(
              child: settings.products.isEmpty
                  ? Text(
                      AppStrings.productsEmptyHint,
                      style: AppText.body.copyWith(color: inkMuted),
                    )
                  : Column(
                      children: settings.products
                          .map(
                            (p) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(p.name, style: AppText.label),
                              subtitle: Text(
                                '${p.milkTypeLabel} · ${p.containerTypeLabel} · '
                                '₹${p.rate.toStringAsFixed(0)}${AppStrings.perLtr}',
                                style: AppText.meta.copyWith(color: inkMuted),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    tooltip: AppStrings.settingsEditProduct,
                                    onPressed: () => _editProduct(p),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 20,
                                      color: inkMuted,
                                    ),
                                    tooltip: AppStrings.deleteProductTitle,
                                    onPressed: () => _confirmDeleteProduct(p),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),

            // ── Milk types ───────────────────────────────────────────────
            const SizedBox(height: AppSpace.lg),
            _MilkTypesSection(repository: ref.read(ownerRepositoryProvider)),

            // ── Container types ──────────────────────────────────────────
            const SizedBox(height: AppSpace.lg),
            _ContainerTypesSection(repository: ref.read(ownerRepositoryProvider)),

            // ── WhatsApp sharing ─────────────────────────────────────────
            const SizedBox(height: AppSpace.lg),
            OwnerSectionHeader(title: AppStrings.settingsTemplatesSection),
            const SizedBox(height: AppSpace.xs),
            Text(
              AppStrings.settingsWhatsAppImageNote,
              style: AppText.meta.copyWith(color: inkMuted),
            ),
            const SizedBox(height: AppSpace.sm),
            AppCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.settingsIncludeFarmHeader, style: AppText.body),
                value: _includeFarmHeader,
                onChanged: (v) async {
                  setState(() => _includeFarmHeader = v);
                  try {
                    await ref.read(ownerRepositoryProvider).updateSettings(
                          OwnerSettingsUpdate(
                            documentSettings: DocumentTemplateSettings(
                              milkLogFormat: settings.documentSettings.milkLogFormat,
                              billingFormat: settings.documentSettings.billingFormat,
                              paymentReceiptFormat:
                                  settings.documentSettings.paymentReceiptFormat,
                              includeFarmHeader: v,
                            ),
                          ),
                        );
                    ref.invalidate(ownerSettingsProvider);
                  } on ApiException catch (e) {
                    if (mounted) {
                      setState(() => _includeFarmHeader = !v);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Farm profile read card
// ─────────────────────────────────────────────────────────────────────────────

class _FarmProfileCard extends StatelessWidget {
  const _FarmProfileCard({
    required this.farm,
    required this.onEdit,
    required this.isDark,
  });

  final SettingsFarm farm;
  final VoidCallback onEdit;
  final bool isDark;

  String get _cityStatePinValue {
    final city = farm.city ?? '';
    final state = farm.state ?? '';
    final zip = farm.zip ?? '';
    if (city.isEmpty && state.isEmpty && zip.isEmpty) return '—';
    final parts = <String>[];
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    final head = parts.join(', ');
    if (zip.isNotEmpty) {
      return head.isNotEmpty ? '$head · $zip' : zip;
    }
    return head.isNotEmpty ? head : '—';
  }

  @override
  Widget build(BuildContext context) {
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final ink = isDark ? AppColors.darkInk : AppColors.ink;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: name + edit button
          Row(
            children: [
              Expanded(
                child: Text(
                  farm.name?.isNotEmpty == true ? farm.name! : '—',
                  style: AppText.cardTitle.copyWith(color: ink),
                ),
              ),
              AppSoftIconButton(
                icon: Icons.edit_outlined,
                tooltip: AppStrings.settingsFarmEditTooltip,
                onPressed: onEdit,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          _InfoRow(
            label: AppStrings.settingsAddressLabel,
            value: farm.addressLine?.isNotEmpty == true ? farm.addressLine! : '—',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpace.xs),
          _InfoRow(
            label: AppStrings.settingsCityStatePinRow,
            value: _cityStatePinValue,
            isDark: isDark,
          ),
          const SizedBox(height: AppSpace.xs),
          _InfoRow(
            label: AppStrings.settingsUpiVpa,
            value: farm.upiVpa?.isNotEmpty == true ? farm.upiVpa! : '—',
            isDark: isDark,
          ),
          const SizedBox(height: AppSpace.xs),
          _InfoRow(
            label: AppStrings.settingsUpiPayeeName,
            value: farm.upiPayeeName?.isNotEmpty == true ? farm.upiPayeeName! : '—',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Owner profile read card
// ─────────────────────────────────────────────────────────────────────────────

class _OwnerProfileCard extends StatelessWidget {
  const _OwnerProfileCard({
    required this.owner,
    required this.onEdit,
    required this.isDark,
  });

  final SettingsOwner owner;
  final VoidCallback onEdit;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final ink = isDark ? AppColors.darkInk : AppColors.ink;
    final fullName = owner.fullName.isNotEmpty ? owner.fullName : '—';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fullName,
                  style: AppText.cardTitle.copyWith(color: ink),
                ),
              ),
              AppSoftIconButton(
                icon: Icons.edit_outlined,
                tooltip: AppStrings.settingsOwnerEditTooltip,
                onPressed: onEdit,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Row(
            children: [
              Text(
                AppStrings.mobileLabel,
                style: AppText.meta.copyWith(color: inkMuted),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  owner.mobile,
                  style: AppText.body.copyWith(color: inkMuted),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable info row (label + value)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final ink = isDark ? AppColors.darkInk : AppColors.ink;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: AppText.meta.copyWith(color: inkMuted)),
        ),
        Expanded(
          child: Text(value, style: AppText.body.copyWith(color: ink), textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Farm edit sheet (StatefulWidget — manages pincode lookup state internally)
// ─────────────────────────────────────────────────────────────────────────────

class _FarmEditSheet extends StatefulWidget {
  const _FarmEditSheet({
    required this.farmName,
    required this.address,
    required this.zip,
    required this.city,
    required this.state,
    required this.upiVpa,
    required this.upiPayeeName,
    required this.currentFarm,
    required this.onSave,
    required this.repository,
  });

  final TextEditingController farmName;
  final TextEditingController address;
  final TextEditingController zip;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController upiVpa;
  final TextEditingController upiPayeeName;
  final SettingsFarm currentFarm;
  final Future<void> Function(SettingsFarm) onSave;
  final dynamic repository; // OwnerRepository

  @override
  State<_FarmEditSheet> createState() => _FarmEditSheetState();
}

class _FarmEditSheetState extends State<_FarmEditSheet> {
  bool _lookingUpPincode = false;
  bool _pincodeError = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.zip.addListener(_onZipChanged);
  }

  @override
  void dispose() {
    widget.zip.removeListener(_onZipChanged);
    super.dispose();
  }

  void _onZipChanged() {
    final text = widget.zip.text;
    if (text.length == 6) {
      _doLookupPincode(text);
    }
  }

  Future<void> _doLookupPincode(String pincode) async {
    setState(() {
      _lookingUpPincode = true;
      _pincodeError = false;
    });
    try {
      final result = await widget.repository.lookupPincode(pincode);
      if (mounted) {
        widget.city.text = result.city;
        widget.state.text = result.state;
        setState(() => _lookingUpPincode = false);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _lookingUpPincode = false;
          _pincodeError = e.code == 'PINCODE_NOT_FOUND' || true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _lookingUpPincode = false;
          _pincodeError = true;
        });
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final farm = SettingsFarm(
      id: widget.currentFarm.id,
      name: widget.farmName.text.trim(),
      addressLine: widget.address.text.trim(),
      city: widget.city.text.trim(),
      state: widget.state.text.trim(),
      zip: widget.zip.text.trim(),
      upiVpa: widget.upiVpa.text.trim(),
      upiPayeeName: widget.upiPayeeName.text.trim(),
      morningOrderTime: widget.currentFarm.morningOrderTime,
      eveningOrderTime: widget.currentFarm.eveningOrderTime,
    );
    try {
      await widget.onSave(farm);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    bool autofocus = false,
    Widget? suffix,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.label.copyWith(color: inkMuted)),
        const SizedBox(height: AppSpace.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          autofocus: autofocus,
          enabled: enabled,
          style: AppText.body,
          decoration: InputDecoration(
            suffix: suffix,
          ),
        ),
      ],
    );
  }

  Widget _loadingSpinner() => const Padding(
        padding: EdgeInsets.only(right: 4),
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerSheetTitle(AppStrings.settingsEditFarmTitle),
          const SizedBox(height: AppSpace.sm),
          _buildLabeledField(
            label: AppStrings.farmNameLabel,
            controller: widget.farmName,
            autofocus: true,
            enabled: !_saving,
          ),
          const SizedBox(height: AppSpace.sm),
          _buildLabeledField(
            label: AppStrings.settingsAddressLabel,
            controller: widget.address,
            enabled: !_saving,
          ),
          const SizedBox(height: AppSpace.sm),
          // Three-column row: PIN code (flex 2) / City (flex 3) / State (flex 3)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildLabeledField(
                  label: AppStrings.settingsPinCodeLabel,
                  controller: widget.zip,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  enabled: !_saving,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                flex: 3,
                child: _buildLabeledField(
                  label: AppStrings.settingsCityLabel,
                  controller: widget.city,
                  readOnly: _lookingUpPincode,
                  enabled: !_saving,
                  suffix: _lookingUpPincode ? _loadingSpinner() : null,
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                flex: 3,
                child: _buildLabeledField(
                  label: AppStrings.settingsStateLabel,
                  controller: widget.state,
                  readOnly: _lookingUpPincode,
                  enabled: !_saving,
                  suffix: _lookingUpPincode ? _loadingSpinner() : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          // Pincode error row (conditional)
          if (_pincodeError)
            Text(
              AppStrings.settingsPincodeError,
              style: AppText.meta.copyWith(color: AppColors.danger),
            ),
          const SizedBox(height: AppSpace.md),
          _buildLabeledField(
            label: AppStrings.settingsUpiVpa,
            controller: widget.upiVpa,
            enabled: !_saving,
          ),
          const SizedBox(height: AppSpace.sm),
          _buildLabeledField(
            label: AppStrings.settingsUpiPayeeName,
            controller: widget.upiPayeeName,
            enabled: !_saving,
          ),
          const SizedBox(height: AppSpace.md),
          OwnerSheetActions(
            primaryLabel: AppStrings.settingsSave,
            loading: _saving,
            onPrimary: (_saving || _lookingUpPincode) ? null : _submit,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Owner edit sheet
// ─────────────────────────────────────────────────────────────────────────────

class _OwnerEditSheet extends StatefulWidget {
  const _OwnerEditSheet({
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.onSave,
  });

  final TextEditingController firstName;
  final TextEditingController lastName;
  final String mobile;
  final Future<void> Function(String firstName, String lastName) onSave;

  @override
  State<_OwnerEditSheet> createState() => _OwnerEditSheetState();
}

class _OwnerEditSheetState extends State<_OwnerEditSheet> {
  bool _saving = false;
  String? _firstNameError;

  Future<void> _submit() async {
    final fn = widget.firstName.text.trim();
    if (fn.isEmpty) {
      setState(() => _firstNameError = AppStrings.firstNameRequired);
      return;
    }
    setState(() {
      _firstNameError = null;
      _saving = true;
    });
    try {
      await widget.onSave(fn, widget.lastName.text.trim());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OwnerSheetTitle(AppStrings.settingsEditOwnerTitle),
        const SizedBox(height: AppSpace.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                controller: widget.firstName,
                label: AppStrings.firstNameLabel,
                enabled: !_saving,
                errorText: _firstNameError,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: AppTextField(
                controller: widget.lastName,
                label: AppStrings.lastNameLabel,
                enabled: !_saving,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        // Read-only mobile row
        Row(
          children: [
            Text(
              AppStrings.mobileLabel,
              style: AppText.label.copyWith(color: inkMuted),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                widget.mobile,
                style: AppText.body.copyWith(color: inkMuted),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        OwnerSheetActions(
          primaryLabel: AppStrings.settingsSave,
          loading: _saving,
          onPrimary: _saving ? null : _submit,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Milk types section (S6-13)
// ─────────────────────────────────────────────────────────────────────────────

class _MilkTypesSection extends ConsumerStatefulWidget {
  const _MilkTypesSection({required this.repository});
  final dynamic repository; // OwnerRepository

  @override
  ConsumerState<_MilkTypesSection> createState() => _MilkTypesSectionState();
}

class _MilkTypesSectionState extends ConsumerState<_MilkTypesSection> {
  bool _adding = false;

  Future<void> _openAddSheet() async {
    final nameCtrl = TextEditingController();
    await showOwnerBottomSheet<void>(
      context: context,
      child: _AddMilkTypeSheet(
        controller: nameCtrl,
        adding: _adding,
        onSave: (name) async {
          setState(() => _adding = true);
          try {
            await widget.repository.addMilkType(name);
            ref.invalidate(milkTypesProvider);
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.settingsMilkTypeAdded)),
              );
            }
          } on ApiException catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.message)));
            }
          } finally {
            if (mounted) setState(() => _adding = false);
          }
        },
      ),
    );
    nameCtrl.dispose();
  }

  Future<void> _toggleVisibility(MilkTypeItem item, bool newVisible) async {
    // Optimistic: invalidate and re-fetch (actual optimistic toggle done locally via override)
    try {
      if (newVisible) {
        await widget.repository.unhideMilkType(item.id);
      } else {
        await widget.repository.hideMilkType(item.id);
      }
      ref.invalidate(milkTypesProvider);
    } on ApiException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.settingsToggleError)),
        );
        ref.invalidate(milkTypesProvider);
      }
    }
  }

  Future<void> _confirmDelete(MilkTypeItem item) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete ${item.name}?',
      message: AppStrings.settingsDeleteTypeMessage,
      confirmLabel: AppStrings.deleteLabel,
      cancelLabel: AppStrings.cancelLabel,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.deleteMilkType(item.id);
      ref.invalidate(milkTypesProvider);
    } on ApiException catch (e) {
      if (mounted) {
        final msg = e.code == 'TYPE_IN_USE'
            ? AppStrings.settingsDeleteTypeBlocked
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        ref.invalidate(milkTypesProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final inkFaint = isDark ? AppColors.darkInkFaint : AppColors.inkFaint;
    final milkTypesAsync = ref.watch(milkTypesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OwnerSectionHeader(
          title: AppStrings.settingsMilkTypesSection,
          trailing: AppSoftIconButton(
            icon: Icons.add,
            tooltip: AppStrings.settingsAddMilkType,
            onPressed: _openAddSheet,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        milkTypesAsync.when(
          loading: () => const AppCard(child: Center(child: CircularProgressIndicator())),
          error: (_, __) => AppCard(
            child: Center(
              child: TextButton(
                onPressed: () => ref.invalidate(milkTypesProvider),
                child: const Text('Retry'),
              ),
            ),
          ),
          data: (types) {
            final visible = types.where((t) => !t.isHidden || t.isSystem).toList();
            if (visible.isEmpty && types.every((t) => t.isHidden)) {
              return OwnerDashedEmptyCard(
                icon: Icons.water_drop_outlined,
                message: AppStrings.settingsMilkTypesEmpty,
              );
            }
            if (types.isEmpty) {
              return OwnerDashedEmptyCard(
                icon: Icons.water_drop_outlined,
                message: AppStrings.settingsMilkTypesEmpty,
              );
            }
            return AppCard(
              child: Column(
                children: [
                  for (int i = 0; i < types.length; i++) ...[
                    _MilkTypeRow(
                      item: types[i],
                      inkMuted: inkMuted,
                      inkFaint: inkFaint,
                      onToggle: (visible) => _toggleVisibility(types[i], visible),
                      onDelete: () => _confirmDelete(types[i]),
                    ),
                    if (i < types.length - 1) const Divider(height: AppSpace.lg),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MilkTypeRow extends StatefulWidget {
  const _MilkTypeRow({
    required this.item,
    required this.inkMuted,
    required this.inkFaint,
    required this.onToggle,
    required this.onDelete,
  });

  final MilkTypeItem item;
  final Color inkMuted;
  final Color inkFaint;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  State<_MilkTypeRow> createState() => _MilkTypeRowState();
}

class _MilkTypeRowState extends State<_MilkTypeRow> {
  late bool _visible;

  @override
  void initState() {
    super.initState();
    _visible = !widget.item.isHidden;
  }

  @override
  void didUpdateWidget(_MilkTypeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visible = !widget.item.isHidden;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.item.name, style: AppText.label),
      subtitle: widget.item.isSystem
          ? Text(
              AppStrings.settingsSystemDefault,
              style: AppText.meta.copyWith(color: widget.inkFaint),
            )
          : null,
      trailing: widget.item.isSystem
          ? Semantics(
              label: '${widget.item.name} — ${_visible ? 'visible' : 'hidden'}',
              child: Transform.scale(
                scale: 0.72,
                alignment: Alignment.centerRight,
                child: Switch(
                  value: _visible,
                  onChanged: (v) {
                    setState(() => _visible = v); // optimistic
                    widget.onToggle(v);
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            )
          : Tooltip(
              message: AppStrings.settingsDeleteTypeTooltip,
              child: IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: widget.inkMuted),
                onPressed: widget.onDelete,
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add milk type sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddMilkTypeSheet extends StatefulWidget {
  const _AddMilkTypeSheet({
    required this.controller,
    required this.adding,
    required this.onSave,
  });

  final TextEditingController controller;
  final bool adding;
  final Future<void> Function(String name) onSave;

  @override
  State<_AddMilkTypeSheet> createState() => _AddMilkTypeSheetState();
}

class _AddMilkTypeSheetState extends State<_AddMilkTypeSheet> {
  String? _nameError;
  bool _saving = false;

  Future<void> _submit() async {
    final name = widget.controller.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = AppStrings.settingsMilkTypeNameRequired);
      return;
    }
    setState(() {
      _nameError = null;
      _saving = true;
    });
    try {
      await widget.onSave(name);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OwnerSheetTitle(AppStrings.settingsAddMilkTypeTitle),
        const SizedBox(height: AppSpace.sm),
        AppTextField(
          controller: widget.controller,
          label: AppStrings.settingsMilkTypeNameLabel,
          hint: AppStrings.settingsMilkTypeNameHint,
          enabled: !_saving,
          errorText: _nameError,
        ),
        const SizedBox(height: AppSpace.md),
        OwnerSheetActions(
          primaryLabel: AppStrings.settingsSave,
          loading: _saving,
          onPrimary: _saving ? null : _submit,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Container types section (S6-14)
// ─────────────────────────────────────────────────────────────────────────────

class _ContainerTypesSection extends ConsumerStatefulWidget {
  const _ContainerTypesSection({required this.repository});
  final dynamic repository;

  @override
  ConsumerState<_ContainerTypesSection> createState() =>
      _ContainerTypesSectionState();
}

class _ContainerTypesSectionState extends ConsumerState<_ContainerTypesSection> {
  bool _adding = false;

  Future<void> _openAddSheet() async {
    await showOwnerBottomSheet<void>(
      context: context,
      child: _AddContainerTypeSheet(
        onSave: (material, size) async {
          setState(() => _adding = true);
          try {
            await widget.repository.addContainerType(material: material, size: size);
            ref.invalidate(containerTypesProvider);
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.settingsContainerTypeAdded)),
              );
            }
          } on ApiException catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(e.message)));
            }
          } finally {
            if (mounted) setState(() => _adding = false);
          }
        },
      ),
    );
  }

  Future<void> _toggleVisibility(ContainerTypeItem item, bool newVisible) async {
    try {
      if (newVisible) {
        await widget.repository.unhideContainerType(item.id);
      } else {
        await widget.repository.hideContainerType(item.id);
      }
      ref.invalidate(containerTypesProvider);
    } on ApiException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.settingsToggleError)),
        );
        ref.invalidate(containerTypesProvider);
      }
    }
  }

  Future<void> _confirmDelete(ContainerTypeItem item) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete ${item.name}?',
      message: AppStrings.settingsDeleteTypeMessage,
      confirmLabel: AppStrings.deleteLabel,
      cancelLabel: AppStrings.cancelLabel,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository.deleteContainerType(item.id);
      ref.invalidate(containerTypesProvider);
    } on ApiException catch (e) {
      if (mounted) {
        final msg = e.code == 'TYPE_IN_USE'
            ? AppStrings.settingsDeleteTypeBlocked
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        ref.invalidate(containerTypesProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final inkFaint = isDark ? AppColors.darkInkFaint : AppColors.inkFaint;
    final containerTypesAsync = ref.watch(containerTypesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OwnerSectionHeader(
          title: AppStrings.settingsContainerTypesSection,
          trailing: AppSoftIconButton(
            icon: Icons.add,
            tooltip: AppStrings.settingsAddContainerType,
            onPressed: _openAddSheet,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        containerTypesAsync.when(
          loading: () => const AppCard(child: Center(child: CircularProgressIndicator())),
          error: (_, __) => AppCard(
            child: Center(
              child: TextButton(
                onPressed: () => ref.invalidate(containerTypesProvider),
                child: const Text('Retry'),
              ),
            ),
          ),
          data: (types) {
            if (types.isEmpty) {
              return OwnerDashedEmptyCard(
                icon: Icons.inventory_2_outlined,
                message: AppStrings.settingsContainerTypesEmpty,
              );
            }
            return AppCard(
              child: Column(
                children: [
                  for (int i = 0; i < types.length; i++) ...[
                    _ContainerTypeRow(
                      item: types[i],
                      inkMuted: inkMuted,
                      inkFaint: inkFaint,
                      onToggle: (visible) => _toggleVisibility(types[i], visible),
                      onDelete: () => _confirmDelete(types[i]),
                    ),
                    if (i < types.length - 1) const Divider(height: AppSpace.lg),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ContainerTypeRow extends StatefulWidget {
  const _ContainerTypeRow({
    required this.item,
    required this.inkMuted,
    required this.inkFaint,
    required this.onToggle,
    required this.onDelete,
  });

  final ContainerTypeItem item;
  final Color inkMuted;
  final Color inkFaint;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  State<_ContainerTypeRow> createState() => _ContainerTypeRowState();
}

class _ContainerTypeRowState extends State<_ContainerTypeRow> {
  late bool _visible;

  @override
  void initState() {
    super.initState();
    _visible = !widget.item.isHidden;
  }

  @override
  void didUpdateWidget(_ContainerTypeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visible = !widget.item.isHidden;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.item.name, style: AppText.label),
      subtitle: widget.item.isSystem
          ? Text(
              AppStrings.settingsSystemDefault,
              style: AppText.meta.copyWith(color: widget.inkFaint),
            )
          : null,
      trailing: widget.item.isSystem
          ? Semantics(
              label: '${widget.item.name} — ${_visible ? 'visible' : 'hidden'}',
              child: Transform.scale(
                scale: 0.72,
                alignment: Alignment.centerRight,
                child: Switch(
                  value: _visible,
                  onChanged: (v) {
                    setState(() => _visible = v); // optimistic
                    widget.onToggle(v);
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            )
          : Tooltip(
              message: AppStrings.settingsDeleteTypeTooltip,
              child: IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: widget.inkMuted),
                onPressed: widget.onDelete,
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add container type sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddContainerTypeSheet extends StatefulWidget {
  const _AddContainerTypeSheet({required this.onSave});
  final Future<void> Function(String material, String size) onSave;

  @override
  State<_AddContainerTypeSheet> createState() => _AddContainerTypeSheetState();
}

class _AddContainerTypeSheetState extends State<_AddContainerTypeSheet> {
  String? _material;
  final _sizeCtrl = TextEditingController();
  String? _materialError;
  String? _sizeError;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _sizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    String? matErr;
    String? sizeErr;
    if (_material == null) matErr = AppStrings.settingsMaterialRequired;
    if (_sizeCtrl.text.trim().isEmpty) sizeErr = AppStrings.settingsSizeRequired;
    if (matErr != null || sizeErr != null) {
      setState(() {
        _materialError = matErr;
        _sizeError = sizeErr;
      });
      return;
    }
    setState(() {
      _materialError = null;
      _sizeError = null;
      _saving = true;
    });
    try {
      await widget.onSave(_material!, _sizeCtrl.text.trim());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OwnerSheetTitle(AppStrings.settingsAddContainerTypeTitle),
        const SizedBox(height: AppSpace.sm),
        DropdownButtonFormField<String>(
          value: _material,
          decoration: InputDecoration(
            labelText: AppStrings.settingsMaterialLabel,
            hintText: AppStrings.settingsMaterialHint,
            errorText: _materialError,
          ),
          items: const [
            DropdownMenuItem(value: 'glass_bottle', child: Text('Glass Bottle')),
            DropdownMenuItem(value: 'plastic_bag', child: Text('Plastic Bag')),
          ],
          onChanged: _saving ? null : (v) => setState(() => _material = v),
        ),
        const SizedBox(height: AppSpace.sm),
        AppTextField(
          controller: _sizeCtrl,
          label: AppStrings.settingsSizeLabel,
          hint: AppStrings.settingsSizeHint,
          enabled: !_saving,
          errorText: _sizeError,
        ),
        const SizedBox(height: AppSpace.md),
        OwnerSheetActions(
          primaryLabel: AppStrings.settingsSave,
          loading: _saving,
          onPrimary: _saving ? null : _submit,
        ),
      ],
    );
  }
}
