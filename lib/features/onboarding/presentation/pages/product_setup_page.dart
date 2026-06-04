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
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/selection_chip.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class _DraftProduct {
  _DraftProduct();

  final nameController = TextEditingController();
  String milkType = 'cow';
  String containerType = 'glass_bottle';
  final rateController = TextEditingController();

  void loadFrom(_SavedProduct product) {
    nameController.text = product.name;
    milkType = product.milkType;
    containerType = product.containerType;
    rateController.text = product.rate.toStringAsFixed(
      product.rate == product.rate.roundToDouble() ? 0 : 2,
    );
  }

  void clear() {
    nameController.clear();
    rateController.clear();
    milkType = 'cow';
    containerType = 'glass_bottle';
  }

  Map<String, dynamic> toJson() => {
        'name': nameController.text.trim(),
        'milk_type': milkType,
        'rate': double.parse(rateController.text.trim()),
        'unit': 'ltr',
        'container_type': containerType,
      };

  void dispose() {
    nameController.dispose();
    rateController.dispose();
  }
}

class _SavedProduct {
  const _SavedProduct({
    required this.name,
    required this.milkType,
    required this.containerType,
    required this.rate,
  });

  final String name;
  final String milkType;
  final String containerType;
  final double rate;

  Map<String, dynamic> toJson() => {
        'name': name,
        'milk_type': milkType,
        'rate': rate,
        'unit': 'ltr',
        'container_type': containerType,
      };

  String get milkTypeLabel => switch (milkType) {
        'gir_cow' => 'Gir Cow',
        'buffalo' => 'Buffalo',
        _ => 'Cow',
      };

  String get containerLabel => switch (containerType) {
        'plastic_bag' => 'Plastic Bag',
        _ => 'Glass Bottle',
      };
}

class ProductSetupPage extends ConsumerStatefulWidget {
  const ProductSetupPage({super.key});

  @override
  ConsumerState<ProductSetupPage> createState() => _ProductSetupPageState();
}

class _ProductSetupPageState extends ConsumerState<ProductSetupPage> {
  final _draft = _DraftProduct();
  final _saved = <_SavedProduct>[];
  int? _editingIndex;
  bool _loading = false;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  bool _validateDraft() {
    if (_draft.nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.productNameRequired)),
      );
      return false;
    }
    final rate = double.tryParse(_draft.rateController.text.trim());
    if (rate == null || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.rateRequired)),
      );
      return false;
    }
    return true;
  }

  void _addOrUpdateProduct() {
    if (!_validateDraft()) return;

    final entry = _SavedProduct(
      name: _draft.nameController.text.trim(),
      milkType: _draft.milkType,
      containerType: _draft.containerType,
      rate: double.parse(_draft.rateController.text.trim()),
    );

    setState(() {
      if (_editingIndex != null) {
        _saved[_editingIndex!] = entry;
        _editingIndex = null;
      } else {
        _saved.add(entry);
      }
      _draft.clear();
    });
  }

  void _deleteProduct(int index) {
    setState(() {
      if (_editingIndex == index) {
        _editingIndex = null;
        _draft.clear();
      } else if (_editingIndex != null && index < _editingIndex!) {
        _editingIndex = _editingIndex! - 1;
      }
      _saved.removeAt(index);
    });
  }

  Future<void> _confirmDeleteProduct(int index) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: AppStrings.deleteProductTitle,
      message: AppStrings.deleteProductConfirm,
      confirmLabel: AppStrings.deleteLabel,
      cancelLabel: AppStrings.cancelLabel,
      destructive: true,
    );
    if (confirmed == true && mounted) _deleteProduct(index);
  }

  void _editProduct(int index) {
    setState(() {
      _editingIndex = index;
      _draft.loadFrom(_saved[index]);
    });
  }

  Future<void> _save() async {
    if (_saved.isEmpty) {
      if (!_validateDraft()) return;
      _addOrUpdateProduct();
    }
    if (_saved.isEmpty) return;

    setState(() => _loading = true);
    try {
      await ref.read(onboardingRepositoryProvider).saveProductsBatch(
            _saved.map((p) => p.toJson()).toList(),
          );
      ref.invalidate(authSessionProvider);
      if (!mounted) return;
      context.go('/onboarding/dashboard');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkMuted = isDark ? AppColors.darkInkMuted : AppColors.inkMuted;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.productsTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.lg),
                children: [
                  Text(
                    AppStrings.productsSubtitle,
                    style: AppText.body.copyWith(color: inkMuted),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _editingIndex != null ? AppStrings.editProduct : AppStrings.addProduct,
                          style: AppText.sectionTitle,
                        ),
                        const SizedBox(height: AppSpace.md),
                        AppTextField(
                          label: AppStrings.productNameLabel,
                          hint: AppStrings.productNameHint,
                          controller: _draft.nameController,
                        ),
                        const SizedBox(height: AppSpace.md),
                        Text(AppStrings.milkTypeLabel, style: AppText.label),
                        const SizedBox(height: AppSpace.xs),
                        Wrap(
                          spacing: AppSpace.xs,
                          runSpacing: AppSpace.xs,
                          children: [
                            _SelectionChip(
                              label: 'Gir Cow',
                              selected: _draft.milkType == 'gir_cow',
                              onTap: () => setState(() => _draft.milkType = 'gir_cow'),
                            ),
                            _SelectionChip(
                              label: 'Cow',
                              selected: _draft.milkType == 'cow',
                              onTap: () => setState(() => _draft.milkType = 'cow'),
                            ),
                            _SelectionChip(
                              label: 'Buffalo',
                              selected: _draft.milkType == 'buffalo',
                              onTap: () => setState(() => _draft.milkType = 'buffalo'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.md),
                        AppTextField(
                          label: AppStrings.rateLabel,
                          controller: _draft.rateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                        const SizedBox(height: AppSpace.md),
                        Text(AppStrings.containerLabel, style: AppText.label),
                        const SizedBox(height: AppSpace.xs),
                        Wrap(
                          spacing: AppSpace.xs,
                          runSpacing: AppSpace.xs,
                          children: [
                            _SelectionChip(
                              label: 'Glass Bottle',
                              selected: _draft.containerType == 'glass_bottle',
                              onTap: () => setState(() => _draft.containerType = 'glass_bottle'),
                            ),
                            _SelectionChip(
                              label: 'Plastic Bag',
                              selected: _draft.containerType == 'plastic_bag',
                              onTap: () => setState(() => _draft.containerType = 'plastic_bag'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  OutlinedButton(
                    onPressed: _addOrUpdateProduct,
                    child: Text(
                      _editingIndex != null ? AppStrings.confirmLabel : AppStrings.addProduct,
                    ),
                  ),
                  if (_saved.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.lg),
                    ...List.generate(_saved.length, (i) {
                      final p = _saved[i];
                      final isEditing = _editingIndex == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: AppCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, style: AppText.cardTitle),
                                    const SizedBox(height: AppSpace.xxs),
                                    Text(
                                      '${p.milkTypeLabel} · ${p.containerLabel} · ₹${p.rate.toStringAsFixed(0)}/ltr',
                                      style: AppText.meta.copyWith(color: inkMuted),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: AppStrings.editProduct,
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: isEditing ? primary : inkMuted,
                                ),
                                onPressed: () => _editProduct(i),
                              ),
                              IconButton(
                                tooltip: AppStrings.deleteProductTitle,
                                icon: Icon(Icons.delete_outline, size: 20, color: inkMuted),
                                onPressed: () => _confirmDeleteProduct(i),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: AppButton(
                label: AppStrings.saveProducts,
                loading: _loading,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _SelectionChip = SelectionChip;

