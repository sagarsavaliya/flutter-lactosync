import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_form_layout.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/onboarding_models.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/rate_calculation_card.dart';

class _LineDraft {
  int? productId;
  final qtyController = TextEditingController(text: '1');
  final couponController = TextEditingController();
  String shift = 'morning';

  void dispose() {
    qtyController.dispose();
    couponController.dispose();
  }
}

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  CustomerItem? _selectedCustomer;
  final _lines = [_LineDraft()];
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _initFromBootstrap(SubscriptionBootstrap data) {
    if (_initialized) return;
    _initialized = true;
    _selectedCustomer = data.customers.isNotEmpty ? data.customers.first : null;
    if (data.products.isNotEmpty) {
      _lines.first.productId = data.products.first.id;
    }
  }

  ProductItem? _productFor(int? id, List<ProductItem> products) {
    if (id == null) return null;
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  double _lineTotal(ProductItem? product, _LineDraft line) {
    if (product == null) return 0;
    final qty = double.tryParse(line.qtyController.text.trim()) ?? 0;
    final coupon = double.tryParse(line.couponController.text.trim()) ?? 0;
    final effective = (product.rate - coupon).clamp(0, double.infinity);
    return effective * qty;
  }

  Future<void> _submit() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a customer first')),
      );
      return;
    }

    final bootstrap = ref.read(subscriptionBootstrapProvider).value;
    final products = bootstrap?.products ?? [];

    final payload = <Map<String, dynamic>>[];
    for (final line in _lines) {
      final product = _productFor(line.productId, products);
      if (product == null) continue;
      final qty = double.tryParse(line.qtyController.text.trim()) ?? 0;
      if (qty <= 0) continue;
      payload.add({
        'product_id': product.id,
        'quantity': qty,
        'coupon_amount': double.tryParse(line.couponController.text.trim()) ?? 0,
        'shift': line.shift,
      });
    }

    if (payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product line')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(onboardingRepositoryProvider).saveSubscription(
            customerId: _selectedCustomer!.id,
            lines: payload,
          );
      ref.invalidate(authSessionProvider);
      if (!mounted) return;
      context.go('/dashboard');
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
    final bootstrapAsync = ref.watch(subscriptionBootstrapProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.subscriptionTitle)),
      body: SafeArea(
        child: bootstrapAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mapDioError(e).message, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpace.md),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(subscriptionBootstrapProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            _initFromBootstrap(data);
            final customers = data.customers;
            final products = data.products;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    children: [
                      Text(
                        AppStrings.subscriptionSubtitle,
                        style: AppText.body.copyWith(color: inkMuted),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      DropdownButtonFormField<CustomerItem>(
                        value: _selectedCustomer,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: AppStrings.selectCustomer),
                        items: customers
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text('${c.fullName} · ${c.contact}'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCustomer = v),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      ...List.generate(_lines.length, (i) {
                        final line = _lines[i];
                        final product = _productFor(line.productId, products);
                        final coupon = double.tryParse(line.couponController.text.trim()) ?? 0;
                        final qty = double.tryParse(line.qtyController.text.trim()) ?? 1;
                        final total = _lineTotal(product, line);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<int>(
                                value: line.productId,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: AppStrings.selectProduct),
                                items: products
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p.id,
                                        child: Text('${p.name} · ₹${p.rate.toStringAsFixed(0)}'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => line.productId = v),
                              ),
                              const SizedBox(height: AppSpace.md),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: AppStrings.quantityLabel,
                                      controller: line.qtyController,
                                      suffixText: 'ltr',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                      ],
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  Expanded(
                                    child: AppTextField(
                                      label: AppStrings.couponLabel,
                                      controller: line.couponController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                      ],
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.sm),
                                  Expanded(
                                    child: AppReadOnlyField(
                                      label: AppStrings.totalLabel,
                                      value: '₹${total.toStringAsFixed(0)}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpace.md),
                              Text(AppStrings.shiftLabel, style: AppText.label),
                              const SizedBox(height: AppSpace.xs),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'morning',
                                    label: Text(AppStrings.morningShift),
                                  ),
                                  ButtonSegment(
                                    value: 'evening',
                                    label: Text(AppStrings.eveningShift),
                                  ),
                                ],
                                selected: {line.shift},
                                onSelectionChanged: (s) => setState(() => line.shift = s.first),
                              ),
                              if (product != null) ...[
                                const SizedBox(height: AppSpace.md),
                                RateCalculationCard(
                                  productName: product.name,
                                  unitRate: product.rate,
                                  couponAmount: coupon,
                                  quantity: qty,
                                  unit: product.unit,
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      OutlinedButton(
                        onPressed: () => setState(() {
                          final draft = _LineDraft();
                          if (products.isNotEmpty) draft.productId = products.first.id;
                          _lines.add(draft);
                        }),
                        child: const Text(AppStrings.addMoreProduct),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: AppButton(
                    label: AppStrings.createSubscriptionBtn,
                    loading: _loading,
                    onPressed: _submit,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
