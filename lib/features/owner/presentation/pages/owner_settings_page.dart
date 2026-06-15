import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/redesign_tokens.dart';
import '../../domain/entities/settings_models.dart';
import '../../domain/repositories/owner_repository.dart';
import '../providers/owner_provider.dart';
import '../widgets/customer_detail/customer_detail_styles.dart';
import '../widgets/owner_design_system.dart';
import '../widgets/owner_screen_widgets.dart';
import '../../../../core/widgets/app_snackbar.dart';

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
  // OR-10: prefill toggle
  bool _prefillCustomerAddress = false;

  // Per-sheet loading flags
  bool _savingFarm = false;

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
    _prefillCustomerAddress = settings.farm.prefillCustomerAddress;
    _loaded = true;
  }

  // OR-10: optimistic prefill toggle
  Future<void> _onPrefillToggle(bool newValue) async {
    final settings = _settings;
    if (settings == null) return;
    setState(() => _prefillCustomerAddress = newValue);
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
                morningOrderTime: settings.farm.morningOrderTime,
                eveningOrderTime: settings.farm.eveningOrderTime,
                prefillCustomerAddress: newValue,
              ),
            ),
          );
      ref.invalidate(ownerSettingsProvider);
    } on ApiException catch (_) {
      if (mounted) {
        setState(() => _prefillCustomerAddress = !newValue);
        AppSnackBar.show(context, AppStrings.settingsPrefillSaveFailed);
      }
    }
  }

  TimeOfDay _parseTime(String? value) {
    final parts = (value ?? '05:00').split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 5,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String _formatTimeForApi(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
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
                morningOrderTime: _formatTimeForApi(_morningOrderTime),
                eveningOrderTime: _formatTimeForApi(_eveningOrderTime),
                prefillCustomerAddress: _prefillCustomerAddress,
              ),
            ),
          );
      ref.invalidate(ownerSettingsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        AppSnackBar.show(context, e.message);
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
              AppSnackBar.show(context, AppStrings.settingsSaved);
            }
          } on ApiException catch (e) {
            if (mounted) {
              AppSnackBar.show(context, e.message);
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
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(ownerSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              AppStrings.settingsTitle,
              style: AppText.screenTitle.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: CustomerDetailColors.accent,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 16),
            OwnerSettingsSectionLabel(
              label: AppStrings.settingsFarmSection,
              icon: LucideIcons.home,
            ),
            _FarmProfileCard(
              // Use local _prefillCustomerAddress for optimistic toggle display.
              farm: SettingsFarm(
                id: settings.farm.id,
                name: settings.farm.name,
                addressLine: settings.farm.addressLine,
                city: settings.farm.city,
                state: settings.farm.state,
                zip: settings.farm.zip,
                upiVpa: settings.farm.upiVpa,
                upiPayeeName: settings.farm.upiPayeeName,
                morningOrderTime: settings.farm.morningOrderTime,
                eveningOrderTime: settings.farm.eveningOrderTime,
                prefillCustomerAddress: _prefillCustomerAddress,
              ),
              onEdit: _openFarmEditSheet,
              isDark: isDark,
              onPrefillToggle: _onPrefillToggle,
            ),

            OwnerSettingsSectionLabel(
              label: AppStrings.settingsOrderScheduleSection,
              icon: LucideIcons.clock3,
            ),
            OwnerSettingsCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ScheduleTimeRow(
                    icon: LucideIcons.sun,
                    iconColor: const Color(0xFFE89A2E),
                    title: AppStrings.settingsMorningOrderTime,
                    timeLabel: _displayTime(_morningOrderTime),
                    onTap: () => _pickOrderTime(morning: true),
                  ),
                  const Divider(height: 1, thickness: 1, color: RedesignTokens.divider),
                  _ScheduleTimeRow(
                    icon: LucideIcons.moon,
                    iconColor: const Color(0xFF5E78B0),
                    title: AppStrings.settingsEveningOrderTime,
                    timeLabel: _displayTime(_eveningOrderTime),
                    onTap: () => _pickOrderTime(morning: false),
                  ),
                ],
              ),
            ),

            // ── OR-08: Products ──────────────────────────────────────────
            const SizedBox(height: AppSpace.lg),
            const _ProductsSection(),

            // ── Milk types ───────────────────────────────────────────────
            const SizedBox(height: AppSpace.lg),
            _MilkTypesSection(repository: ref.read(ownerRepositoryProvider)),

            // ── OR-07: Container types ───────────────────────────────────
            const SizedBox(height: AppSpace.lg),
            const _ContainerTypesSection(),

            OwnerSettingsSectionLabel(
              label: AppStrings.settingsTemplatesSection,
              icon: LucideIcons.messageCircle,
            ),
            OwnerSettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.settingsWhatsAppImageNote,
                    style: AppText.meta.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CustomerDetailColors.iconMuted,
                    ),
                  ),
                  const Divider(height: 24, color: CustomerDetailColors.divider),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.settingsIncludeFarmHeader,
                          style: AppText.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: CustomerDetailColors.onSurface,
                          ),
                        ),
                      ),
                      Switch(
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
                              AppSnackBar.show(context, e.message);
                            }
                          }
                        },
                        activeTrackColor: RedesignTokens.accent,
                      ),
                    ],
                  ),
                ],
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
    required this.onPrefillToggle,
  });

  final SettingsFarm farm;
  final VoidCallback onEdit;
  final bool isDark;
  final ValueChanged<bool> onPrefillToggle;

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
    return OwnerSettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CustomerDetailColors.avatarBg,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(LucideIcons.home, size: 20, color: CustomerDetailColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farm.name?.isNotEmpty == true ? farm.name! : '—',
                      style: AppText.cardTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CustomerDetailColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _cityStatePinValue,
                      style: AppText.meta.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CustomerDetailColors.iconMuted,
                      ),
                    ),
                  ],
                ),
              ),
              OwnerIconActionButton(
                icon: LucideIcons.pencil,
                size: 34,
                background: CustomerDetailColors.accentLight,
                border: CustomerDetailColors.accentBorder,
                iconColor: CustomerDetailColors.accent,
                onTap: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Divider(color: CustomerDetailColors.divider, height: 1),
          const SizedBox(height: 13),
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
          const Divider(height: 1, color: CustomerDetailColors.divider),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.settingsPrefillToggleTitle,
                      style: AppText.cardTitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: CustomerDetailColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.settingsPrefillToggleHint,
                      style: AppText.meta.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CustomerDetailColors.iconMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: farm.prefillCustomerAddress,
                onChanged: onPrefillToggle,
                activeTrackColor: RedesignTokens.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Owner profile read card
// ─────────────────────────────────────────────────────────────────────────────

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
  final OwnerRepository repository;

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
      // Preserve the prefill toggle value when saving other farm fields.
      prefillCustomerAddress: widget.currentFarm.prefillCustomerAddress,
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
// Milk types section (S6-13)
// ─────────────────────────────────────────────────────────────────────────────

class _MilkTypesSection extends ConsumerStatefulWidget {
  const _MilkTypesSection({required this.repository});
  final OwnerRepository repository;

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
              AppSnackBar.show(context, AppStrings.settingsMilkTypeAdded);
            }
          } on ApiException catch (e) {
            if (mounted) {
              AppSnackBar.show(context, e.message);
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
        AppSnackBar.show(context, AppStrings.settingsToggleError);
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
        AppSnackBar.show(context, msg);
        ref.invalidate(milkTypesProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final milkTypesAsync = ref.watch(milkTypesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OwnerSettingsSectionLabel(
          label: AppStrings.settingsMilkTypesSection,
          icon: LucideIcons.list,
          trailing: Material(
            color: CustomerDetailColors.accentLight,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _openAddSheet,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CustomerDetailColors.accentBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 14, color: CustomerDetailColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.settingsAddMilkType,
                      style: AppText.meta.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: CustomerDetailColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        milkTypesAsync.when(
          loading: () => const OwnerSettingsCard(
            child: Center(child: CircularProgressIndicator(color: CustomerDetailColors.accent)),
          ),
          error: (_, __) => OwnerSettingsCard(
            child: Center(
              child: TextButton(
                onPressed: () => ref.invalidate(milkTypesProvider),
                child: const Text('Retry'),
              ),
            ),
          ),
          data: (types) {
            if (types.isEmpty) {
              return OwnerDashedEmptyCard(
                icon: LucideIcons.droplets,
                message: AppStrings.settingsMilkTypesEmpty,
              );
            }
            return OwnerSettingsCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (int i = 0; i < types.length; i++) ...[
                    _MilkTypeRow(
                      item: types[i],
                      inkMuted: CustomerDetailColors.iconMuted,
                      inkFaint: CustomerDetailColors.labelMuted,
                      onToggle: (visible) => _toggleVisibility(types[i], visible),
                      onDelete: () => _confirmDelete(types[i]),
                    ),
                    if (i < types.length - 1)
                      Divider(height: 1, color: CustomerDetailColors.divider),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      title: Text(
        widget.item.name,
        style: AppText.cardTitle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: RedesignTokens.ink,
        ),
      ),
      subtitle: widget.item.isSystem
          ? Text(
              AppStrings.settingsSystemDefault,
              style: AppText.meta.copyWith(color: widget.inkFaint),
            )
          : null,
      trailing: widget.item.isSystem
          ? Semantics(
              label: '${widget.item.name} — ${_visible ? 'visible' : 'hidden'}',
              child: Switch(
                value: _visible,
                onChanged: (v) {
                  setState(() => _visible = v); // optimistic
                  widget.onToggle(v);
                },
                activeTrackColor: RedesignTokens.accent,
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
// OR-07: Container types section — grouped card UI with size chips
// ─────────────────────────────────────────────────────────────────────────────

class _ContainerTypesSection extends ConsumerStatefulWidget {
  const _ContainerTypesSection({super.key});

  @override
  ConsumerState<_ContainerTypesSection> createState() =>
      _ContainerTypesSectionState();
}

class _ContainerTypesSectionState extends ConsumerState<_ContainerTypesSection> {
  Future<void> _openAddSheet() async {
    await showOwnerBottomSheet<void>(
      context: context,
      child: _AddContainerTypeSheet(
        onSave: (name, sizes) async {
          try {
            await ref
                .read(ownerRepositoryProvider)
                .createOwnerContainerType(name: name, sizes: sizes);
            ref.invalidate(ownerContainerTypesProvider);
            if (mounted) {
              Navigator.of(context).pop();
              AppSnackBar.show(context, AppStrings.settingsContainerTypeAdded);
            }
          } on ApiException catch (e) {
            if (mounted) {
              AppSnackBar.show(context, e.message);
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(OwnerContainerType item) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: AppStrings.settingsContainerTypeRemoveTitle,
      message: '"${item.name}" ${AppStrings.settingsContainerTypeRemoveBody}',
      confirmLabel: AppStrings.settingsContainerTypeRemoveConfirm,
      cancelLabel: AppStrings.cancelLabel,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(ownerRepositoryProvider).deleteOwnerContainerType(item.id);
      ref.invalidate(ownerContainerTypesProvider);
      if (mounted) {
        AppSnackBar.show(context, AppStrings.settingsContainerTypeRemoved);
      }
    } on ApiException catch (e) {
      if (mounted) {
        AppSnackBar.show(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typesAsync = ref.watch(ownerContainerTypesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OwnerSettingsSectionLabel(
          label: AppStrings.settingsContainerTypesSection,
          icon: LucideIcons.package,
          trailing: Material(
            color: CustomerDetailColors.accentLight,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _openAddSheet,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CustomerDetailColors.accentBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 14, color: CustomerDetailColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.settingsAddContainerType,
                      style: AppText.meta.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: CustomerDetailColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        typesAsync.when(
          loading: () => const OwnerSettingsCard(
            child: Center(child: CircularProgressIndicator(color: CustomerDetailColors.accent)),
          ),
          error: (_, __) => OwnerSettingsCard(
            child: Center(
              child: TextButton(
                onPressed: () => ref.invalidate(ownerContainerTypesProvider),
                child: const Text('Retry'),
              ),
            ),
          ),
          data: (types) {
            if (types.isEmpty) {
              return OwnerDashedEmptyCard(
                icon: LucideIcons.package,
                message: AppStrings.settingsContainerTypesEmpty,
              );
            }
            return Column(
              children: [
                for (final ct in types) ...[
                  _ContainerTypeCard(
                    item: ct,
                    isDark: isDark,
                    onDelete: () => _confirmDelete(ct),
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// One card per container type
// ─────────────────────────────────────────────────────────────────────────────

class _ContainerTypeCard extends StatelessWidget {
  const _ContainerTypeCard({
    required this.item,
    required this.isDark,
    required this.onDelete,
  });

  final OwnerContainerType item;
  final bool isDark;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? AppColors.darkInk : AppColors.ink;

    return OwnerSettingsCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name row + badge/delete
          Row(
            children: [
              Expanded(
                child: Text(item.name,
                    style: AppText.cardTitle.copyWith(color: ink)),
              ),
              if (item.isSystem) _SystemBadge(isDark: isDark),
              if (!item.isSystem)
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      size: 20, color: AppColors.danger),
                  tooltip: AppStrings.settingsContainerTypeRemoveConfirm,
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
          if (item.sizes.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: item.sizeLabels
                  .map((label) => _SizeChip(label: label))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small pill "System" badge.
class _SystemBadge extends StatelessWidget {
  const _SystemBadge({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final fill = isDark ? AppColors.darkInkFaint : AppColors.inkFaint;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 2),
      decoration: BoxDecoration(
        color: fill.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 11, color: inkMuted),
          const SizedBox(width: 2),
          Text(
            'System',
            style: AppText.meta.copyWith(
              fontSize: 10,
              color: inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only size chip.
class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: RedesignTokens.accentLight,
        borderRadius: BorderRadius.circular(RedesignTokens.chipRadius),
        border: Border.all(color: RedesignTokens.accentBorder),
      ),
      child: Text(
        label,
        style: AppText.meta.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: RedesignTokens.accent,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OR-07: Add container type bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddContainerTypeSheet extends StatefulWidget {
  const _AddContainerTypeSheet({required this.onSave});
  final Future<void> Function(String name, List<double> sizes) onSave;

  @override
  State<_AddContainerTypeSheet> createState() => _AddContainerTypeSheetState();
}

class _AddContainerTypeSheetState extends State<_AddContainerTypeSheet> {
  final _nameCtrl = TextEditingController();
  final List<double> _sizes = [];
  String? _nameError;
  String? _sizesError;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addSizeValue() async {
    final ctrl = TextEditingController();
    double? result;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          String? err;
          return AlertDialog(
            title: const Text(
              AppStrings.settingsContainerTypeAddSizeTitle,
              style: AppText.sectionTitle,
            ),
            content: StatefulBuilder(
              builder: (ctx2, setFieldState) => TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppStrings.settingsContainerTypeAddSizeLabel,
                  hintText: AppStrings.settingsContainerTypeAddSizeHint,
                  errorText: err,
                ),
                onSubmitted: (_) {
                  final v = double.tryParse(ctrl.text.trim());
                  if (v == null || v <= 0) {
                    setFieldState(() =>
                        err = AppStrings.settingsContainerTypeAddSizeInvalid);
                    return;
                  }
                  result = v;
                  Navigator.of(ctx).pop();
                },
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(
                AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        final v = double.tryParse(ctrl.text.trim());
                        if (v == null || v <= 0) {
                          setDialogState(() => err =
                              AppStrings.settingsContainerTypeAddSizeInvalid);
                          return;
                        }
                        result = v;
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    ctrl.dispose();
    if (result != null && mounted) {
      final v = result!;
      if (!_sizes.contains(v)) {
        setState(() {
          _sizes.add(v);
          _sizes.sort();
          _sizesError = null;
        });
      }
    }
  }

  void _removeSize(double size) {
    setState(() => _sizes.remove(size));
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    String? nameErr;
    String? sizeErr;
    if (name.isEmpty) nameErr = AppStrings.settingsContainerTypeNameRequired;
    if (_sizes.isEmpty) sizeErr = AppStrings.settingsContainerTypeSizesRequired;
    if (nameErr != null || sizeErr != null) {
      setState(() {
        _nameError = nameErr;
        _sizesError = sizeErr;
      });
      return;
    }
    setState(() {
      _nameError = null;
      _sizesError = null;
      _saving = true;
    });
    try {
      await widget.onSave(name, List<double>.from(_sizes));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerSheetTitle(AppStrings.settingsAddContainerTypeTitle),
          const SizedBox(height: AppSpace.md),
          AppTextField(
            controller: _nameCtrl,
            label: AppStrings.settingsContainerTypeNameLabel,
            hint: AppStrings.settingsContainerTypeNameHint,
            enabled: !_saving,
            errorText: _nameError,
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            AppStrings.settingsContainerTypeSizesLabel,
            style: AppText.label.copyWith(color: inkMuted),
          ),
          const SizedBox(height: AppSpace.xs),
          Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              ..._sizes.map(
                (s) => Chip(
                  label: Text(formatSizeLabel(s), style: AppText.meta.copyWith(color: Colors.white)),
                  backgroundColor: AppColors.primary,
                  side: BorderSide.none,
                  deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                  onDeleted: _saving ? null : () => _removeSize(s),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              ActionChip(
                label: const Text('+ Add size'),
                backgroundColor:
                    isDark ? AppColors.darkSurface : AppColors.surface,
                side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border),
                onPressed: _saving ? null : _addSizeValue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          if (_sizesError != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              _sizesError!,
              style: AppText.meta.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          OwnerSheetActions(
            primaryLabel: AppStrings.settingsSave,
            loading: _saving,
            onPrimary: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OR-08: Products section — new list tile format + add form
// ─────────────────────────────────────────────────────────────────────────────

class _ProductsSection extends ConsumerStatefulWidget {
  const _ProductsSection({super.key});

  @override
  ConsumerState<_ProductsSection> createState() => _ProductsSectionState();
}

class _ProductsSectionState extends ConsumerState<_ProductsSection> {
  Future<void> _openAddSheet() async {
    await showOwnerBottomSheet<void>(
      context: context,
      child: _AddProductSheet(
        onSave: (milkTypeId, containerTypeId, rate) async {
          try {
            await ref.read(ownerRepositoryProvider).createOwnerProduct(
                  milkTypeId: milkTypeId,
                  containerTypeId: containerTypeId,
                  rate: rate,
                );
            ref.invalidate(ownerProductsProvider);
            if (mounted) {
              Navigator.of(context).pop();
              AppSnackBar.show(context, AppStrings.settingsProductAdded);
            }
          } on ApiException catch (e) {
            if (mounted) {
              AppSnackBar.show(context, e.message);
            }
          }
        },
      ),
    );
  }

  Future<void> _openEditSheet(OwnerProduct product) async {
    await showOwnerBottomSheet<void>(
      context: context,
      child: _EditProductSheet(
        product: product,
        onSave: (milkTypeId, containerTypeId, rate) async {
          try {
            await ref.read(ownerRepositoryProvider).updateProduct(
                  product.id,
                  {
                    'milk_type_id': milkTypeId,
                    'container_type_id': containerTypeId,
                    'rate': rate,
                  },
                );
            ref.invalidate(ownerProductsProvider);
            if (mounted) {
              Navigator.of(context).pop();
              AppSnackBar.show(context, AppStrings.settingsProductUpdated);
            }
          } on ApiException catch (e) {
            if (mounted) {
              AppSnackBar.show(context, e.message);
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(OwnerProduct product) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: AppStrings.settingsProductRemoveTitle,
      message: '"${product.name}" will be removed from your catalog.',
      confirmLabel: AppStrings.settingsProductRemoveConfirm,
      cancelLabel: AppStrings.cancelLabel,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(ownerRepositoryProvider).deleteOwnerProduct(product.id);
      ref.invalidate(ownerProductsProvider);
      if (mounted) {
        AppSnackBar.show(context, AppStrings.settingsProductRemoved);
      }
    } on ApiException catch (e) {
      if (mounted) {
        AppSnackBar.show(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final productsAsync = ref.watch(ownerProductsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OwnerSettingsSectionLabel(
          label: AppStrings.settingsProductsSection,
          icon: LucideIcons.milk,
          trailing: Material(
            color: CustomerDetailColors.accentLight,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _openAddSheet,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CustomerDetailColors.accentBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 14, color: CustomerDetailColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      AppStrings.settingsAddProduct,
                      style: AppText.meta.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: CustomerDetailColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        productsAsync.when(
          loading: () => const OwnerSettingsCard(
            child: Center(child: CircularProgressIndicator(color: CustomerDetailColors.accent)),
          ),
          error: (_, __) => OwnerSettingsCard(
            child: Center(
              child: TextButton(
                onPressed: () => ref.invalidate(ownerProductsProvider),
                child: const Text('Retry'),
              ),
            ),
          ),
          data: (products) => OwnerSettingsCard(
            padding: EdgeInsets.zero,
            child: products.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(
                      AppStrings.settingsProductEmpty,
                      style: AppText.body.copyWith(color: inkMuted),
                    ),
                  )
                : Column(
                    children: [
                      for (int i = 0; i < products.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: milkTypeDotColor(products[i].milkType.name),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      products[i].titleLine,
                                      style: AppText.body.copyWith(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: CustomerDetailColors.onSurface,
                                      ),
                                    ),
                                    Text(
                                      products[i].subtitleLine,
                                      style: AppText.meta.copyWith(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: CustomerDetailColors.iconMuted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              OwnerIconActionButton(
                                icon: LucideIcons.pencil,
                                size: 30,
                                onTap: () => _openEditSheet(products[i]),
                              ),
                              const SizedBox(width: 6),
                              OwnerIconActionButton(
                                icon: LucideIcons.trash2,
                                size: 30,
                                background: CustomerDetailColors.deleteBg,
                                border: CustomerDetailColors.deleteBorder,
                                iconColor: CustomerDetailColors.danger,
                                onTap: () => _confirmDelete(products[i]),
                              ),
                            ],
                          ),
                        ),
                        if (i < products.length - 1)
                          Divider(height: 1, color: CustomerDetailColors.divider),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OR-08: Add product bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddProductSheet extends ConsumerStatefulWidget {
  const _AddProductSheet({required this.onSave});
  final Future<void> Function(int milkTypeId, int containerTypeId, double rate)
      onSave;

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  int? _milkTypeId;
  int? _containerTypeId;
  String? _selectedContainerName;
  String? _containerSizesHint;
  final _rateCtrl = TextEditingController();
  String? _milkTypeError;
  String? _containerTypeError;
  String? _rateError;
  bool _saving = false;

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  String? get _selectedMilkTypeName {
    if (_milkTypeId == null) return null;
    final types = ref.read(milkTypesProvider).valueOrNull ?? [];
    for (final t in types) {
      if (t.id == _milkTypeId) return t.name;
    }
    return null;
  }

  bool get _showPreview {
    final rate = double.tryParse(_rateCtrl.text.trim());
    return _milkTypeId != null && rate != null && rate > 0;
  }

  String get _previewName {
    final name = _selectedMilkTypeName ?? '';
    final rate = _rateCtrl.text.trim();
    return '$name - ₹$rate';
  }

  Future<void> _submit() async {
    final rateText = _rateCtrl.text.trim();
    final rate = double.tryParse(rateText);

    String? milkErr;
    String? containerErr;
    String? rateErr;
    if (_milkTypeId == null) milkErr = AppStrings.settingsProductMilkTypeRequired;
    if (_containerTypeId == null)
      containerErr = AppStrings.settingsProductContainerTypeRequired;
    if (rateText.isEmpty || rate == null || rate <= 0)
      rateErr = AppStrings.settingsProductRateRequired;

    if (milkErr != null || containerErr != null || rateErr != null) {
      setState(() {
        _milkTypeError = milkErr;
        _containerTypeError = containerErr;
        _rateError = rateErr;
      });
      return;
    }

    setState(() {
      _milkTypeError = null;
      _containerTypeError = null;
      _rateError = null;
      _saving = true;
    });
    try {
      await widget.onSave(_milkTypeId!, _containerTypeId!, rate!);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final milkTypesAsync = ref.watch(milkTypesProvider);
    final containerTypesAsync = ref.watch(ownerContainerTypesProvider);

    if (milkTypesAsync.isLoading || containerTypesAsync.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final milkTypes = milkTypesAsync.valueOrNull
            ?.where((t) => t.isActive && !t.isHidden)
            .toList() ??
        [];
    final containerTypes = containerTypesAsync.valueOrNull ?? [];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerSheetTitle(AppStrings.settingsProductAddTitle),
          const SizedBox(height: AppSpace.md),
          // Milk type dropdown
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: _milkTypeId,
            decoration: _fieldDecoration(
              AppStrings.settingsProductMilkTypeLabel,
              hint: AppStrings.settingsProductMilkTypeHint,
            ).copyWith(errorText: _milkTypeError),
            items: milkTypes
                .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: _saving
                ? null
                : (v) => setState(() {
                      _milkTypeId = v;
                      _milkTypeError = null;
                    }),
          ),
          const SizedBox(height: AppSpace.sm),
          // Container type dropdown
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: _containerTypeId,
            decoration: _fieldDecoration(
              AppStrings.settingsProductContainerTypeLabel,
              hint: AppStrings.settingsProductContainerTypeHint,
            ).copyWith(errorText: _containerTypeError),
            items: containerTypes
                .map(
                  (ct) => DropdownMenuItem(
                    value: ct.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ct.name, style: AppText.body),
                        if (ct.sizeLabels.isNotEmpty)
                          Text(
                            'Available in ${ct.sizeLabels.join(', ')}',
                            style: AppText.meta.copyWith(color: inkMuted),
                          ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (v) {
                    final matches =
                        containerTypes.where((c) => c.id == v).toList();
                    final ct = matches.isNotEmpty ? matches.first : null;
                    setState(() {
                      _containerTypeId = v;
                      _selectedContainerName = ct?.name;
                      _containerSizesHint = (ct != null && ct.sizeLabels.isNotEmpty)
                          ? 'Available in ${ct.sizeLabels.join(', ')}'
                          : null;
                      _containerTypeError = null;
                    });
                  },
          ),
          if (_containerSizesHint != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              _containerSizesHint!,
              style: AppText.meta.copyWith(color: inkMuted),
            ),
          ],
          const SizedBox(height: AppSpace.sm),
          // Rate field
          TextFormField(
            controller: _rateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            enabled: !_saving,
            style: AppText.body,
            decoration: _fieldDecoration(AppStrings.settingsProductRateLabel)
                .copyWith(errorText: _rateError),
            onChanged: (_) => setState(() => _rateError = null),
          ),
          // Product name preview
          if (_showPreview) ...[
            const SizedBox(height: AppSpace.md),
            Container(
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.bg,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.settingsProductPreviewLabel,
                    style: AppText.meta.copyWith(color: inkMuted),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    _previewName,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpace.md),
          OwnerSheetActions(
            primaryLabel: AppStrings.settingsProductSaveButton,
            loading: _saving,
            onPrimary: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit product bottom sheet (pre-populated from existing product)
// ─────────────────────────────────────────────────────────────────────────────

class _EditProductSheet extends ConsumerStatefulWidget {
  const _EditProductSheet({required this.product, required this.onSave});
  final OwnerProduct product;
  final Future<void> Function(int milkTypeId, int containerTypeId, double rate) onSave;

  @override
  ConsumerState<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends ConsumerState<_EditProductSheet> {
  late int? _milkTypeId;
  late int? _containerTypeId;
  final _rateCtrl = TextEditingController();
  String? _milkTypeError;
  String? _containerTypeError;
  String? _rateError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _milkTypeId = widget.product.milkType.id;
    _containerTypeId = widget.product.containerType.id;
    _rateCtrl.text = widget.product.rate.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final rateText = _rateCtrl.text.trim();
    final rate = double.tryParse(rateText);

    String? milkErr;
    String? containerErr;
    String? rateErr;
    if (_milkTypeId == null) milkErr = AppStrings.settingsProductMilkTypeRequired;
    if (_containerTypeId == null)
      containerErr = AppStrings.settingsProductContainerTypeRequired;
    if (rateText.isEmpty || rate == null || rate <= 0)
      rateErr = AppStrings.settingsProductRateRequired;

    if (milkErr != null || containerErr != null || rateErr != null) {
      setState(() {
        _milkTypeError = milkErr;
        _containerTypeError = containerErr;
        _rateError = rateErr;
      });
      return;
    }

    setState(() {
      _milkTypeError = null;
      _containerTypeError = null;
      _rateError = null;
      _saving = true;
    });
    try {
      await widget.onSave(_milkTypeId!, _containerTypeId!, rate!);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final milkTypesAsync = ref.watch(milkTypesProvider);
    final containerTypesAsync = ref.watch(ownerContainerTypesProvider);

    if (milkTypesAsync.isLoading || containerTypesAsync.isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final milkTypes = milkTypesAsync.valueOrNull
            ?.where((t) => t.isActive && !t.isHidden)
            .toList() ??
        [];
    final containerTypes = containerTypesAsync.valueOrNull ?? [];

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerSheetTitle(AppStrings.settingsProductEditTitle),
          const SizedBox(height: AppSpace.md),
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: milkTypes.any((t) => t.id == _milkTypeId) ? _milkTypeId : null,
            decoration: _fieldDecoration(AppStrings.settingsProductMilkTypeLabel)
                .copyWith(errorText: _milkTypeError),
            items: milkTypes
                .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: _saving
                ? null
                : (v) => setState(() {
                      _milkTypeId = v;
                      _milkTypeError = null;
                    }),
          ),
          const SizedBox(height: AppSpace.sm),
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: containerTypes.any((c) => c.id == _containerTypeId) ? _containerTypeId : null,
            decoration: _fieldDecoration(AppStrings.settingsProductContainerTypeLabel)
                .copyWith(errorText: _containerTypeError),
            items: containerTypes
                .map(
                  (ct) => DropdownMenuItem(
                    value: ct.id,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ct.name, style: AppText.body),
                        if (ct.sizeLabels.isNotEmpty)
                          Text(
                            'Available in ${ct.sizeLabels.join(', ')}',
                            style: AppText.meta.copyWith(color: inkMuted),
                          ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (v) => setState(() {
                      _containerTypeId = v;
                      _containerTypeError = null;
                    }),
          ),
          const SizedBox(height: AppSpace.sm),
          TextFormField(
            controller: _rateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            enabled: !_saving,
            style: AppText.body,
            decoration: _fieldDecoration(AppStrings.settingsProductRateLabel)
                .copyWith(errorText: _rateError),
            onChanged: (_) => setState(() => _rateError = null),
          ),
          const SizedBox(height: AppSpace.md),
          OwnerSheetActions(
            primaryLabel: AppStrings.settingsProductSaveButton,
            loading: _saving,
            onPrimary: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _ScheduleTimeRow extends StatelessWidget {
  const _ScheduleTimeRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.timeLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppText.label.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: RedesignTokens.ink,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6EC),
                borderRadius: BorderRadius.circular(RedesignTokens.chipRadius),
                border: Border.all(color: const Color(0xFFDCEBDC)),
              ),
              child: Text(
                timeLabel,
                style: AppText.cardTitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: RedesignTokens.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
