import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../providers/delivery_boy_auth_provider.dart';

class DeliveryBoyResetPinPage extends ConsumerStatefulWidget {
  const DeliveryBoyResetPinPage({
    super.key,
    required this.phone,
    required this.resetToken,
  });

  final String phone;
  final String resetToken;

  @override
  ConsumerState<DeliveryBoyResetPinPage> createState() =>
      _DeliveryBoyResetPinPageState();
}

class _DeliveryBoyResetPinPageState
    extends ConsumerState<DeliveryBoyResetPinPage> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (pin.length != 4) {
      AppSnackBar.showError(context, 'PIN must be 4 digits');
      return;
    }
    if (pin != confirm) {
      AppSnackBar.showError(context, 'PINs do not match');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(deliveryBoyAuthRepositoryProvider).resetForgotPin(
            phone: widget.phone,
            resetToken: widget.resetToken,
            pin: pin,
          );
      if (!mounted) return;
      context.go('/delivery-boy/home');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, mapDioError(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RedesignFormScaffold(
      title: 'Set new PIN',
      subtitle: 'Choose a new 4-digit PIN for your delivery account.',
      child: RedesignSurfaceCard(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'New PIN',
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
            ),
            const SizedBox(height: AppSpace.md),
            AppTextField(
              label: 'Confirm PIN',
              controller: _confirmCtrl,
              keyboardType: TextInputType.number,
              obscureText: _obscureConfirm,
              prefixIcon: Icons.lock_outline,
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
          ],
        ),
      ),
    );
  }
}
