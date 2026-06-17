import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/onboarding_models.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/rate_calculation_card.dart';
import '../../../../core/widgets/app_snackbar.dart';

const List<double> kSubscriptionQtyOptions = [
  0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0,
  5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0,
];

String _qtyLabel(double litres) {
  if (litres < 1.0) return '${(litres * 1000).toInt()} ml';
  if (litres == litres.roundToDouble()) return '${litres.toInt()} L';
  return '$litres L';
}

class _LineDraft {
  int? productId;
  double qty = 0.5;
  final couponController = TextEditingController();
  String shift = 'morning';

  void dispose() {
    couponController.dispose();
  }
}

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({
    super.key,
    this.lockedCustomerId,
    this.prefilledCustomer,
  });

  final int? lockedCustomerId;
  final CustomerItem? prefilledCustomer;

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  CustomerItem? _selectedCustomer;
  final _lines = [_LineDraft()];
  bool _loading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final prefilled = widget.prefilledCustomer;
    final lockedId = widget.lockedCustomerId ?? prefilled?.id;
    if (lockedId != null && prefilled != null && prefilled.id == lockedId) {
      _selectedCustomer = prefilled;
    }
  }

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(SubscriptionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lockedCustomerId != widget.lockedCustomerId ||
        oldWidget.prefilledCustomer?.id != widget.prefilledCustomer?.id) {
      _initialized = false;
      _selectedCustomer = widget.prefilledCustomer;
    }
  }

  void _applyBootstrap(SubscriptionBootstrap data) {
    if (_initialized) return;
    _initialized = true;

    final lockedId = widget.lockedCustomerId ?? widget.prefilledCustomer?.id;
    if (lockedId != null) {
      _selectedCustomer = data.customers.where((c) => c.id == lockedId).firstOrNull ??
          widget.prefilledCustomer;
    } else {
      _selectedCustomer = data.customers.isNotEmpty ? data.customers.first : null;
    }

    if (data.products.isNotEmpty && _lines.first.productId == null) {
      _lines.first.productId = data.products.first.id;
    }
  }

  CustomerItem? _customerDropdownValue(List<CustomerItem> customers) {
    final target = _selectedCustomer ?? widget.prefilledCustomer;
    if (target == null) return null;
    return customers.where((c) => c.id == target.id).firstOrNull ?? target;
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
    final coupon = double.tryParse(line.couponController.text.trim()) ?? 0;
    final effective = (product.rate - coupon).clamp(0, double.infinity);
    return effective * line.qty;
  }

  Future<void> _submit() async {
    final customer = _selectedCustomer ?? widget.prefilledCustomer;
    if (customer == null) {
      AppSnackBar.show(context, 'Add a customer first');
      return;
    }

    final bootstrap = ref.read(subscriptionBootstrapProvider).value;
    final products = bootstrap?.products ?? [];

    final payload = <Map<String, dynamic>>[];
    for (final line in _lines) {
      final product = _productFor(line.productId, products);
      if (product == null) continue;
      if (line.qty <= 0) continue;
      payload.add({
        'product_id': product.id,
        'quantity': line.qty,
        'coupon_amount': double.tryParse(line.couponController.text.trim()) ?? 0,
        'shift': line.shift,
      });
    }

    if (payload.isEmpty) {
      AppSnackBar.show(context, 'Add at least one product line');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(onboardingRepositoryProvider).saveSubscription(
            customerId: customer.id,
            lines: payload,
          );
      ref.invalidate(authSessionProvider);
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, mapDioError(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapAsync = ref.watch(subscriptionBootstrapProvider);

    return RedesignFormScaffold(
      title: AppStrings.subscriptionTitle,
      subtitle: AppStrings.subscriptionSubtitle,
      scrollable: false,
      padding: EdgeInsets.zero,
      bottom: AppButton(
        label: AppStrings.createSubscriptionBtn,
        loading: _loading,
        onPressed: _submit,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: bootstrapAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: CustomerDetailColors.accent),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e is ApiException
                        ? e.message
                        : mapDioError(e).message,
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: CustomerDetailColors.bodyInk),
                  ),
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
            if (!_initialized) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _initialized) return;
                setState(() => _applyBootstrap(data));
              });
            }

            final lockedId = widget.lockedCustomerId ?? widget.prefilledCustomer?.id;
            var customers = List<CustomerItem>.from(data.customers);
            final prefilled = widget.prefilledCustomer;
            if (lockedId != null &&
                prefilled != null &&
                prefilled.id == lockedId &&
                !customers.any((c) => c.id == lockedId)) {
              customers = [prefilled, ...customers];
            }
            final products = data.products;
            final isCustomerLocked = lockedId != null;
            final customerValue = _customerDropdownValue(customers);

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
              children: [
                RedesignSurfaceCard(
                  child: DropdownButtonFormField<CustomerItem>(
                    value: customerValue,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: AppStrings.selectCustomer,
                    ),
                    items: customers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.fullName} · ${c.contact}'),
                          ),
                        )
                        .toList(),
                    onChanged: isCustomerLocked
                        ? null
                        : (v) => setState(() => _selectedCustomer = v),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                ...List.generate(_lines.length, (i) {
                  final line = _lines[i];
                  final product = _productFor(line.productId, products);
                  final coupon =
                      double.tryParse(line.couponController.text.trim()) ?? 0;
                  final total = _lineTotal(product, line);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.lg),
                    child: RedesignSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<int>(
                            value: line.productId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: AppStrings.selectProduct,
                            ),
                            items: products
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p.id,
                                    child: Text(
                                      '${p.name} · ₹${p.rate.toStringAsFixed(0)}',
                                    ),
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
                                child: DropdownButtonFormField<double>(
                                  value: line.qty,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.quantityLtrLabel,
                                  ),
                                  items: kSubscriptionQtyOptions
                                      .map(
                                        (q) => DropdownMenuItem(
                                          value: q,
                                          child: Text(_qtyLabel(q)),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => line.qty = v);
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(
                                child: TextFormField(
                                  controller: line.couponController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}'),
                                    ),
                                  ],
                                  onChanged: (_) => setState(() {}),
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.couponLtrLabel,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(
                                child: TextFormField(
                                  key: ValueKey(total),
                                  readOnly: true,
                                  enableInteractiveSelection: false,
                                  initialValue: '₹${total.toStringAsFixed(0)}',
                                  style: AppText.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: CustomerDetailColors.onSurface,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.totalLabel,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpace.md),
                          Text(
                            AppStrings.shiftLabel,
                            style: AppText.label.copyWith(
                              color: CustomerDetailColors.labelMuted,
                            ),
                          ),
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
                            onSelectionChanged: (s) =>
                                setState(() => line.shift = s.first),
                          ),
                          if (product != null) ...[
                            const SizedBox(height: AppSpace.md),
                            RateCalculationCard(
                              productName: product.name,
                              unitRate: product.rate,
                              couponAmount: coupon,
                              quantity: line.qty,
                              unit: product.unit,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                OutlinedButton(
                  onPressed: () => setState(() {
                    final draft = _LineDraft();
                    if (products.isNotEmpty) {
                      draft.productId = products.first.id;
                    }
                    _lines.add(draft);
                  }),
                  child: const Text(AppStrings.addMoreProduct),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
