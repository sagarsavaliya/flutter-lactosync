import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../providers/delivery_boy_auth_provider.dart';

class DeliveryBoySetPinPage extends ConsumerStatefulWidget {
  const DeliveryBoySetPinPage({super.key});

  @override
  ConsumerState<DeliveryBoySetPinPage> createState() =>
      _DeliveryBoySetPinPageState();
}

class _DeliveryBoySetPinPageState
    extends ConsumerState<DeliveryBoySetPinPage> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_newCtrl.text.trim().length != 4 ||
        _newCtrl.text.trim() != _confirmCtrl.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match or must be 4 digits')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(deliveryBoyAuthRepositoryProvider).changePin(
            _currentCtrl.text.trim(),
            _newCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN changed successfully')),
      );
      context.pop();
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
      title: 'Change PIN',
      subtitle: 'Enter your current PIN, then your new PIN.',
      child: RedesignSurfaceCard(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PinField(
              controller: _currentCtrl,
              label: 'Current PIN',
              onSubmitted: (_) {},
            ),
            const SizedBox(height: AppSpace.md),
            _PinField(
              controller: _newCtrl,
              label: 'New PIN',
              onSubmitted: (_) {},
            ),
            const SizedBox(height: AppSpace.md),
            _PinField(
              controller: _confirmCtrl,
              label: 'Confirm New PIN',
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpace.lg),
            AppButton(
              label: 'Save New PIN',
              loading: _loading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _PinField extends StatefulWidget {
  const _PinField({
    required this.controller,
    required this.label,
    required this.onSubmitted,
  });
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onSubmitted;

  @override
  State<_PinField> createState() => _PinFieldState();
}

class _PinFieldState extends State<_PinField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: TextInputType.number,
      obscureText: _obscure,
      maxLength: 4,
      style: Theme.of(context).textTheme.bodyMedium,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        counterText: '',
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
