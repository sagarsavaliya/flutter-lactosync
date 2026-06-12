import 'dart:async';

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

/// Two-stage OTP screen:
/// Stage 1 — Enter mobile number → POST send-otp
/// Stage 2 — Enter OTP code → POST verify-otp → navigate to set-pin
class CustomerOtpPage extends ConsumerStatefulWidget {
  const CustomerOtpPage({
    super.key,
    required this.initialContact,
    required this.reason,
  });

  /// Pre-filled mobile number (may be empty if coming from a direct link).
  final String initialContact;

  /// 'first_time' or 'forgot' — used for display copy only.
  final String reason;

  @override
  ConsumerState<CustomerOtpPage> createState() => _CustomerOtpPageState();
}

class _CustomerOtpPageState extends ConsumerState<CustomerOtpPage> {
  // ── Stage 1: Send OTP ────────────────────────────────────────────────────
  final _mobileController = TextEditingController();
  String? _mobileError;
  bool _sendLoading = false;

  // ── Stage 2: Verify OTP ─────────────────────────────────────────────────
  bool _otpSent = false;
  String _sentToContact = '';
  final _otpController = TextEditingController();
  String? _otpError;
  bool _verifyLoading = false;

  // ── Resend countdown ────────────────────────────────────────────────────
  static const _resendSeconds = 30;
  int _countdown = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _mobileController.text = widget.initialContact;
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Countdown helpers ────────────────────────────────────────────────────

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

  // ── Stage 1: Send OTP ───────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    final contact = _mobileController.text.trim();
    if (contact.isEmpty || contact.length != 10) {
      setState(() => _mobileError = 'Enter valid 10-digit number');
      return;
    }
    setState(() {
      _mobileError = null;
      _sendLoading = true;
    });
    try {
      await ref
          .read(customerAuthRepositoryProvider)
          .sendOtp(contact);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _sentToContact = contact;
      });
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mapDioError(e).message),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendLoading = false);
    }
  }

  // ── Stage 2: Verify OTP ─────────────────────────────────────────────────

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
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
      await ref
          .read(customerAuthRepositoryProvider)
          .verifyOtp(_sentToContact, otp);
      if (!mounted) return;
      context.push(
        '/customer/set-pin',
        extra: {'contact': _sentToContact},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mapDioError(e).message),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _verifyLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await ref
          .read(customerAuthRepositoryProvider)
          .sendOtp(_sentToContact);
      if (!mounted) return;
      _startCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent on WhatsApp.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mapDioError(e).message),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _otpSent ? _buildVerifyStage(context) : _buildSendStage(context);
  }

  Widget _buildSendStage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final ink = isDark ? AppColors.darkInk : AppColors.ink;
    final isForgot = widget.reason == 'forgot';

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
                        Icons.message_outlined,
                        size: 56,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      'Verify with OTP',
                      textAlign: TextAlign.center,
                      style: AppText.screenTitle.copyWith(color: ink),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      "We'll send a 6-digit code on WhatsApp",
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
                      errorText: _mobileError,
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
                    const SizedBox(height: AppSpace.sm),
                    if (isForgot)
                      Center(
                        child: TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            'Back to sign in',
                            style: AppText.label.copyWith(color: primary),
                          ),
                        ),
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

  Widget _buildVerifyStage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final inkFaint = isDark ? AppColors.darkInkFaint : AppColors.inkFaint;
    final ink = isDark ? AppColors.darkInk : AppColors.ink;
    final canResend = _countdown == 0;

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
                        Icons.lock_open_outlined,
                        size: 56,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      'Enter OTP',
                      textAlign: TextAlign.center,
                      style: AppText.screenTitle.copyWith(color: ink),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'Check WhatsApp for the 6-digit code sent to\n$_sentToContact',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: inkMuted),
                    ),
                    const SizedBox(height: AppSpace.xxl),
                    AppTextField(
                      label: 'OTP',
                      hint: '6 digits',
                      controller: _otpController,
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
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        Text(
                          canResend
                              ? 'Resend OTP'
                              : 'Resend OTP in ${_formatCountdown(_countdown)}',
                          style: AppText.meta.copyWith(color: inkMuted),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: canResend ? _resendOtp : null,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                canResend ? primary : inkFaint,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.sm,
                              vertical: AppSpace.xxs,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Resend'),
                        ),
                      ],
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
