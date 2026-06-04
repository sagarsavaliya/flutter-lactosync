import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../../core/constants/app_strings.dart';

import '../../../../core/network/dio_provider.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/theme/app_typography.dart';

import '../../../../core/widgets/app_button.dart';

import '../../../../core/widgets/app_form_layout.dart';

import '../../../../core/widgets/app_text_field.dart';

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

  final _stateController = TextEditingController();

  final _zipController = TextEditingController();

  final _contactController = TextEditingController();

  final _secondaryController = TextEditingController();

  bool _whatsappEnabled = true;

  bool _isActive = true;

  bool _loading = false;



  @override

  void dispose() {

    _firstController.dispose();

    _lastController.dispose();

    _addressController.dispose();

    _areaController.dispose();

    _landmarkController.dispose();

    _cityController.dispose();

    _stateController.dispose();

    _zipController.dispose();

    _contactController.dispose();

    _secondaryController.dispose();

    super.dispose();

  }



  Future<void> _submit() async {

    if (!_formKey.currentState!.validate()) return;



    setState(() => _loading = true);

    try {

      await ref.read(onboardingRepositoryProvider).saveCustomer({

        'first_name': _firstController.text.trim(),

        'last_name': _lastController.text.trim(),

        'address_line': _addressController.text.trim(),

        'area': _areaController.text.trim().isEmpty ? null : _areaController.text.trim(),

        'landmark':

            _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),

        'city': _cityController.text.trim(),

        'state': _stateController.text.trim(),

        'zip': _zipController.text.trim(),

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



  @override

  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;



    return Scaffold(

      appBar: AppBar(title: const Text(AppStrings.customerTitle)),

      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(AppSpace.lg),

          child: Form(

            key: _formKey,

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                Text(

                  AppStrings.customerSubtitle,

                  style: AppText.body.copyWith(color: inkMuted),

                ),

                const SizedBox(height: AppSpace.lg),

                AppFieldRow(

                  left: AppTextField(

                    label: AppStrings.firstNameLabel,

                    controller: _firstController,

                    validator: (v) =>

                        (v == null || v.trim().isEmpty) ? AppStrings.firstNameRequired : null,

                  ),

                  right: AppTextField(

                    label: AppStrings.lastNameLabel,

                    controller: _lastController,

                    validator: (v) =>

                        (v == null || v.trim().isEmpty) ? AppStrings.lastNameRequired : null,

                  ),

                ),

                const SizedBox(height: AppSpace.md),

                AppTextField(

                  label: AppStrings.addressLabel,

                  controller: _addressController,

                  validator: (v) =>

                      (v == null || v.trim().isEmpty) ? AppStrings.addressRequired : null,

                ),

                const SizedBox(height: AppSpace.md),

                AppFieldRow(

                  left: AppTextField(label: AppStrings.areaLabel, controller: _areaController),

                  right: AppTextField(label: AppStrings.landmarkLabel, controller: _landmarkController),

                ),

                const SizedBox(height: AppSpace.md),

                AppFieldRow(

                  left: AppTextField(

                    label: AppStrings.cityLabel,

                    controller: _cityController,

                    validator: (v) =>

                        (v == null || v.trim().isEmpty) ? AppStrings.cityRequired : null,

                  ),

                  right: AppTextField(

                    label: AppStrings.zipLabel,

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

                const SizedBox(height: AppSpace.md),

                AppTextField(

                  label: AppStrings.stateLabel,

                  controller: _stateController,

                  validator: (v) =>

                      (v == null || v.trim().isEmpty) ? AppStrings.stateRequired : null,

                ),

                const SizedBox(height: AppSpace.md),

                AppLabelRow(

                  label: AppStrings.primaryContactLabel,

                  trailing: Row(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      Text(AppStrings.whatsappTinyLabel, style: AppText.meta.copyWith(color: inkMuted)),

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

                  label: AppStrings.primaryContactLabel,

                  showLabel: false,

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

                const SizedBox(height: AppSpace.md),

                AppTextField(

                  label: AppStrings.secondaryContactLabel,

                  controller: _secondaryController,

                  keyboardType: TextInputType.phone,

                  inputFormatters: [

                    FilteringTextInputFormatter.digitsOnly,

                    LengthLimitingTextInputFormatter(10),

                  ],

                ),

                const SizedBox(height: AppSpace.sm),

                AppLabelRow(

                  label: AppStrings.customerActive,

                  trailing: AppCompactSwitch(

                    value: _isActive,

                    onChanged: (v) => setState(() => _isActive = v),

                  ),

                ),

                const SizedBox(height: AppSpace.lg),

                AppButton(

                  label: AppStrings.saveCustomer,

                  loading: _loading,

                  onPressed: _submit,

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

}


