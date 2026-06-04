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

class ForgotPinPage extends ConsumerStatefulWidget {
  const ForgotPinPage({super.key});

  @override
  ConsumerState<ForgotPinPage> createState() => _ForgotPinPageState();
}

class _ForgotPinPageState extends ConsumerState<ForgotPinPage> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final mobile = _mobileController.text.trim();
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(mobile: mobile);
      if (!mounted) return;
      await context.push('/verify-otp', extra: mobile);
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
      appBar: AppBar(title: const Text(AppStrings.forgotPinTitle)),
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
                  AppStrings.forgotPinSubtitle,
                  style: AppText.body.copyWith(color: inkMuted),
                ),
                const SizedBox(height: AppSpace.lg),
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
                  validator: (value) {
                    final digits = value?.trim() ?? '';
                    if (digits.isEmpty) return AppStrings.mobileRequired;
                    if (digits.length != 10) return AppStrings.mobileInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.lg),
                AppButton(
                  label: AppStrings.sendOtp,
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
