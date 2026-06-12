import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/customer_auth_provider.dart';

class CustomerLoginPage extends ConsumerStatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  ConsumerState<CustomerLoginPage> createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends ConsumerState<CustomerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();

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
      await ref.read(customerAuthRepositoryProvider).login(
            _mobileController.text.trim(),
            _pinController.text.trim(),
          );
      if (!mounted) return;
      context.go('/customer/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mapDioError(e).message),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToOtp({required String reason}) {
    context.push(
      '/customer/otp',
      extra: {
        'contact': _mobileController.text.trim(),
        'reason': reason,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final ink = isDark ? AppColors.darkInk : AppColors.ink;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpace.xxl),
                      Center(
                        child: Icon(
                          Icons.local_drink_outlined,
                          size: 56,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Text(
                        'Sign in',
                        textAlign: TextAlign.center,
                        style: AppText.screenTitle.copyWith(color: ink),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        'Enter your mobile number and PIN',
                        textAlign: TextAlign.center,
                        style: AppText.body.copyWith(color: inkMuted),
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      AppTextField(
                        label: 'Mobile number',
                        hint: '10-digit number',
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_android_outlined,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        validator: _validateMobile,
                      ),
                      const SizedBox(height: AppSpace.sm),
                      AppTextField(
                        label: 'PIN',
                        hint: '4 digits',
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
                      const SizedBox(height: AppSpace.xs),
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
                          onPressed: () => _goToOtp(reason: 'forgot'),
                          child: Text(
                            'Forgot PIN?',
                            style: AppText.label.copyWith(color: primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      AppButton(
                        label: 'Sign in',
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Center(
                        child: TextButton(
                          onPressed: () => _goToOtp(reason: 'first_time'),
                          child: Text(
                            'New here? Send OTP first',
                            style: AppText.label.copyWith(color: primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String? _validateMobile(String? value) {
    final digits = value?.trim() ?? '';
    if (digits.isEmpty) return 'Enter mobile number';
    if (digits.length != 10) return 'Enter valid 10-digit number';
    return null;
  }

  String? _validatePin(String? value) {
    final pin = value?.trim() ?? '';
    if (pin.isEmpty) return 'Enter PIN';
    if (pin.length != 4) return 'PIN must be 4 digits';
    return null;
  }
}
