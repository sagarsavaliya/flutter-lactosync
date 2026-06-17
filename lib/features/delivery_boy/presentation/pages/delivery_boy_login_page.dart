import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../providers/delivery_boy_auth_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';

class DeliveryBoyLoginPage extends ConsumerStatefulWidget {
  const DeliveryBoyLoginPage({super.key});

  @override
  ConsumerState<DeliveryBoyLoginPage> createState() =>
      _DeliveryBoyLoginPageState();
}

class _DeliveryBoyLoginPageState extends ConsumerState<DeliveryBoyLoginPage> {
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _obscurePin = true;
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_phoneCtrl.text.trim().isEmpty || _pinCtrl.text.trim().length < 4) {
      return;
    }
    setState(() => _loading = true);
    try {
      await ref
          .read(deliveryBoyAuthRepositoryProvider)
          .login(_phoneCtrl.text.trim(), _pinCtrl.text.trim());
      if (!mounted) return;
      context.go('/delivery-boy/pickup');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, mapDioError(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _phoneCtrl.text.trim().isNotEmpty &&
        _pinCtrl.text.trim().length == 4 &&
        !_loading;

    return RedesignFormScaffold(
      scrollable: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 88,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CustomerDetailColors.accentLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: CustomerDetailColors.accentBorder),
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                size: 44,
                color: CustomerDetailColors.accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            'Delivery Boy Login',
            textAlign: TextAlign.center,
            style: AppText.screenTitle.copyWith(
              fontSize: 24,
              color: CustomerDetailColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Enter your phone number and 4-digit PIN',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: CustomerDetailColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpace.xl),
          RedesignSurfaceCard(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpace.md),
                AppTextField(
                  label: '4-Digit PIN',
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: _obscurePin,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: _obscurePin
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  onSuffixTap: () => setState(() => _obscurePin = !_obscurePin),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpace.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(
                      '/delivery-boy/forgot-pin',
                      extra: _phoneCtrl.text.trim(),
                    ),
                    child: Text(
                      'Forgot PIN?',
                      style: AppText.label
                          .copyWith(color: CustomerDetailColors.accent),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                AppButton(
                  label: 'Login',
                  loading: _loading,
                  onPressed: canSubmit ? _login : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          TextButton(
            onPressed: () => context.go('/sign-in'),
            child: Text(
              'Not a delivery boy? Owner login →',
              style: AppText.label.copyWith(color: CustomerDetailColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
