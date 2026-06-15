import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../core/constants/app_strings.dart';

import '../../../core/network/dio_provider.dart';

import '../../../core/theme/app_spacing.dart';

import '../../../core/theme/app_typography.dart';

import '../../../core/theme/redesign_colors.dart';

import '../../../core/widgets/app_button.dart';

import '../../../core/widgets/app_logo.dart';

import '../../../core/widgets/app_text_field.dart';

import '../../../core/widgets/redesign_scaffold.dart';

import 'providers/auth_provider.dart';
import '../../../core/widgets/app_snackbar.dart';



enum _SignInRole { farmOwner, customer }



class SignInPage extends ConsumerStatefulWidget {

  const SignInPage({super.key});



  @override

  ConsumerState<SignInPage> createState() => _SignInPageState();

}



class _SignInPageState extends ConsumerState<SignInPage> {

  final _formKey = GlobalKey<FormState>();

  final _mobileController = TextEditingController();

  final _pinController = TextEditingController();

  _SignInRole _role = _SignInRole.farmOwner;

  bool _obscurePin = true;

  bool _loading = false;



  @override

  void dispose() {

    _mobileController.dispose();

    _pinController.dispose();

    super.dispose();

  }



  Future<void> _submit() async {

    if (!_formKey.currentState!.validate()) return;



    setState(() => _loading = true);

    try {

      await ref.read(authRepositoryProvider).login(

            mobile: _mobileController.text.trim(),

            pin: _pinController.text.trim(),

          );

      final session = await ref.read(authRepositoryProvider).readStoredSession();

      ref.invalidate(authSessionProvider);

      if (!mounted) return;

      context.go(session?.onboardingRoute ?? '/dashboard');

    } catch (e) {

      if (!mounted) return;

      final message = mapDioError(e).message;

      AppSnackBar.show(context, message);

    } finally {

      if (mounted) setState(() => _loading = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    return RedesignFormScaffold(
      scrollable: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

                  const SizedBox(height: AppSpace.xxl),

                  const Center(child: AppLogo(size: 48)),

                  const SizedBox(height: AppSpace.lg),

                  Text(

                    AppStrings.signInTitle,

                    textAlign: TextAlign.center,

                    style: AppText.screenTitle.copyWith(

                      fontSize: 22,

                      color: CustomerDetailColors.onSurface,

                    ),

                  ),

                  const SizedBox(height: AppSpace.xs),

                  Text(

                    AppStrings.signInSubtitle,

                    textAlign: TextAlign.center,

                    style: AppText.body.copyWith(

                      color: CustomerDetailColors.onSurfaceVariant,

                    ),

                  ),

                  const SizedBox(height: AppSpace.lg),

                  RedesignSurfaceCard(

                    padding: const EdgeInsets.all(AppSpace.lg),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [

                        SegmentedButton<_SignInRole>(

                          segments: const [

                            ButtonSegment(

                              value: _SignInRole.farmOwner,

                              label: Text(AppStrings.roleFarmOwner),

                            ),

                            ButtonSegment(

                              value: _SignInRole.customer,

                              label: Text(AppStrings.roleCustomer),

                            ),

                          ],

                          selected: {_role},

                          onSelectionChanged: (s) {

                            if (s.first == _SignInRole.customer) {

                              context.push('/customer/login');

                              return;

                            }

                            setState(() => _role = s.first);

                          },

                        ),

                        const SizedBox(height: AppSpace.lg),

                        Text(

                          AppStrings.signInOwnerHint,

                          textAlign: TextAlign.center,

                          style: AppText.meta.copyWith(

                            color: CustomerDetailColors.onSurfaceVariant,

                          ),

                        ),

                        const SizedBox(height: AppSpace.md),

                        AppTextField(

                          label: AppStrings.mobileLabel,

                          hint: AppStrings.mobileHint,

                          controller: _mobileController,

                          keyboardType: TextInputType.phone,

                          prefixIcon: Icons.phone_android_outlined,

                          inputFormatters: [

                            FilteringTextInputFormatter.digitsOnly,

                            LengthLimitingTextInputFormatter(10),

                          ],

                          validator: _validateMobile,

                        ),

                        const SizedBox(height: AppSpace.md),

                        AppTextField(

                          label: AppStrings.pinLabel,

                          hint: AppStrings.pinHint,

                          controller: _pinController,

                          obscureText: _obscurePin,

                          keyboardType: TextInputType.number,

                          prefixIcon: Icons.lock_outline,

                          suffixIcon: _obscurePin

                              ? Icons.visibility_outlined

                              : Icons.visibility_off_outlined,

                          onSuffixTap: () =>

                              setState(() => _obscurePin = !_obscurePin),

                          inputFormatters: [

                            FilteringTextInputFormatter.digitsOnly,

                            LengthLimitingTextInputFormatter(4),

                          ],

                          validator: _validatePin,

                        ),

                        const SizedBox(height: AppSpace.xxs),

                        Align(

                          alignment: Alignment.centerRight,

                          child: TextButton(

                            style: TextButton.styleFrom(

                              padding: const EdgeInsets.symmetric(

                                horizontal: AppSpace.xs,

                                vertical: AppSpace.xxs,

                              ),

                              minimumSize: Size.zero,

                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,

                            ),

                            onPressed: () => context.push('/forgot-pin'),

                            child: Text(

                              AppStrings.forgotPin,

                              style: AppText.label.copyWith(

                                color: CustomerDetailColors.accent,

                              ),

                            ),

                          ),

                        ),

                        const SizedBox(height: AppSpace.md),

                        AppButton(

                          label: AppStrings.signIn,

                          loading: _loading,

                          onPressed: _submit,

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(height: AppSpace.md),

                  Center(

                    child: TextButton(

                      onPressed: () => context.push('/signup'),

                      child: Text(

                        AppStrings.createAccount,

                        style: AppText.label.copyWith(

                          color: CustomerDetailColors.accent,

                        ),

                      ),

                    ),

                  ),

                  Center(

                    child: TextButton(

                      onPressed: () => context.push('/delivery-boy/login'),

                      child: Text(

                        'Delivery Boy? Login here',

                        style: AppText.label.copyWith(

                          color: CustomerDetailColors.onSurfaceVariant,

                        ),

                      ),

                    ),

                  ),

                  const SizedBox(height: AppSpace.lg),

                ],

              ),

            ),

    );

  }



  String? _validateMobile(String? value) {

    final digits = value?.trim() ?? '';

    if (digits.isEmpty) return AppStrings.mobileRequired;

    if (digits.length != 10) return AppStrings.mobileInvalid;

    return null;

  }



  String? _validatePin(String? value) {

    final pin = value?.trim() ?? '';

    if (pin.isEmpty) return AppStrings.pinRequired;

    if (pin.length != 4 || int.tryParse(pin) == null) return AppStrings.pinInvalid;

    return null;

  }

}


