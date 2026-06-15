import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../../core/theme/redesign_tokens.dart';
import '../../../../core/widgets/app_button.dart'; 
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/customer_form_sections.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../../domain/entities/owner_models.dart';
import '../providers/owner_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';

/// Frame 7 — edit customer full-page form (same DNA as add customer).
class EditCustomerPage extends ConsumerStatefulWidget {
  const EditCustomerPage({super.key, required this.customerId});

  final int customerId;

  @override
  ConsumerState<EditCustomerPage> createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends ConsumerState<EditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstController = TextEditingController();
  final _lastController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _areaController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();

  bool _initialized = false;
  String? _selectedState;
  bool _whatsappEnabled = true;
  bool _suspendDelivery = false;
  String _deliveryType = 'home_delivery';
  bool _loading = false;
  bool _importingContact = false;
  bool _prefillApplied = false;

  bool get _isWalkIn => _deliveryType == 'walk_in';

  CustomerDetailQuery get _query => CustomerDetailQuery(
        customerId: widget.customerId,
        billingMonth: DateTime(DateTime.now().year, DateTime.now().month),
      );

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _initFrom(CustomerDetailInfo customer) {
    if (_initialized) return;
    _firstController.text = customer.firstName;
    _lastController.text = customer.lastName;
    _contactController.text = customer.contact;
    _addressController.text = customer.addressLine;
    _areaController.text = customer.area;
    _landmarkController.text = customer.landmark;
    _cityController.text = customer.city;
    _selectedState = customer.state.isEmpty ? null : customer.state;
    _zipController.text = customer.zip;
    _whatsappEnabled = customer.whatsappEnabled;
    _suspendDelivery = !customer.isActive;
    _deliveryType = customer.deliveryType;
    _initialized = true;
    _applyFarmAddressPrefillIfNeeded();
  }

  Future<void> _applyFarmAddressPrefillIfNeeded() async {
    if (_prefillApplied) return;
    try {
      final settings = await ref.read(ownerSettingsProvider.future);
      if (!mounted) return;
      setState(() {
        _selectedState = applyFarmAddressPrefill(
          enabled: settings.farm.prefillCustomerAddress,
          farmCity: settings.farm.city,
          farmState: settings.farm.state,
          farmZip: settings.farm.zip,
          cityController: _cityController,
          zipController: _zipController,
          selectedState: _selectedState,
        );
        _prefillApplied = true;
      });
    } catch (_) {}
  }

  Future<void> _importContact() async {
    setState(() => _importingContact = true);
    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!mounted) return;
      if (!granted) {
        AppSnackBar.show(context, AppStrings.contactsPermissionDenied);
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
        AppSnackBar.show(context, AppStrings.contactNoPhone);
        return;
      }
      final phone = full.phones.first;
      final raw = (phone.normalizedNumber.isNotEmpty ? phone.normalizedNumber : phone.number)
          .replaceAll(RegExp(r'[^\d]'), '');
      final last10 = raw.length >= 10 ? raw.substring(raw.length - 10) : raw;
      _contactController.text = last10;
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(context, AppStrings.contactImportError);
    } finally {
      if (mounted) setState(() => _importingContact = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(ownerRepositoryProvider).updateCustomer(
            widget.customerId,
            CustomerUpdateRequest(
              firstName: _firstController.text.trim(),
              lastName: _lastController.text.trim(),
              contact: _contactController.text.trim(),
              addressLine: _isWalkIn ? null : _addressController.text.trim(),
              area: _areaController.text.trim(),
              landmark: _landmarkController.text.trim(),
              city: _isWalkIn ? null : _cityController.text.trim(),
              state: _isWalkIn ? null : (_selectedState ?? ''),
              zip: _isWalkIn ? null : _zipController.text.trim(),
              whatsappEnabled: _whatsappEnabled,
              isActive: !_suspendDelivery,
              deliveryType: _deliveryType,
            ),
          );
      if (!mounted) return;
      ref.invalidate(customerDetailProvider(_query));
      ref.invalidate(customersListProvider);
      AppSnackBar.show(context, AppStrings.saveChanges);
      context.pop();
    } on ApiException catch (e) {
      if (mounted) {
        AppSnackBar.show(context, e.message);
      }
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
    final detailAsync = ref.watch(customerDetailProvider(_query));

    return detailAsync.when(
      loading: () => const Scaffold(
        backgroundColor: RedesignTokens.background,
        body: Center(child: CircularProgressIndicator(color: RedesignTokens.accent)),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: RedesignTokens.background,
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(customerDetailProvider(_query)),
            child: const Text('Retry'),
          ),
        ),
      ),
      data: (data) {
        _initFrom(data.customer);
        return RedesignFormScaffold(
          title: AppStrings.editCustomerTitle,
          bottom: AppButton(label: AppStrings.saveChanges, loading: _loading, onPressed: _save),
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
                          final digits = v?.trim() ?? '';
                          if (digits.length != 10) return 'Enter valid 10-digit number';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: RedesignTokens.sectionGap),
                Text(
                  'DELIVERY TYPE',
                  style: RedesignTokens.fieldLabel(context),
                ),
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
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                RedesignSurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _suspendDelivery
                            ? const Color(0xFFFFF3EE)
                            : const Color(0xFFE8F5EC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _suspendDelivery ? LucideIcons.userX : LucideIcons.userCheck,
                        size: 18,
                        color: _suspendDelivery
                            ? const Color(0xFFD04020)
                            : const Color(0xFF2E6E45),
                      ),
                    ),
                    title: Text(
                      'Suspend deliveries',
                      style: AppText.cardTitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: CustomerDetailColors.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Customer stays in directory but won\'t receive milk',
                      style: AppText.meta.copyWith(color: CustomerDetailColors.onSurfaceVariant),
                    ),
                    value: _suspendDelivery,
                    activeTrackColor: const Color(0xFFD04020),
                    onChanged: (v) => setState(() => _suspendDelivery = v),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
              ],
            ),
          ),
        );
      },
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
