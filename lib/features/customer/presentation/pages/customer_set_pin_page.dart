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

class CustomerSetPinPage extends ConsumerStatefulWidget {
  const CustomerSetPinPage({super.key, required this.contact});

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
      await ref.read(customerAuthRepositoryProvider).setPin(widget.contact, pin);
      if (!mounted) return;
      context.go('/customer/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mapDioError(e).message),
          backgroundColor: CustomerDetailColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RedesignFormScaffold(
      scrollable: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: CustomerDetailColors.accentLight,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: CustomerDetailColors.accentBorder),
              ),
              child: Icon(
                LucideIcons.lock,
                size: 36,
                color: CustomerDetailColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Set your PIN',
            textAlign: TextAlign.center,
            style: AppText.screenTitle.copyWith(color: CustomerDetailColors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            "Choose a 4-digit PIN — you'll use this to sign in",
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(color: CustomerDetailColors.onSurfaceVariant),
          ),
          const SizedBox(height: 40),
          RedesignSurfaceCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AppTextField(
                  label: 'New PIN',
                  hint: '4 digits',
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  prefixIcon: LucideIcons.keyRound,
                  errorText: _pinError,
                  suffixIcon: _obscurePin ? LucideIcons.eye : LucideIcons.eyeOff,
                  onSuffixTap: () => setState(() => _obscurePin = !_obscurePin),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm PIN',
                  hint: '4 digits',
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  keyboardType: TextInputType.number,
                  prefixIcon: LucideIcons.keyRound,
                  errorText: _confirmError,
                  suffixIcon: _obscureConfirm ? LucideIcons.eye : LucideIcons.eyeOff,
                  onSuffixTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                ),
                const SizedBox(height: 20),
                AppButton(label: 'Save PIN', loading: _loading, onPressed: _submit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
