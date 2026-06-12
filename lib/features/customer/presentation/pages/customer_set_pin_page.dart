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

class CustomerSetPinPage extends ConsumerStatefulWidget {
  const CustomerSetPinPage({
    super.key,
    required this.contact,
  });

  final String contact;

  @override
  ConsumerState<CustomerSetPinPage> createState() => _CustomerSetPinPageState();
}

class _CustomerSetPinPageState extends ConsumerState<CustomerSetPinPage> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePin = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  String? _pinError;
  String? _confirmError;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    setState(() {
      _pinError = null;
      _confirmError = null;
    });

    if (pin.isEmpty || pin.length != 4) {
      setState(() => _pinError = 'PIN must be 4 digits');
      return;
    }
    if (confirm != pin) {
      setState(() => _confirmError = 'PINs do not match');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref
          .read(customerAuthRepositoryProvider)
          .setPin(widget.contact, pin);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpace.xxl),
                    Center(
                      child: Icon(
                        Icons.lock_outline,
                        size: 56,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      'Set your PIN',
                      textAlign: TextAlign.center,
                      style: AppText.screenTitle.copyWith(color: ink),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      "Choose a 4-digit PIN — you'll use this to sign in",
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: inkMuted),
                    ),
                    const SizedBox(height: AppSpace.xxl),
                    AppTextField(
                      label: 'New PIN',
                      hint: '4 digits',
                      controller: _pinController,
                      obscureText: _obscurePin,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.pin_outlined,
                      errorText: _pinError,
                      suffixIcon: _obscurePin
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      onSuffixTap: () =>
                          setState(() => _obscurePin = !_obscurePin),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                    const SizedBox(height: AppSpace.md),
                    AppTextField(
                      label: 'Confirm PIN',
                      hint: '4 digits',
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.pin_outlined,
                      errorText: _confirmError,
                      suffixIcon: _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      onSuffixTap: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),
                    AppButton(
                      label: 'Save PIN',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpace.lg),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
