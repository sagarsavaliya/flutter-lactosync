import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../../../core/constants/app_strings.dart';

import '../../../../core/network/dio_provider.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/theme/app_typography.dart';

import '../../../../core/theme/redesign_colors.dart';

import '../../../../core/widgets/app_button.dart';

import '../../../../core/widgets/app_text_field.dart';

import '../../../../core/widgets/redesign_scaffold.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';



class SignupOtpPage extends ConsumerStatefulWidget {

  const SignupOtpPage({

    super.key,

    required this.mobile,

    required this.firstName,

    required this.lastName,

  });



  final String mobile;

  final String firstName;

  final String lastName;



  @override

  ConsumerState<SignupOtpPage> createState() => _SignupOtpPageState();

}



class _SignupOtpPageState extends ConsumerState<SignupOtpPage> {

  final _otpController = TextEditingController();

  bool _loading = false;



  @override

  void dispose() {

    _otpController.dispose();

    super.dispose();

  }



  Future<void> _verify() async {

    if (_otpController.text.trim().length != 6) {

      AppSnackBar.show(context, AppStrings.otpInvalid);

      return;

    }



    setState(() => _loading = true);

    try {

      final token = await ref.read(authRepositoryProvider).signupVerifyOtp(

            mobile: widget.mobile,

            otp: _otpController.text.trim(),

          );

      if (!mounted) return;

      context.push(

        '/signup/role',

        extra: {'mobile': widget.mobile, 'signup_token': token},

      );

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

      bottom: AppButton(

        label: AppStrings.verifyOtp,

        loading: _loading,

        onPressed: _verify,

      ),

      child: RedesignSurfaceCard(

        padding: const EdgeInsets.all(AppSpace.lg),

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

            const SizedBox(height: AppSpace.lg),

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

            ),

          ],

        ),

      ),

    );

  }

}


