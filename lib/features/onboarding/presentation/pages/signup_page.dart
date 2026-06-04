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
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstController = TextEditingController();
  final _lastController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _firstController.dispose();
    _lastController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).signupSendOtp(
            firstName: _firstController.text.trim(),
            lastName: _lastController.text.trim(),
            mobile: _mobileController.text.trim(),
          );
      if (!mounted) return;
      context.push(
        '/signup/otp',
        extra: {
          'mobile': _mobileController.text.trim(),
          'first_name': _firstController.text.trim(),
          'last_name': _lastController.text.trim(),
        },
      );
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
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.signupTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.signupSubtitle,
                  style: AppText.body.copyWith(color: inkMuted),
                ),
                const SizedBox(height: AppSpace.lg),
                AppTextField(
                  label: AppStrings.firstNameLabel,
                  controller: _firstController,
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppStrings.firstNameRequired : null,
                ),
                const SizedBox(height: AppSpace.md),
                AppTextField(
                  label: AppStrings.lastNameLabel,
                  controller: _lastController,
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? AppStrings.lastNameRequired : null,
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
                  validator: (v) {
                    final d = v?.trim() ?? '';
                    if (d.isEmpty) return AppStrings.mobileRequired;
                    if (d.length != 10) return AppStrings.mobileInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.lg),
                AppButton(
                  label: AppStrings.sendOtp,
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpace.sm),
                TextButton(
                  onPressed: () => context.go('/sign-in'),
                  child: Text(
                    AppStrings.alreadyHaveAccount,
                    style: AppText.label.copyWith(color: primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
