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



class SetPinPage extends ConsumerStatefulWidget {

  const SetPinPage({

    super.key,

    required this.mobile,

    required this.signupToken,

  });



  final String mobile;

  final String signupToken;



  @override

  ConsumerState<SetPinPage> createState() => _SetPinPageState();

}



class _SetPinPageState extends ConsumerState<SetPinPage> {

  final _pinController = TextEditingController();

  final _confirmController = TextEditingController();

  bool _loading = false;



  @override

  void dispose() {

    _pinController.dispose();

    _confirmController.dispose();

    super.dispose();

  }



  Future<void> _submit() async {

    final pin = _pinController.text.trim();

    if (pin.length != 4) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text(AppStrings.pinInvalid)),

      );

      return;

    }

    if (pin != _confirmController.text.trim()) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text(AppStrings.pinMismatch)),

      );

      return;

    }



    setState(() => _loading = true);

    try {

      final session = await ref.read(authRepositoryProvider).signupComplete(

            signupToken: widget.signupToken,

            pin: pin,

          );

      ref.invalidate(authSessionProvider);

      if (!mounted) return;

      context.go(session.onboardingRoute);

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

      title: AppStrings.setPinTitle,

      subtitle: AppStrings.setPinSubtitle,

      child: RedesignSurfaceCard(

        padding: const EdgeInsets.all(AppSpace.lg),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            AppTextField(

              label: AppStrings.pinLabel,

              hint: AppStrings.pinHint,

              controller: _pinController,

              obscureText: true,

              keyboardType: TextInputType.number,

              prefixIcon: Icons.lock_outline,

              inputFormatters: [

                FilteringTextInputFormatter.digitsOnly,

                LengthLimitingTextInputFormatter(4),

              ],

            ),

            const SizedBox(height: AppSpace.md),

            AppTextField(

              label: AppStrings.confirmPinLabel,

              controller: _confirmController,

              obscureText: true,

              keyboardType: TextInputType.number,

              prefixIcon: Icons.lock_outline,

              inputFormatters: [

                FilteringTextInputFormatter.digitsOnly,

                LengthLimitingTextInputFormatter(4),

              ],

            ),

            const SizedBox(height: AppSpace.lg),

            AppButton(

              label: AppStrings.savePin,

              loading: _loading,

              onPressed: _submit,

            ),

          ],

        ),

      ),

    );

  }

}


