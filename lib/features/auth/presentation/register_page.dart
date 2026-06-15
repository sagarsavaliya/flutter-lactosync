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
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/redesign_scaffold.dart';
import 'providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _ownerController = TextEditingController();
  final _farmController = TextEditingController();
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ownerController.dispose();
    _farmController.dispose();
    _mobileController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).register(
            ownerName: _ownerController.text.trim(),
            farmName: _farmController.text.trim(),
            mobile: _mobileController.text.trim(),
            pin: _pinController.text.trim(),
          );
      ref.invalidate(authSessionProvider);
      if (!mounted) return;
      context.go('/home');
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
      title: AppStrings.registerTitle,
      bottom: AppButton(label: AppStrings.createAccount, loading: _loading, onPressed: _submit),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.registerSubtitle,
              style: AppText.body.copyWith(color: CustomerDetailColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpace.lg),
            AppTextField(
              label: AppStrings.ownerNameLabel,
              controller: _ownerController,
              prefixIcon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppStrings.ownerNameRequired : null,
            ),
            const SizedBox(height: AppSpace.md),
            AppTextField(
              label: AppStrings.farmNameLabel,
              controller: _farmController,
              prefixIcon: Icons.agriculture_outlined,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? AppStrings.farmNameRequired : null,
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
            const SizedBox(height: AppSpace.md),
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
              validator: (v) {
                final p = v?.trim() ?? '';
                if (p.length != 4) return AppStrings.pinInvalid;
                return null;
              },
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
              validator: (v) =>
                  v?.trim() != _pinController.text.trim() ? AppStrings.pinMismatch : null,
            ),
            const SizedBox(height: AppSpace.sm),
            Center(
              child: TextButton(
                onPressed: () => context.go('/sign-in'),
                child: Text(
                  AppStrings.alreadyHaveAccount,
                  style: AppText.label.copyWith(color: CustomerDetailColors.accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
