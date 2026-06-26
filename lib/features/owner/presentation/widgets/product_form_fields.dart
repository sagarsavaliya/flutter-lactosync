import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/selection_chip.dart';
import '../../domain/entities/settings_models.dart';

String buildProductName(String milkTypeLabel, double rate) {
  final rateLabel = rate == rate.roundToDouble()
      ? rate.toStringAsFixed(0)
      : rate.toStringAsFixed(0);
  return '$milkTypeLabel Milk - $rateLabel/-';
}

class ProductFormValues {
  ProductFormValues({
    this.milkTypeId,
    this.containerKind = 'glass_bottle',
    this.selectedContainerIds = const {},
    this.rateText = '',
    this.nameText = '',
    this.nameManuallyEdited = false,
  });

  int? milkTypeId;
  String containerKind;
  Set<int> selectedContainerIds;
  String rateText;
  String nameText;
  bool nameManuallyEdited;

  Map<String, dynamic> toApiJson({
    required List<MilkTypeItem> milkTypes,
  }) {
    final rate = double.parse(rateText.trim());
    String milkLabel = 'Milk';
    for (final t in milkTypes) {
      if (t.id == milkTypeId) {
        milkLabel = t.name;
        break;
      }
    }

    return {
      if (nameText.trim().isNotEmpty) 'name': nameText.trim(),
      'milk_type_id': milkTypeId,
      'rate': rate,
      'unit': 'ltr',
      'container_kind': containerKind,
      'container_type_ids': selectedContainerIds.toList(),
      'milk_type': _legacyMilkSlug(milkLabel),
    };
  }

  String _legacyMilkSlug(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('gir')) return 'gir_cow';
    if (lower.contains('buffalo')) return 'buffalo';
    return 'cow';
  }
}

class ProductFormFields extends StatelessWidget {
  const ProductFormFields({
    super.key,
    required this.values,
    required this.milkTypes,
    required this.containerTypes,
    required this.onChanged,
    this.nameController,
    this.rateController,
  });

  final ProductFormValues values;
  final List<MilkTypeItem> milkTypes;
  final List<ContainerTypeItem> containerTypes;
  final VoidCallback onChanged;
  final TextEditingController? nameController;
  final TextEditingController? rateController;

  List<ContainerTypeItem> get _visibleContainers => containerTypes
      .where((t) => t.isActive && !t.isHidden)
      .toList();

  List<ContainerTypeItem> get _sizesForKind {
    final sizes = _visibleContainers
        .where((t) => (t.kind ?? '') == values.containerKind)
        .toList();
    sizes.sort((a, b) => (b.sizeMl ?? 0).compareTo(a.sizeMl ?? 0));
    return sizes;
  }

  String? get _milkLabel {
    if (values.milkTypeId == null) return null;
    for (final t in milkTypes) {
      if (t.id == values.milkTypeId) return t.name;
    }
    return null;
  }

  void _syncAutoName() {
    if (values.nameManuallyEdited) return;
    final milk = _milkLabel;
    final rate = double.tryParse(values.rateText.trim());
    if (milk == null || rate == null || rate <= 0) return;
    final generated = buildProductName(milk, rate);
    values.nameText = generated;
    nameController?.text = generated;
  }

  @override
  Widget build(BuildContext context) {
    final activeMilkTypes =
        milkTypes.where((t) => t.isActive && !t.isHidden).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          isExpanded: true,
          value: values.milkTypeId,
          decoration: const InputDecoration(labelText: AppStrings.milkTypeLabel),
          items: activeMilkTypes
              .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
              .toList(),
          onChanged: (v) {
            values.milkTypeId = v;
            _syncAutoName();
            onChanged();
          },
        ),
        const SizedBox(height: AppSpace.sm),
        AppTextField(
          label: AppStrings.rateLabel,
          controller: rateController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) {
            values.rateText = v;
            _syncAutoName();
            onChanged();
          },
        ),
        const SizedBox(height: AppSpace.sm),
        Text(AppStrings.containerKindLabel, style: AppText.label),
        const SizedBox(height: AppSpace.xs),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            SelectionChip(
              label: 'Glass Bottle',
              selected: values.containerKind == 'glass_bottle',
              onTap: () {
                values.containerKind = 'glass_bottle';
                values.selectedContainerIds = _defaultSizeIds('glass_bottle');
                onChanged();
              },
            ),
            SelectionChip(
              label: 'Plastic Bag',
              selected: values.containerKind == 'plastic_bag',
              onTap: () {
                values.containerKind = 'plastic_bag';
                values.selectedContainerIds = _defaultSizeIds('plastic_bag');
                onChanged();
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Text(AppStrings.containerSizesLabel, style: AppText.label),
        const SizedBox(height: AppSpace.xs),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: _sizesForKind.map((size) {
            final selected = values.selectedContainerIds.contains(size.id);
            return SelectionChip(
              label: size.displaySizeLabel,
              selected: selected,
              onTap: () {
                if (selected) {
                  values.selectedContainerIds = Set<int>.from(
                    values.selectedContainerIds..remove(size.id),
                  );
                } else {
                  values.selectedContainerIds = Set<int>.from(
                    values.selectedContainerIds..add(size.id),
                  );
                }
                onChanged();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpace.sm),
        AppTextField(
          label: AppStrings.productNameLabel,
          hint: AppStrings.productNameAutoHint,
          controller: nameController,
          onChanged: (v) {
            values.nameText = v;
            values.nameManuallyEdited = v.trim().isNotEmpty;
            onChanged();
          },
        ),
      ],
    );
  }

  Set<int> _defaultSizeIds(String kind) {
    final keys = kind == 'glass_bottle'
        ? {'1L', '500ml'}
        : {'1.5L', '1L', '500ml'};
    return _visibleContainers
        .where((t) => t.kind == kind && keys.contains(t.sizeKey))
        .map((t) => t.id)
        .toSet();
  }
}
