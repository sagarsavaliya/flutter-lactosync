import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../core/constants/app_strings.dart';

import '../../../core/network/dio_provider.dart';

import '../../../core/theme/app_typography.dart';

import '../../../core/theme/redesign_colors.dart';

import '../../../core/widgets/app_button.dart';

import '../../../core/widgets/app_text_field.dart';

import '../../../core/widgets/redesign_scaffold.dart';

import 'providers/auth_provider.dart';
import '../../../core/widgets/app_snackbar.dart';



class VerifyOtpPage extends ConsumerStatefulWidget {

  const VerifyOtpPage({super.key, required this.mobile});



  final String mobile;



  @override

  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();

}



class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage> {

  final _formKey = GlobalKey<FormState>();

  final _otpController = TextEditingController();

  bool _loading = false;



  @override

  void dispose() {

    _otpController.dispose();

    super.dispose();

  }



  Future<void> _submit() async {

    if (!_formKey.currentState!.validate()) return;



    setState(() => _loading = true);

    try {

      final resetToken = await ref.read(authRepositoryProvider).verifyOtp(

            mobile: widget.mobile,

            otp: _otpController.text.trim(),

          );

      if (!mounted) return;

      await context.push('/reset-pin', extra: {

        'mobile': widget.mobile,

        'reset_token': resetToken,

      });

    } catch (e) {

      if (!mounted) return;

      AppSnackBar.show(context, mapDioError(e).message);

    } finally {

      if (mounted) setState(() => _loading = false);

    }

  }



  @override

  Widget build(BuildContext context) {

    return RedesignFormScaffold(

      title: AppStrings.verifyOtpTitle,

      subtitle: AppStrings.verifyOtpSubtitle,

      child: Form(

        key: _formKey,

        child: RedesignSurfaceCard(

          padding: const EdgeInsets.all(20),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              Text(

                widget.mobile,

                style: AppText.label.copyWith(

                  fontWeight: FontWeight.w700,

                  color: CustomerDetailColors.accent,

                ),

              ),

              const SizedBox(height: 16),

              AppTextField(

                label: AppStrings.otpLabel,

                hint: AppStrings.otpHint,

                controller: _otpController,

                keyboardType: TextInputType.number,

                prefixIcon: Icons.sms_outlined,

                inputFormatters: [

                  FilteringTextInputFormatter.digitsOnly,

                  LengthLimitingTextInputFormatter(6),

                ],

                validator: (value) {

                  final otp = value?.trim() ?? '';

                  if (otp.isEmpty) return AppStrings.otpRequired;

                  if (otp.length != 6) return AppStrings.otpInvalid;

                  return null;

                },

              ),

              const SizedBox(height: 20),

              AppButton(

                label: AppStrings.verifyOtp,

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


