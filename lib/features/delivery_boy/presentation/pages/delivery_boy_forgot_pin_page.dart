import 'dart:async';

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
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../providers/delivery_boy_auth_provider.dart';

class DeliveryBoyForgotPinPage extends ConsumerStatefulWidget {
  const DeliveryBoyForgotPinPage({super.key, this.initialPhone = ''});

  final String initialPhone;

  @override
  ConsumerState<DeliveryBoyForgotPinPage> createState() =>
      _DeliveryBoyForgotPinPageState();
}

class _DeliveryBoyForgotPinPageState
    extends ConsumerState<DeliveryBoyForgotPinPage> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  String? _phoneError;
  String? _otpError;
  bool _sendLoading = false;
  bool _verifyLoading = false;
  bool _otpSent = false;
  String _sentToPhone = '';

  static const _resendSeconds = 30;
  int _countdown = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = widget.initialPhone;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String _formatCountdown(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      setState(() => _phoneError = 'Enter a valid 10-digit phone number');
      return;
    }
    setState(() {
      _phoneError = null;
      _sendLoading = true;
    });
    try {
      await ref.read(deliveryBoyAuthRepositoryProvider).sendForgotPinOtp(phone);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _sentToPhone = phone;
      });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, mapDioError(e).message);
    } finally {
      if (mounted) setState(() => _sendLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      setState(() => _otpError = 'Enter OTP');
      return;
    }
    if (otp.length != 6) {
      setState(() => _otpError = 'OTP must be 6 digits');
      return;
    }
    setState(() {
      _otpError = null;
      _verifyLoading = true;
    });
    try {
      final resetToken = await ref
          .read(deliveryBoyAuthRepositoryProvider)
          .verifyForgotPinOtp(_sentToPhone, otp);
      if (!mounted) return;
      await context.push('/delivery-boy/reset-pin', extra: {
        'phone': _sentToPhone,
        'reset_token': resetToken,
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, mapDioError(e).message);
    } finally {
      if (mounted) setState(() => _verifyLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await ref
          .read(deliveryBoyAuthRepositoryProvider)
          .sendForgotPinOtp(_sentToPhone);
      if (!mounted) return;
      _startCountdown();
      AppSnackBar.show(context, 'OTP resent on WhatsApp.');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, mapDioError(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _otpSent ? _buildVerifyStage(context) : _buildSendStage(context);
  }

  Widget _buildSendStage(BuildContext context) {
    return RedesignFormScaffold(
      title: 'Reset PIN',
      subtitle: 'We will send a 6-digit code on WhatsApp to verify you.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RedesignSurfaceCard(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              children: [
                AppTextField(
                  label: 'Phone Number',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  errorText: _phoneError,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                AppButton(
                  label: 'Send OTP',
                  loading: _sendLoading,
                  onPressed: _sendOtp,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Back to sign in',
                style: AppText.label.copyWith(color: CustomerDetailColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyStage(BuildContext context) {
    final canResend = _countdown == 0;

    return RedesignFormScaffold(
      title: 'Enter OTP',
      subtitle: 'Check WhatsApp for the code sent to $_sentToPhone',
      child: RedesignSurfaceCard(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          children: [
            AppTextField(
              label: 'OTP',
              hint: '6 digits',
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.sms_outlined,
              errorText: _otpError,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            AppButton(
              label: 'Verify OTP',
              loading: _verifyLoading,
              onPressed: _verifyOtp,
            ),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Text(
                  canResend
                      ? 'Resend OTP'
                      : 'Resend OTP in ${_formatCountdown(_countdown)}',
                  style: AppText.meta
                      .copyWith(color: CustomerDetailColors.onSurfaceVariant),
                ),
                const Spacer(),
                TextButton(
                  onPressed: canResend ? _resendOtp : null,
                  child: Text(
                    'Resend',
                    style: AppText.label.copyWith(
                      color: canResend
                          ? CustomerDetailColors.accent
                          : CustomerDetailColors.labelMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
