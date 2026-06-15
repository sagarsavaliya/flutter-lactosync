import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../../core/theme/redesign_tokens.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/customer_form_sections.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class AddCustomerPage extends ConsumerStatefulWidget {
  const AddCustomerPage({super.key, this.returnToFork = true});

  final bool returnToFork;

  @override
  ConsumerState<AddCustomerPage> createState() => _AddCustomerPageState();
}

class _AddCustomerPageState extends ConsumerState<AddCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstController = TextEditingController();
  final _lastController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _contactController = TextEditingController();
  final _secondaryController = TextEditingController();

  String _deliveryType = 'home_delivery';
  String? _selectedState;
  bool _whatsappEnabled = true;
  bool _isActive = true;
  bool _loading = false;
  bool _importingContact = false;

  bool get _isWalkIn => _deliveryType == 'walk_in';

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _contactController.dispose();
    _secondaryController.dispose();
    super.dispose();
  }

  Future<void> _importContact() async {
    setState(() => _importingContact = true);
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.contactsPermissionDenied)),
        );
        return;
      }
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;
      final full = await FlutterContacts.getContact(contact.id, withProperties: true);
      if (full == null) return;
      _firstController.text = full.name.first.trim();
      _lastController.text = full.name.last.trim();
      if (full.phones.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.contactNoPhone)),
        );
        return;
      }
      final phone = full.phones.first;
      final raw = (phone.normalizedNumber.isNotEmpty ? phone.normalizedNumber : phone.number)
          .replaceAll(RegExp(r'[^\d]'), '');
      final last10 = raw.length >= 10 ? raw.substring(raw.length - 10) : raw;
      _contactController.text = last10;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.contactImportError)),
      );
    } finally {
      if (mounted) setState(() => _importingContact = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(onboardingRepositoryProvider).saveCustomer({
        'first_name': _firstController.text.trim(),
        'last_name': _lastController.text.trim(),
        'delivery_type': _deliveryType,
        if (!_isWalkIn) 'address_line': _addressController.text.trim(),
        'area': _areaController.text.trim().isEmpty ? null : _areaController.text.trim(),
        'landmark':
            _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
        if (!_isWalkIn) 'city': _cityController.text.trim(),
        if (!_isWalkIn) 'state': _selectedState ?? '',
        if (!_isWalkIn) 'zip': _zipController.text.trim(),
        'contact': _contactController.text.trim(),
        'whatsapp_enabled': _whatsappEnabled,
        'secondary_contact': _secondaryController.text.trim().isEmpty
            ? null
            : _secondaryController.text.trim(),
        'is_active': _isActive,
      });
      ref.invalidate(authSessionProvider);
      if (!mounted) return;
      if (widget.returnToFork) {
        context.go('/onboarding/customer-saved');
      } else {
        context.go('/onboarding/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapDioError(e).message)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget get _whatsappToggle => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.messageCircle, size: 13, color: Color(0xFF2E6E45)),
          const SizedBox(width: 4),
          Text(
            'WhatsApp',
            style: AppText.meta.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E6E45),
            ),
          ),
          Transform.scale(
            scale: 0.72,
            child: Switch(
              value: _whatsappEnabled,
              onChanged: (v) => setState(() => _whatsappEnabled = v),
              activeTrackColor: const Color(0xFF2E6E45),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return RedesignFormScaffold(
      title: AppStrings.customerTitle,
      bottom: AppButton(label: 'Save & add subscription', loading: _loading, onPressed: _submit),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomerFormSectionHeader(
              icon: LucideIcons.user,
              title: 'Customer details',
              trailing: CustomerFormImportChip(loading: _importingContact, onTap: _importContact),
            ),
            RedesignSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'FIRST NAME',
                      controller: _firstController,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? AppStrings.firstNameRequired : null,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: AppTextField(
                      label: 'LAST NAME',
                      controller: _lastController,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? AppStrings.lastNameRequired : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('DELIVERY TYPE', style: RedesignTokens.fieldLabel(context)),
            const SizedBox(height: 8),
            RedesignSurfaceCard(
              padding: const EdgeInsets.all(5),
              radius: 15,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'home_delivery',
                    label: Text('Home delivery'),
                    icon: Icon(Icons.local_shipping_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: 'walk_in',
                    label: Text('Walk-in'),
                    icon: Icon(Icons.storefront_outlined, size: 18),
                  ),
                ],
                selected: {_deliveryType},
                onSelectionChanged: (s) => setState(() => _deliveryType = s.first),
              ),
            ),
            if (!_isWalkIn) ...[
              const SizedBox(height: RedesignTokens.sectionGap),
              const CustomerFormSectionHeader(icon: LucideIcons.mapPin, title: 'Delivery address'),
              RedesignSurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    AppTextField(
                      label: 'ADDRESS',
                      controller: _addressController,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? AppStrings.addressRequired : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(label: 'AREA', controller: _areaController),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: AppTextField(label: 'LANDMARK', controller: _landmarkController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 13,
                          child: AppTextField(
                            label: 'CITY',
                            controller: _cityController,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? AppStrings.cityRequired : null,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: AppTextField(
                            label: 'PIN CODE',
                            controller: _zipController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            validator: (v) {
                              if ((v?.trim() ?? '').length != 6) return AppStrings.zipRequired;
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StateDropdown(
                      value: _selectedState,
                      onChanged: (v) => setState(() => _selectedState = v),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? AppStrings.stateRequired : null,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: RedesignTokens.sectionGap),
            const CustomerFormSectionHeader(icon: LucideIcons.phone, title: 'Contact'),
            RedesignSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  AppTextField(
                    label: 'PRIMARY CONTACT',
                    labelTrailing: _whatsappToggle,
                    prefixText: '+91 ',
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (v) {
                      if ((v?.trim() ?? '').length != 10) return AppStrings.contactRequired;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'SECONDARY CONTACT',
                    labelTrailing: Text(
                      'optional',
                      style: AppText.meta.copyWith(
                        color: CustomerDetailColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    prefixText: '+91 ',
                    controller: _secondaryController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: RedesignTokens.sectionGap),
            RedesignSurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.userCheck, size: 18, color: Color(0xFF2E6E45)),
                ),
                title: Text(
                  AppStrings.customerActive,
                  style: AppText.label.copyWith(
                    color: CustomerDetailColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Customer receives deliveries and appears in lists',
                  style: AppText.meta.copyWith(color: CustomerDetailColors.onSurfaceVariant),
                ),
                value: _isActive,
                activeTrackColor: const Color(0xFF2E6E45),
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
        ),
      ),
    );
  }
}

class _StateDropdown extends StatelessWidget {
  const _StateDropdown({
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STATE',
          style: AppText.label.copyWith(color: const Color(0xFF6B727B)),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          hint: const Text('Select state'),
          isExpanded: true,
          items: kIndianStates
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
