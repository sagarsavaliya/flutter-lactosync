import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/redesign_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/redesign_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../owner/domain/entities/settings_models.dart';
import '../../../owner/presentation/providers/owner_provider.dart';
import '../../../owner/presentation/widgets/product_form_fields.dart';
import '../providers/onboarding_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';

class _SavedProductDraft {
  _SavedProductDraft({
    required this.values,
    required this.milkTypes,
  });

  final ProductFormValues values;
  final List<MilkTypeItem> milkTypes;

  String get displayName {
    if (values.nameText.trim().isNotEmpty) return values.nameText.trim();
    String? milk;
    for (final t in milkTypes) {
      if (t.id == values.milkTypeId) {
        milk = t.name;
        break;
      }
    }
    final rate = double.tryParse(values.rateText.trim());
    if (milk == null || rate == null) return AppStrings.addProduct;
    return buildProductName(milk, rate);
  }

  Map<String, dynamic> toJson() => values.toApiJson(milkTypes: milkTypes);
}

class ProductSetupPage extends ConsumerStatefulWidget {
  const ProductSetupPage({super.key});

  @override
  ConsumerState<ProductSetupPage> createState() => _ProductSetupPageState();
}

class _ProductSetupPageState extends ConsumerState<ProductSetupPage> {
  final _values = ProductFormValues();
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();
  final _saved = <_SavedProductDraft>[];
  int? _editingIndex;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  bool _validateDraft(List<MilkTypeItem> milkTypes) {
    if (_values.milkTypeId == null) {
      AppSnackBar.show(context, AppStrings.milkTypeLabel);
      return false;
    }
    final rate = double.tryParse(_values.rateText.trim());
    if (rate == null || rate <= 0) {
      AppSnackBar.show(context, AppStrings.rateRequired);
      return false;
    }
    if (_values.selectedContainerIds.isEmpty) {
      AppSnackBar.show(context, AppStrings.containerSizesRequired);
      return false;
    }
    if (_values.nameText.trim().isEmpty) {
      final milk = milkTypes.firstWhere((t) => t.id == _values.milkTypeId).name;
      _values.nameText = buildProductName(milk, rate);
      _nameController.text = _values.nameText;
    }
    return true;
  }

  void _addOrUpdateProduct(List<MilkTypeItem> milkTypes) {
    if (!_validateDraft(milkTypes)) return;

    final entry = _SavedProductDraft(
      values: ProductFormValues(
        milkTypeId: _values.milkTypeId,
        containerKind: _values.containerKind,
        selectedContainerIds: Set<int>.from(_values.selectedContainerIds),
        rateText: _values.rateText,
        nameText: _values.nameText,
        nameManuallyEdited: _values.nameManuallyEdited,
      ),
      milkTypes: milkTypes,
    );

    setState(() {
      if (_editingIndex != null) {
        _saved[_editingIndex!] = entry;
        _editingIndex = null;
      } else {
        _saved.add(entry);
      }
      _resetDraft();
    });
  }

  void _resetDraft() {
    _values
      ..milkTypeId = null
      ..containerKind = 'glass_bottle'
      ..selectedContainerIds = {}
      ..rateText = ''
      ..nameText = ''
      ..nameManuallyEdited = false;
    _nameController.clear();
    _rateController.clear();
  }

  void _deleteProduct(int index) {
    setState(() {
      if (_editingIndex == index) {
        _editingIndex = null;
        _resetDraft();
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

  void _editProduct(int index, List<MilkTypeItem> milkTypes) {
    final draft = _saved[index];
    setState(() {
      _editingIndex = index;
      _values
        ..milkTypeId = draft.values.milkTypeId
        ..containerKind = draft.values.containerKind
        ..selectedContainerIds = Set<int>.from(draft.values.selectedContainerIds)
        ..rateText = draft.values.rateText
        ..nameText = draft.values.nameText
        ..nameManuallyEdited = draft.values.nameManuallyEdited;
      _nameController.text = draft.values.nameText;
      _rateController.text = draft.values.rateText;
    });
  }

  Future<void> _save() async {
    final milkTypes = ref.read(milkTypesProvider).valueOrNull ?? [];
    final containerTypes = ref.read(containerTypesProvider).valueOrNull ?? [];

    if (_saved.isEmpty) {
      if (!_validateDraft(milkTypes)) return;
      _addOrUpdateProduct(milkTypes);
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
      AppSnackBar.show(context, mapDioError(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    if (milkTypes.isEmpty || containerTypes.isEmpty) {
      // no-op; providers loaded above for validation only
    }
  }

  @override
  Widget build(BuildContext context) {
    final milkTypesAsync = ref.watch(milkTypesProvider);
    final containerTypesAsync = ref.watch(containerTypesProvider);

    return RedesignFormScaffold(
      title: AppStrings.productsTitle,
      subtitle: AppStrings.productsSubtitle,
      scrollable: false,
      padding: EdgeInsets.zero,
      bottom: AppButton(
        label: AppStrings.saveProducts,
        loading: _loading,
        onPressed: _save,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: milkTypesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: CustomerDetailColors.accent),
          ),
          error: (_, __) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(milkTypesProvider),
              child: const Text('Retry'),
            ),
          ),
          data: (milkTypes) => containerTypesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: CustomerDetailColors.accent),
            ),
            error: (_, __) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(containerTypesProvider),
                child: const Text('Retry'),
              ),
            ),
            data: (containerTypes) {
              if (_values.milkTypeId == null && milkTypes.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _values.milkTypeId != null) return;
                  setState(() {
                    _values.milkTypeId = milkTypes.first.id;
                    if (_values.selectedContainerIds.isEmpty) {
                      _values.selectedContainerIds = containerTypes
                          .where((t) =>
                              t.kind == 'glass_bottle' &&
                              t.isActive &&
                              !t.isHidden &&
                              (t.sizeKey == '1L' || t.sizeKey == '500ml'))
                          .map((t) => t.id)
                          .toSet();
                    }
                  });
                });
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                children: [
                  RedesignSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _editingIndex != null
                              ? AppStrings.editProduct
                              : AppStrings.addProduct,
                          style: AppText.sectionTitle.copyWith(
                            color: CustomerDetailColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpace.md),
                        ProductFormFields(
                          values: _values,
                          milkTypes: milkTypes,
                          containerTypes: containerTypes,
                          nameController: _nameController,
                          rateController: _rateController,
                          onChanged: () => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  OutlinedButton(
                    onPressed: () => _addOrUpdateProduct(milkTypes),
                    child: Text(
                      _editingIndex != null
                          ? AppStrings.confirmLabel
                          : AppStrings.addProduct,
                    ),
                  ),
                  if (_saved.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.lg),
                    ...List.generate(_saved.length, (i) {
                      final p = _saved[i];
                      final isEditing = _editingIndex == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpace.sm),
                        child: RedesignSurfaceCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.displayName,
                                      style: AppText.cardTitle.copyWith(
                                        color: CustomerDetailColors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.xxs),
                                    Text(
                                      '₹${p.values.rateText}/ltr',
                                      style: AppText.meta.copyWith(
                                        color: CustomerDetailColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: AppStrings.editProduct,
                                icon: Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: isEditing
                                      ? CustomerDetailColors.accent
                                      : CustomerDetailColors.iconMuted,
                                ),
                                onPressed: () => _editProduct(i, milkTypes),
                              ),
                              IconButton(
                                tooltip: AppStrings.deleteProductTitle,
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: CustomerDetailColors.iconMuted,
                                ),
                                onPressed: () => _confirmDeleteProduct(i),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
