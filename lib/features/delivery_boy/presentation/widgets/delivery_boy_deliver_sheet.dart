import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/delivery_boy_route_provider.dart';
import 'delivery_boy_styles.dart';
import 'delivery_boy_widgets.dart';

/// Screen 3 — Deliver confirm & collect cash (bottom sheet).
class DeliveryBoyDeliverSheet extends ConsumerStatefulWidget {
  const DeliveryBoyDeliverSheet({
    super.key,
    required this.customer,
    required this.date,
  });

  final DbRouteCustomer customer;
  final String date;

  @override
  ConsumerState<DeliveryBoyDeliverSheet> createState() =>
      _DeliveryBoyDeliverSheetState();
}

class _DeliveryBoyDeliverSheetState
    extends ConsumerState<DeliveryBoyDeliverSheet> {
  late double _qty;
  final _cashCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _qty = widget.customer.totalQty > 0 ? widget.customer.totalQty : 1;
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  double get _dues => widget.customer.outstandingBalance;

  Future<void> _submit({bool skip = false}) async {
    if (skip) {
      try {
        await deliveryBoySkipDelivery(
          ref: ref,
          customerId: widget.customer.customerId,
          date: widget.date,
        );
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) AppSnackBar.showError(context, mapDioError(e).message);
      }
      return;
    }

    final orderId = widget.customer.primaryOrderId;
    if (orderId == null) {
      AppSnackBar.showError(context, 'No order found for this stop.');
      return;
    }

    setState(() => _loading = true);
    try {
      final cash = double.tryParse(_cashCtrl.text.trim()) ?? 0;
      await deliveryBoyMarkDelivered(
        ref: ref,
        orderId: orderId,
        date: widget.date,
        quantity: _qty,
        cashReceived: cash,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, mapDioError(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.customer.deliveryLines.isNotEmpty
        ? widget.customer.deliveryLines.first
        : null;
    final productLabel = line?.productName.isNotEmpty == true
        ? line!.productName
        : 'Milk delivery';

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: DbBoyColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DbBoyColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: DbBoyText.whiteCard(),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.customer.name,
                                  style: DbBoyText.cardTitle,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.customer.address,
                                  style: DbBoyText.meta,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('DELIVER QUANTITY', style: DbBoyText.sectionLabel),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: DbBoyText.whiteCard(radius: DbBoyMetrics.innerRadius),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(productLabel, style: DbBoyText.cardTitle.copyWith(fontSize: 15)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _QtyBtn(
                                icon: LucideIcons.minus,
                                onTap: () => setState(() {
                                  if (_qty > 0.5) _qty -= 0.5;
                                }),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  '${_qty.toStringAsFixed(1)} L',
                                  style: DbBoyText.greeting.copyWith(fontSize: 28),
                                ),
                              ),
                              _QtyBtn(
                                icon: LucideIcons.plus,
                                onTap: () => setState(() => _qty += 0.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('CASH COLLECTION', style: DbBoyText.sectionLabel),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: DbBoyText.whiteCard(radius: DbBoyMetrics.innerRadius),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Their dairy dues: ₹${_dues.toStringAsFixed(0)}',
                            style: DbBoyText.cardTitle.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _cashCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Cash received',
                              prefixText: '₹ ',
                              filled: true,
                              fillColor: DbBoyColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: DbBoyColors.border),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (_dues >= 500)
                                _QuickCash(
                                  label: '₹500',
                                  onTap: () => _cashCtrl.text = '500',
                                ),
                              if (_dues >= 1000)
                                _QuickCash(
                                  label: '₹1,000',
                                  onTap: () => _cashCtrl.text = '1000',
                                ),
                              if (_dues > 0)
                                _QuickCash(
                                  label: 'Full ₹${_dues.toStringAsFixed(0)}',
                                  onTap: () =>
                                      _cashCtrl.text = _dues.toStringAsFixed(0),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Cash is carried to the dairy and credited to the customer\'s account.',
                            style: DbBoyText.meta.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    DbPrimaryButton(
                      label: 'Mark delivered',
                      icon: LucideIcons.check,
                      loading: _loading,
                      onPressed: () => _submit(),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _loading ? null : () => _submit(skip: true),
                      child: Text(
                        'Skip this stop',
                        style: DbBoyText.cardTitle.copyWith(
                          color: DbBoyColors.danger,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DbBoyColors.accentLight,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: DbBoyColors.accent),
        ),
      ),
    );
  }
}

class _QuickCash extends StatelessWidget {
  const _QuickCash({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      backgroundColor: DbBoyColors.accentLight,
      side: const BorderSide(color: DbBoyColors.accentBorder),
      onPressed: onTap,
    );
  }
}
