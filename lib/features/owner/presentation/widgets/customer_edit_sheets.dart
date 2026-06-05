import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_form_layout.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/owner_models.dart';
import '../../domain/entities/settings_models.dart';
import '../providers/owner_provider.dart';
import 'owner_design_system.dart';
import 'owner_form_theme.dart';
import 'owner_shared_widgets.dart';
import '../../../onboarding/presentation/widgets/rate_calculation_card.dart';

class EditCustomerSheet extends ConsumerStatefulWidget {
  const EditCustomerSheet({super.key, required this.customer});

  final CustomerDetailInfo customer;

  static Future<void> show(BuildContext context, CustomerDetailInfo customer) {
    return showOwnerBottomSheet<void>(
      context: context,
      child: EditCustomerSheet(customer: customer),
    );
  }

  @override
  ConsumerState<EditCustomerSheet> createState() => _EditCustomerSheetState();
}

class _EditCustomerSheetState extends ConsumerState<EditCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstController;
  late final TextEditingController _lastController;
  late final TextEditingController _contactController;
  late final TextEditingController _addressController;
  late final TextEditingController _areaController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipController;
  late bool _whatsappEnabled;
  late bool _suspendDelivery;
  bool _loading = false;
  bool _importingContact = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _firstController = TextEditingController(text: c.firstName);
    _lastController = TextEditingController(text: c.lastName);
    _contactController = TextEditingController(text: c.contact);
    _addressController = TextEditingController(text: c.addressLine);
    _areaController = TextEditingController(text: c.area);
    _landmarkController = TextEditingController(text: c.landmark);
    _cityController = TextEditingController(text: c.city);
    _stateController = TextEditingController(text: c.state);
    _zipController = TextEditingController(text: c.zip);
    _whatsappEnabled = c.whatsappEnabled;
    _suspendDelivery = !c.isActive;
  }

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(ownerRepositoryProvider).updateCustomer(
            widget.customer.id,
            CustomerUpdateRequest(
              firstName: _firstController.text.trim(),
              lastName: _lastController.text.trim(),
              contact: _contactController.text.trim(),
              addressLine: _addressController.text.trim(),
              area: _areaController.text.trim(),
              landmark: _landmarkController.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              zip: _zipController.text.trim(),
              whatsappEnabled: _whatsappEnabled,
              isActive: !_suspendDelivery,
            ),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.saveChanges)),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OwnerSheetTitle(AppStrings.editCustomerTitle),
            const SizedBox(height: AppSpace.lg),
            AppLabelRow(
              label: AppStrings.customerInfoTitle,
              trailing: Tooltip(
                message: AppStrings.importFromContacts,
                child: InkWell(
                  onTap: _importingContact ? null : _importContact,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _importingContact
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.contacts_outlined,
                            size: 20,
                            color: Theme.of(context).hintColor,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.firstNameLabel,
                      controller: _firstController,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? AppStrings.firstNameRequired : null,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.lastNameLabel,
                      controller: _lastController,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? AppStrings.lastNameRequired : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              AppLabelRow(
                label: AppStrings.primaryContactLabel,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.whatsappTinyLabel,
                      style: AppText.meta.copyWith(color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(width: AppSpace.xxs),
                    AppCompactSwitch(
                      value: _whatsappEnabled,
                      onChanged: (v) => setState(() => _whatsappEnabled = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              AppTextField(
                controller: _contactController,
                label: AppStrings.primaryContactLabel,
                showLabel: false,
                hint: AppStrings.mobileHint,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) {
                  if (v == null || v.length != 10) return AppStrings.mobileInvalid;
                  return null;
                },
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(
                label: AppStrings.addressLabel,
                controller: _addressController,
                validator: (v) => (v == null || v.trim().isEmpty) ? AppStrings.addressRequired : null,
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(label: AppStrings.areaLabel, controller: _areaController),
              const SizedBox(height: AppSpace.md),
              AppTextField(label: AppStrings.landmarkLabel, controller: _landmarkController),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(child: AppTextField(label: AppStrings.cityLabel, controller: _cityController)),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(child: AppTextField(label: AppStrings.stateLabel, controller: _stateController)),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              AppTextField(
                label: AppStrings.zipLabel,
                controller: _zipController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                validator: (v) => (v == null || v.length != 6) ? AppStrings.zipRequired : null,
              ),
              const SizedBox(height: AppSpace.md),
              AppLabelRow(
                label: AppStrings.suspendDeliveryLabel,
                trailing: AppCompactSwitch(
                  value: _suspendDelivery,
                  onChanged: (v) => setState(() => _suspendDelivery = v),
                ),
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                AppStrings.suspendDeliveryHint,
                style: AppText.meta.copyWith(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: AppSpace.lg),
            OwnerSheetActions(
              primaryLabel: AppStrings.saveChanges,
              loading: _loading,
              onPrimary: _save,
              secondaryLabel: AppStrings.cancelLabel,
              onSecondary: _loading ? null : () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class EditSubscriptionSheet extends ConsumerStatefulWidget {
  const EditSubscriptionSheet({
    super.key,
    required this.subscription,
    required this.line,
    required this.products,
  });

  final CustomerSubscriptionDetail subscription;
  final SubscriptionLineDetail line;
  final List<SettingsProduct> products;

  static Future<void> show(
    BuildContext context, {
    required CustomerSubscriptionDetail subscription,
    required SubscriptionLineDetail line,
    required List<SettingsProduct> products,
  }) {
    return showOwnerBottomSheet<void>(
      context: context,
      child: EditSubscriptionSheet(
        subscription: subscription,
        line: line,
        products: products,
      ),
    );
  }

  @override
  ConsumerState<EditSubscriptionSheet> createState() => _EditSubscriptionSheetState();
}

class _LineEditor {
  _LineEditor({
    required this.lineId,
    required this.productId,
    required this.quantity,
    required this.couponController,
    required this.shift,
  });

  final int lineId;
  int productId;
  double quantity;
  final TextEditingController couponController;
  String shift;

  void dispose() {
    couponController.dispose();
  }
}

class _EditSubscriptionSheetState extends ConsumerState<EditSubscriptionSheet> {
  late final _LineEditor _line;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final line = widget.line;
    _line = _LineEditor(
      lineId: line.id,
      productId: line.productId,
      quantity: nearestMilkQty(line.quantity),
      couponController: TextEditingController(
        text: line.couponAmount > 0 ? line.couponAmount.toStringAsFixed(0) : '',
      ),
      shift: line.shift,
    );
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  SettingsProduct? _productFor(int id) {
    for (final product in widget.products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final line = _line;
      if (line.quantity <= 0) return;

      await ref.read(ownerRepositoryProvider).updateSubscriptionLine(
            widget.subscription.id,
            line.lineId,
            SubscriptionLineUpdateRequest(
              productId: line.productId,
              quantity: line.quantity,
              shift: line.shift,
              couponAmount: double.tryParse(line.couponController.text.trim()) ?? 0,
            ),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.saveChanges)),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _alignedFieldDecoration(BuildContext context, String label) {
    final border = OwnerFormTheme.outlineBorder();
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OwnerFormTheme.outlineBorder(OwnerFormTheme.accentColor, 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final line = _line;
    final product = _productFor(line.productId);
    final coupon = double.tryParse(line.couponController.text.trim()) ?? 0;
    final qty = line.quantity;
    final fieldDecoration = _alignedFieldDecoration;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerSheetTitle(AppStrings.editSubscriptionTitle),
          const SizedBox(height: AppSpace.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  value: widget.products.any((p) => p.id == line.productId)
                      ? line.productId
                      : widget.products.firstOrNull?.id,
                  isExpanded: true,
                  decoration: fieldDecoration(context, AppStrings.selectProduct),
                  items: widget.products
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} · ₹${p.rate.toStringAsFixed(0)}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    if (v != null) line.productId = v;
                  }),
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        value: kMilkQtyOptions.contains(qty) ? qty : nearestMilkQty(qty),
                        isExpanded: true,
                        decoration: fieldDecoration(context, AppStrings.quantityLabel),
                        items: kMilkQtyOptions
                            .map(
                              (option) => DropdownMenuItem(
                                value: option,
                                child: Text(milkQtyLabel(option)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          if (v != null) line.quantity = v;
                        }),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: TextFormField(
                        controller: line.couponController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: fieldDecoration(context, AppStrings.couponLabel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'morning', label: Text(AppStrings.morningShift)),
                    ButtonSegment(value: 'evening', label: Text(AppStrings.eveningShift)),
                  ],
                  selected: {line.shift},
                  onSelectionChanged: (s) => setState(() => line.shift = s.first),
                ),
                if (product != null) ...[
                  const SizedBox(height: AppSpace.md),
                  RateCalculationCard(
                    productName: product.name,
                    unitRate: product.rate,
                    couponAmount: coupon,
                    quantity: qty,
                    unit: product.unit,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          OwnerSheetActions(
            primaryLabel: AppStrings.saveChanges,
            loading: _loading,
            onPrimary: _save,
            secondaryLabel: AppStrings.cancelLabel,
            onSecondary: _loading ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class CreateSubscriptionSheet extends ConsumerStatefulWidget {
  const CreateSubscriptionSheet({
    super.key,
    required this.customerId,
    required this.products,
  });

  final int customerId;
  final List<SettingsProduct> products;

  static Future<void> show(
    BuildContext context, {
    required int customerId,
    required List<SettingsProduct> products,
  }) {
    return showOwnerBottomSheet<void>(
      context: context,
      child: CreateSubscriptionSheet(customerId: customerId, products: products),
    );
  }

  @override
  ConsumerState<CreateSubscriptionSheet> createState() => _CreateSubscriptionSheetState();
}

class _CreateSubscriptionSheetState extends ConsumerState<CreateSubscriptionSheet> {
  int? _productId;
  double _quantity = 1;
  String _shift = 'morning';
  final _couponController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.products.isNotEmpty) {
      _productId = widget.products.first.id;
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  SettingsProduct? get _product {
    for (final p in widget.products) {
      if (p.id == _productId) return p;
    }
    return null;
  }

  Future<void> _save() async {
    if (_productId == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(ownerRepositoryProvider).createSubscription(
            CreateSubscriptionRequest(
              customerId: widget.customerId,
              lines: [
                SubscriptionLineUpdateRequest(
                  productId: _productId!,
                  quantity: _quantity,
                  shift: _shift,
                  couponAmount: double.tryParse(_couponController.text.trim()) ?? 0,
                ),
              ],
            ),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.createSubscriptionBtn)),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    final border = OwnerFormTheme.outlineBorder();
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OwnerFormTheme.outlineBorder(OwnerFormTheme.accentColor, 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final coupon = double.tryParse(_couponController.text.trim()) ?? 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerSheetTitle(AppStrings.addSubscriptionTitle),
          const SizedBox(height: AppSpace.lg),
          if (widget.products.isEmpty)
            Text(AppStrings.productsEmptyHint, style: AppText.body)
          else ...[
            DropdownButtonFormField<int>(
              value: _productId,
              isExpanded: true,
              decoration: _fieldDecoration(context, AppStrings.selectProduct),
              items: widget.products
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.name} · ₹${p.rate.toStringAsFixed(0)}'),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _productId = v),
            ),
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<double>(
                    value: kMilkQtyOptions.contains(_quantity) ? _quantity : nearestMilkQty(_quantity),
                    isExpanded: true,
                    decoration: _fieldDecoration(context, AppStrings.quantityLabel),
                    items: kMilkQtyOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(milkQtyLabel(option)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      if (v != null) _quantity = v;
                    }),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: TextFormField(
                    controller: _couponController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: _fieldDecoration(context, AppStrings.couponLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'morning', label: Text(AppStrings.morningShift)),
                ButtonSegment(value: 'evening', label: Text(AppStrings.eveningShift)),
              ],
              selected: {_shift},
              onSelectionChanged: (s) => setState(() => _shift = s.first),
            ),
            if (product != null) ...[
              const SizedBox(height: AppSpace.md),
              RateCalculationCard(
                productName: product.name,
                unitRate: product.rate,
                couponAmount: coupon,
                quantity: _quantity,
                unit: product.unit,
              ),
            ],
          ],
          const SizedBox(height: AppSpace.lg),
          OwnerSheetActions(
            primaryLabel: AppStrings.createSubscriptionBtn,
            loading: _loading,
            onPrimary: widget.products.isEmpty || _loading ? null : _save,
            secondaryLabel: AppStrings.cancelLabel,
            onSecondary: _loading ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class UpdateOrderLogSheet extends ConsumerStatefulWidget {
  const UpdateOrderLogSheet({
    super.key,
    required this.customerId,
    required this.billingMonth,
    required this.lineId,
    required this.productName,
  });

  final int customerId;
  final String billingMonth;
  final int lineId;
  final String productName;

  static Future<void> show(
    BuildContext context, {
    required int customerId,
    required String billingMonth,
    required int lineId,
    required String productName,
  }) {
    return showOwnerBottomSheet<void>(
      context: context,
      child: UpdateOrderLogSheet(
        customerId: customerId,
        billingMonth: billingMonth,
        lineId: lineId,
        productName: productName,
      ),
    );
  }

  @override
  ConsumerState<UpdateOrderLogSheet> createState() => _UpdateOrderLogSheetState();
}

class _UpdateOrderLogSheetState extends ConsumerState<UpdateOrderLogSheet> {
  List<SubscriptionDayOrder> _rows = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await ref.read(ownerRepositoryProvider).fetchDeliveryLogGrid(
            customerId: widget.customerId,
            billingMonth: widget.billingMonth,
            subscriptionLineId: widget.lineId,
          );
      if (mounted) setState(() => _rows = rows);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(ownerRepositoryProvider).updateDeliveryLogs(
            customerId: widget.customerId,
            billingMonth: widget.billingMonth,
            subscriptionLineId: widget.lineId,
            entries: _rows
                .map(
                  (row) => DeliveryLogUpdateEntry(
                    date: row.date,
                    morning: row.morning,
                    evening: row.evening,
                  ),
                )
                .toList(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.orderLogUpdated)),
      );
    } on ApiException catch (e) {
      if (mounted) {
        final message = e.code == 'UPDATE_FAILED' && e.message.contains('payment')
            ? AppStrings.billRecalcBlocked
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDay(String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    final weekday = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][parsed.weekday - 1];
    return '${parsed.day.toString().padLeft(2, '0')}, $weekday';
  }

  @override
  Widget build(BuildContext context) {
    final inkMuted = Theme.of(context).hintColor;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OwnerSheetTitle(AppStrings.updateOrderLog, subtitle: widget.productName),
          const SizedBox(height: AppSpace.md),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: Row(
                children: [
                  const Expanded(flex: 3, child: SizedBox.shrink()),
                  Expanded(
                    child: Text(
                      AppStrings.orderLogMorning,
                      textAlign: TextAlign.center,
                      style: AppText.label.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      AppStrings.orderLogEvening,
                      textAlign: TextAlign.center,
                      style: AppText.label.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 360,
              child: ListView.builder(
                itemCount: _rows.length,
                itemBuilder: (context, index) {
                  final row = _rows[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.xs),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            _formatDay(row.date),
                            style: AppText.meta.copyWith(
                              color: row.hasDelivery ? null : inkMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: DropdownButton<double?>(
                            isExpanded: true,
                            value: row.morning,
                            hint: const Text('—'),
                            items: [
                              const DropdownMenuItem<double?>(value: null, child: Text('—')),
                              ...kMilkQtyOptions.map(
                                (q) => DropdownMenuItem(value: q, child: Text(milkQtyLabel(q))),
                              ),
                            ],
                            onChanged: (v) => setState(() {
                              _rows[index] = SubscriptionDayOrder(
                                date: row.date,
                                morning: v,
                                evening: row.evening,
                                hasDelivery: (v ?? 0) > 0 || (row.evening ?? 0) > 0,
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: DropdownButton<double?>(
                            isExpanded: true,
                            value: row.evening,
                            hint: const Text('—'),
                            items: [
                              const DropdownMenuItem<double?>(value: null, child: Text('—')),
                              ...kMilkQtyOptions.map(
                                (q) => DropdownMenuItem(value: q, child: Text(milkQtyLabel(q))),
                              ),
                            ],
                            onChanged: (v) => setState(() {
                              _rows[index] = SubscriptionDayOrder(
                                date: row.date,
                                morning: row.morning,
                                evening: v,
                                hasDelivery: (row.morning ?? 0) > 0 || (v ?? 0) > 0,
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          OwnerSheetActions(
            primaryLabel: AppStrings.saveChanges,
            loading: _saving,
            onPrimary: _loading || _saving ? null : _save,
            secondaryLabel: AppStrings.cancelLabel,
            onSecondary: _saving ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
