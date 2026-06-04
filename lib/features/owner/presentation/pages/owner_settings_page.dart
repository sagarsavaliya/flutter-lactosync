import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
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
  final _farmName = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _upiVpa = TextEditingController();
  final _upiPayeeName = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  bool _includeFarmHeader = true;
  TimeOfDay _morningOrderTime = const TimeOfDay(hour: 5, minute: 0);
  TimeOfDay _eveningOrderTime = const TimeOfDay(hour: 15, minute: 0);
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _farmName.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _upiVpa.dispose();
    _upiPayeeName.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  void _load(OwnerSettings settings) {
    if (_loaded) return;
    _farmName.text = settings.farm.name ?? '';
    _address.text = settings.farm.addressLine ?? '';
    _city.text = settings.farm.city ?? '';
    _state.text = settings.farm.state ?? '';
    _zip.text = settings.farm.zip ?? '';
    _upiVpa.text = settings.farm.upiVpa ?? '';
    _upiPayeeName.text = settings.farm.upiPayeeName ?? '';
    _firstName.text = settings.owner.firstName ?? '';
    _lastName.text = settings.owner.lastName ?? '';
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
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(ownerRepositoryProvider).updateSettings(
            OwnerSettingsUpdate(
              farm: SettingsFarm(
                id: 0,
                name: _farmName.text.trim(),
                addressLine: _address.text.trim(),
                city: _city.text.trim(),
                state: _state.text.trim(),
                zip: _zip.text.trim(),
                upiVpa: _upiVpa.text.trim(),
                upiPayeeName: _upiPayeeName.text.trim(),
                morningOrderTime: _formatTime(_morningOrderTime),
                eveningOrderTime: _formatTime(_eveningOrderTime),
              ),
              owner: SettingsOwner(
                firstName: _firstName.text.trim(),
                lastName: _lastName.text.trim(),
                fullName: '',
                mobile: '',
              ),
              documentSettings: DocumentTemplateSettings(
                milkLogFormat: DocumentShareFormat.image,
                billingFormat: DocumentShareFormat.image,
                paymentReceiptFormat: DocumentShareFormat.image,
                includeFarmHeader: _includeFarmHeader,
              ),
            ),
          );
      ref.invalidate(ownerSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.settingsSaved)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editProduct(SettingsProduct product) async {
    final name = TextEditingController(text: product.name);
    final rate = TextEditingController(text: product.rate.toStringAsFixed(0));
    var milkType = product.milkType;
    var containerType = product.containerType;

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
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: milkType,
                      decoration: InputDecoration(labelText: AppStrings.milkTypeLabel),
                      items: const [
                        DropdownMenuItem(value: 'gir_cow', child: Text('Gir Cow')),
                        DropdownMenuItem(value: 'cow', child: Text('Cow')),
                        DropdownMenuItem(value: 'buffalo', child: Text('Buffalo')),
                      ],
                      onChanged: (v) => setModalState(() => milkType = v ?? milkType),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: containerType,
                      decoration: InputDecoration(labelText: AppStrings.containerLabel),
                      items: const [
                        DropdownMenuItem(value: 'glass_bottle', child: Text('Glass')),
                        DropdownMenuItem(value: 'plastic_bag', child: Text('Plastic')),
                      ],
                      onChanged: (v) => setModalState(() => containerType = v ?? containerType),
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
        'milk_type': milkType,
        'container_type': containerType,
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
        final message = e.code == 'PRODUCT_IN_USE'
            ? AppStrings.deleteProductBlocked
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _addProduct() async {
    await context.push('/onboarding/products');
    if (mounted) ref.invalidate(ownerSettingsProvider);
  }

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
            OwnerSectionHeader(title: AppStrings.settingsFarmSection),
            const SizedBox(height: AppSpace.sm),
            AppCard(
              child: Column(
                children: [
                  AppTextField(controller: _farmName, label: AppStrings.farmNameLabel),
                  const SizedBox(height: AppSpace.sm),
                  AppTextField(controller: _address, label: AppStrings.addressLabel),
                  const SizedBox(height: AppSpace.sm),
                  AppTextField(controller: _city, label: AppStrings.cityLabel),
                  const SizedBox(height: AppSpace.sm),
                  AppTextField(controller: _state, label: AppStrings.stateLabel),
                  const SizedBox(height: AppSpace.sm),
                  AppTextField(
                    controller: _zip,
                    label: AppStrings.zipLabel,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  AppTextField(
                    controller: _upiVpa,
                    label: AppStrings.settingsUpiVpa,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  AppTextField(
                    controller: _upiPayeeName,
                    label: AppStrings.settingsUpiPayeeName,
                  ),
                ],
              ),
            ),
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
                    trailing: Text(_formatTime(_morningOrderTime), style: AppText.body),
                    onTap: () => _pickOrderTime(morning: true),
                  ),
                  const Divider(height: AppSpace.lg),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppStrings.settingsEveningOrderTime, style: AppText.label),
                    trailing: Text(_formatTime(_eveningOrderTime), style: AppText.body),
                    onTap: () => _pickOrderTime(morning: false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            OwnerSectionHeader(title: AppStrings.settingsOwnerSection),
            const SizedBox(height: AppSpace.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(controller: _firstName, label: AppStrings.firstNameLabel),
                  const SizedBox(height: AppSpace.sm),
                  AppTextField(controller: _lastName, label: AppStrings.lastNameLabel),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    '${AppStrings.mobileLabel}: ${settings.owner.mobile}',
                    style: AppText.body.copyWith(color: inkMuted),
                  ),
                ],
              ),
            ),
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
                  ? Text(AppStrings.productsEmptyHint, style: AppText.body.copyWith(color: inkMuted))
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
                                    icon: Icon(Icons.delete_outline, size: 20, color: inkMuted),
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
                onChanged: (v) => setState(() => _includeFarmHeader = v),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            AppButton(
              label: AppStrings.settingsSave,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        );
      },
    );
  }
}
