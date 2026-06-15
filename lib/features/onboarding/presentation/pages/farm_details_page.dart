import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../../core/constants/app_strings.dart';

import '../../../../core/network/dio_provider.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/widgets/app_button.dart';

import '../../../../core/widgets/app_text_field.dart';

import '../../../../core/widgets/redesign_scaffold.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

import '../providers/onboarding_provider.dart';



class FarmDetailsPage extends ConsumerStatefulWidget {

  const FarmDetailsPage({super.key});



  @override

  ConsumerState<FarmDetailsPage> createState() => _FarmDetailsPageState();

}



class _FarmDetailsPageState extends ConsumerState<FarmDetailsPage> {

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _addressController = TextEditingController();

  final _cityController = TextEditingController();

  final _stateController = TextEditingController();

  final _zipController = TextEditingController();

  bool _loading = false;

  bool _prefilled = false;



  @override

  void dispose() {

    _nameController.dispose();

    _addressController.dispose();

    _cityController.dispose();

    _stateController.dispose();

    _zipController.dispose();

    super.dispose();

  }



  @override

  void initState() {

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _prefill());

  }



  Future<void> _prefill() async {

    if (_prefilled) return;

    _prefilled = true;

    try {

      final status = await ref.read(onboardingRepositoryProvider).fetchStatus();

      if (!mounted) return;

      final farm = status.farm;

      if (farm.name != null && farm.name != 'Setup pending') {

        _nameController.text = farm.name!;

      }

      _addressController.text = farm.addressLine ?? '';

      _cityController.text = farm.city ?? '';

      _stateController.text = farm.state ?? '';

      _zipController.text = farm.zip ?? '';

    } catch (_) {}

  }



  Future<void> _submit() async {

    if (!_formKey.currentState!.validate()) return;



    setState(() => _loading = true);

    try {

      await ref.read(onboardingRepositoryProvider).updateFarm(

            name: _nameController.text.trim(),

            addressLine: _addressController.text.trim(),

            city: _cityController.text.trim(),

            state: _stateController.text.trim(),

            zip: _zipController.text.trim(),

          );

      ref.invalidate(authSessionProvider);

      if (!mounted) return;

      context.go('/onboarding/dashboard');

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

    return RedesignFormScaffold(

      title: AppStrings.farmSetupTitle,

      subtitle: AppStrings.farmSetupSubtitle,

      child: Form(

        key: _formKey,

        child: RedesignSurfaceCard(

          padding: const EdgeInsets.all(AppSpace.lg),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              AppTextField(

                label: AppStrings.farmNameLabel,

                controller: _nameController,

                prefixIcon: Icons.agriculture_outlined,

                validator: (v) =>

                    (v == null || v.trim().isEmpty) ? AppStrings.farmNameRequired : null,

              ),

              const SizedBox(height: AppSpace.md),

              AppTextField(

                label: AppStrings.addressLabel,

                controller: _addressController,

                prefixIcon: Icons.home_outlined,

                validator: (v) =>

                    (v == null || v.trim().isEmpty) ? AppStrings.addressRequired : null,

              ),

              const SizedBox(height: AppSpace.md),

              AppTextField(

                label: AppStrings.cityLabel,

                controller: _cityController,

                validator: (v) =>

                    (v == null || v.trim().isEmpty) ? AppStrings.cityRequired : null,

              ),

              const SizedBox(height: AppSpace.md),

              AppTextField(

                label: AppStrings.stateLabel,

                controller: _stateController,

                validator: (v) =>

                    (v == null || v.trim().isEmpty) ? AppStrings.stateRequired : null,

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

                validator: (v) {

                  final z = v?.trim() ?? '';

                  if (z.length != 6) return AppStrings.zipRequired;

                  return null;

                },

              ),

              const SizedBox(height: AppSpace.lg),

              AppButton(

                label: AppStrings.continueLabel,

                loading: _loading,

                onPressed: _submit,

              ),

            ],

          ),

        ),

      ),

    );

  }

}


