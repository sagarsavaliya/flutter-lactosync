import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../../../owner/presentation/widgets/customer_detail/customer_detail_styles.dart';
import '../providers/customer_auth_provider.dart';

class CustomerOtpPage extends ConsumerStatefulWidget {
  const CustomerOtpPage({
    super.key,
    required this.initialContact,
    required this.reason,
  });

  final String initialContact;
  final String reason;

  @override
  ConsumerState<CustomerOtpPage> createState() => _CustomerOtpPageState();
}

class _CustomerOtpPageState extends ConsumerState<CustomerOtpPage> {
  final _mobileController = TextEditingController();
  String? _mobileError;
  bool _sendLoading = false;

  bool _otpSent = false;
  String _sentToContact = '';
  final _otpController = TextEditingController();
  String? _otpError;
  bool _verifyLoading = false;

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
      await ref.read(customerAuthRepositoryProvider).sendOtp(contact);
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
          backgroundColor: CustomerDetailColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendLoading = false);
    }
  }

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
      await ref.read(customerAuthRepositoryProvider).verifyOtp(_sentToContact, otp);
      if (!mounted) return;
      context.push('/customer/set-pin', extra: {'contact': _sentToContact});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mapDioError(e).message),
          backgroundColor: CustomerDetailColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _verifyLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    try {
      await ref.read(customerAuthRepositoryProvider).sendOtp(_sentToContact);
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
          backgroundColor: CustomerDetailColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _otpSent ? _buildVerifyStage(context) : _buildSendStage(context);
  }

  Widget _buildSendStage(BuildContext context) {
    final isForgot = widget.reason == 'forgot';

    return RedesignFormScaffold(
      scrollable: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _AuthHeroIcon(icon: LucideIcons.messageCircle),
          const SizedBox(height: 20),
          Text(
            'Verify with OTP',
            textAlign: TextAlign.center,
            style: AppText.screenTitle.copyWith(color: CustomerDetailColors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll send a 6-digit code on WhatsApp",
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: CustomerDetailColors.onSurfaceVariant),
          ),
          const SizedBox(height: 40),
          RedesignSurfaceCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AppTextField(
                  label: 'Mobile number',
                  hint: '10-digit number',
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: LucideIcons.smartphone,
                  errorText: _mobileError,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(label: 'Send OTP', loading: _sendLoading, onPressed: _sendOtp),
              ],
            ),
          ),
          if (isForgot) ...[
            const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Widget _buildVerifyStage(BuildContext context) {
    final canResend = _countdown == 0;

    return RedesignFormScaffold(
      scrollable: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _AuthHeroIcon(icon: LucideIcons.unlock),
          const SizedBox(height: 20),
          Text(
            'Enter OTP',
            textAlign: TextAlign.center,
            style: AppText.screenTitle.copyWith(color: CustomerDetailColors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Check WhatsApp for the 6-digit code sent to\n$_sentToContact',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: CustomerDetailColors.onSurfaceVariant),
          ),
          const SizedBox(height: 40),
          RedesignSurfaceCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AppTextField(
                  label: 'OTP',
                  hint: '6 digits',
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  prefixIcon: LucideIcons.messageSquare,
                  errorText: _otpError,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Verify OTP',
                  loading: _verifyLoading,
                  onPressed: _verifyOtp,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      canResend
                          ? 'Resend OTP'
                          : 'Resend OTP in ${_formatCountdown(_countdown)}',
                      style: AppText.meta.copyWith(color: CustomerDetailColors.onSurfaceVariant),
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
        ],
      ),
    );
  }
}

class _AuthHeroIcon extends StatelessWidget {
  const _AuthHeroIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: CustomerDetailColors.accentLight,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: CustomerDetailColors.accentBorder),
        ),
        child: Icon(icon, size: 36, color: CustomerDetailColors.accent),
      ),
    );
  }
}
