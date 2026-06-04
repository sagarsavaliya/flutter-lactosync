import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'providers/auth_provider.dart';

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
      appBar: AppBar(title: const Text(AppStrings.verifyOtpTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.verifyOtpSubtitle,
                  style: AppText.body.copyWith(color: inkMuted),
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
                  validator: (value) {
                    final otp = value?.trim() ?? '';
                    if (otp.isEmpty) return AppStrings.otpRequired;
                    if (otp.length != 6) return AppStrings.otpInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.lg),
                AppButton(
                  label: AppStrings.verifyOtp,
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
