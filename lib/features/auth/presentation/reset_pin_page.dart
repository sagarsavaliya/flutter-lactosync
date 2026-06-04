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

class ResetPinPage extends ConsumerStatefulWidget {
  const ResetPinPage({
    super.key,
    required this.mobile,
    required this.resetToken,
  });

  final String mobile;
  final String resetToken;

  @override
  ConsumerState<ResetPinPage> createState() => _ResetPinPageState();
}

class _ResetPinPageState extends ConsumerState<ResetPinPage> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePin = true;
  bool _loading = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPin(
            mobile: widget.mobile,
            resetToken: widget.resetToken,
            pin: _pinController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.pinResetSuccess)),
      );
      context.go('/sign-in');
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
      appBar: AppBar(title: const Text(AppStrings.resetPinTitle)),
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
                  AppStrings.resetPinSubtitle,
                  style: AppText.body.copyWith(color: inkMuted),
                ),
                const SizedBox(height: AppSpace.lg),
                AppTextField(
                  label: AppStrings.newPinLabel,
                  hint: AppStrings.pinHint,
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.lock_outline,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    final pin = value?.trim() ?? '';
                    if (pin.isEmpty) return AppStrings.pinRequired;
                    if (pin.length != 4) return AppStrings.pinInvalid;
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.md),
                AppTextField(
                  label: AppStrings.confirmPinLabel,
                  hint: AppStrings.pinHint,
                  controller: _confirmController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: _obscurePin
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixTap: () => setState(() => _obscurePin = !_obscurePin),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value?.trim() != _pinController.text.trim()) {
                      return AppStrings.pinMismatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpace.lg),
                AppButton(
                  label: AppStrings.saveNewPin,
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
