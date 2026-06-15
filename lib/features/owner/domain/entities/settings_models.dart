class PincodeResult {
  final String city;
  final String district;
  final String state;
  const PincodeResult({required this.city, required this.district, required this.state});
  factory PincodeResult.fromJson(Map<String, dynamic> json) => PincodeResult(
        city: json['city'] as String,
        district: json['district'] as String,
        state: json['state'] as String,
      );
}

class OwnerSettings {
  const OwnerSettings({
    required this.farm,
    required this.owner,
    required this.documentSettings,
    required this.products,
  });

  final SettingsFarm farm;
  final SettingsOwner owner;
  final DocumentTemplateSettings documentSettings;
  final List<SettingsProduct> products;

  factory OwnerSettings.fromJson(Map<String, dynamic> json) {
    final productList = json['products'] as List<dynamic>? ?? [];
    return OwnerSettings(
      farm: SettingsFarm.fromJson(Map<String, dynamic>.from(json['farm'] as Map)),
      owner: SettingsOwner.fromJson(Map<String, dynamic>.from(json['owner'] as Map)),
      documentSettings: DocumentTemplateSettings.fromJson(
        Map<String, dynamic>.from(json['document_settings'] as Map? ?? {}),
      ),
      products: productList
          .map((e) => SettingsProduct.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class SettingsFarm {
  const SettingsFarm({
    required this.id,
    this.name,
    this.addressLine,
    this.city,
    this.state,
    this.zip,
    this.upiVpa,
    this.upiPayeeName,
    this.morningOrderTime,
    this.eveningOrderTime,
    this.prefillCustomerAddress = false,
  });

  final int id;
  final String? name;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? zip;
  final String? upiVpa;
  final String? upiPayeeName;
  final String? morningOrderTime;
  final String? eveningOrderTime;
  /// OR-10: when true, city/state/PIN are pre-filled when adding a new customer.
  final bool prefillCustomerAddress;

  factory SettingsFarm.fromJson(Map<String, dynamic> json) {
    return SettingsFarm(
      id: json['id'] as int,
      name: json['name'] as String?,
      addressLine: json['address_line'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zip: json['zip'] as String?,
      upiVpa: json['upi_vpa'] as String?,
      upiPayeeName: json['upi_payee_name'] as String?,
      morningOrderTime: json['morning_order_time'] as String? ?? '05:00',
      eveningOrderTime: json['evening_order_time'] as String? ?? '15:00',
      prefillCustomerAddress: json['prefill_customer_address'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'address_line': addressLine,
        'city': city,
        'state': state,
        'zip': zip,
        'upi_vpa': upiVpa,
        'upi_payee_name': upiPayeeName,
        if (morningOrderTime != null) 'morning_order_time': morningOrderTime,
        if (eveningOrderTime != null) 'evening_order_time': eveningOrderTime,
        'prefill_customer_address': prefillCustomerAddress,
      };
}

class SettingsOwner {
  const SettingsOwner({
    this.firstName,
    this.lastName,
    required this.fullName,
    required this.mobile,
  });

  final String? firstName;
  final String? lastName;
  final String fullName;
  final String mobile;

  factory SettingsOwner.fromJson(Map<String, dynamic> json) {
    return SettingsOwner(
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      fullName: json['full_name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'first_name': firstName,
        'last_name': lastName,
      };
}

class ProductContainerSize {
  const ProductContainerSize({
    required this.id,
    required this.sizeKey,
    required this.sizeLabel,
  });

  final int id;
  final String sizeKey;
  final String sizeLabel;

  factory ProductContainerSize.fromJson(Map<String, dynamic> json) {
    return ProductContainerSize(
      id: json['id'] as int,
      sizeKey: json['size_key'] as String? ?? '',
      sizeLabel: json['size_label'] as String? ?? json['name'] as String? ?? '',
    );
  }
}

class SettingsProduct {
  const SettingsProduct({
    required this.id,
    required this.name,
    required this.milkType,
    required this.milkTypeLabel,
    required this.rate,
    required this.unit,
    required this.containerType,
    required this.containerTypeLabel,
    this.milkTypeId,
    this.containerTypeId,
    this.containerKind,
    this.containerTypeIds = const [],
    this.containerSizes = const [],
  });

  final int id;
  final String name;
  final String milkType;
  final String milkTypeLabel;
  final double rate;
  final String unit;
  final String containerType;
  final String containerTypeLabel;
  final int? milkTypeId;
  final int? containerTypeId;
  final String? containerKind;
  final List<int> containerTypeIds;
  final List<ProductContainerSize> containerSizes;

  String get containerSizesLabel => containerSizes.isEmpty
      ? containerTypeLabel
      : containerSizes.map((s) => s.sizeLabel).join(', ');

  factory SettingsProduct.fromJson(Map<String, dynamic> json) {
    final sizes = (json['container_sizes'] as List<dynamic>? ?? [])
        .map((e) => ProductContainerSize.fromJson(e as Map<String, dynamic>))
        .toList();

    return SettingsProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      milkType: json['milk_type'] as String? ?? 'cow',
      milkTypeLabel: json['milk_type_label'] as String? ?? '',
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? 'ltr',
      containerType: json['container_type'] as String? ?? 'glass_bottle',
      containerTypeLabel: json['container_type_label'] as String? ?? '',
      milkTypeId: json['milk_type_id'] as int?,
      containerTypeId: json['container_type_id'] as int?,
      containerKind: json['container_kind'] as String?,
      containerTypeIds: (json['container_type_ids'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      containerSizes: sizes,
    );
  }
}

class MilkTypeItem {
  final int id;
  final String name;
  final bool isSystem;
  final bool isHidden;
  final bool isActive;
  const MilkTypeItem({
    required this.id,
    required this.name,
    required this.isSystem,
    required this.isHidden,
    required this.isActive,
  });
  factory MilkTypeItem.fromJson(Map<String, dynamic> json) => MilkTypeItem(
        id: json['id'] as int,
        name: json['name'] as String,
        isSystem: json['is_system'] as bool? ?? false,
        isHidden: json['is_hidden'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
      );
}

class ContainerTypeItem {
  final int id;
  final String name;
  final String? kind;
  final String? sizeKey;
  final String? sizeLabel;
  final int? sizeMl;
  final bool isSystem;
  final bool isHidden;
  final bool isActive;
  const ContainerTypeItem({
    required this.id,
    required this.name,
    this.kind,
    this.sizeKey,
    this.sizeLabel,
    this.sizeMl,
    required this.isSystem,
    required this.isHidden,
    required this.isActive,
  });

  String get displaySizeLabel => sizeLabel ?? name;

  factory ContainerTypeItem.fromJson(Map<String, dynamic> json) => ContainerTypeItem(
        id: json['id'] as int,
        name: json['name'] as String,
        kind: json['kind'] as String?,
        sizeKey: json['size_key'] as String?,
        sizeLabel: json['size_label'] as String?,
        sizeMl: json['size_ml'] as int?,
        isSystem: json['is_system'] as bool? ?? false,
        isHidden: json['is_hidden'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
      );
}

enum DocumentShareFormat { text, image, pdf }

class DocumentTemplateSettings {
  const DocumentTemplateSettings({
    required this.milkLogFormat,
    required this.billingFormat,
    required this.paymentReceiptFormat,
    required this.includeFarmHeader,
  });

  final DocumentShareFormat milkLogFormat;
  final DocumentShareFormat billingFormat;
  final DocumentShareFormat paymentReceiptFormat;
  final bool includeFarmHeader;

  factory DocumentTemplateSettings.fromJson(Map<String, dynamic> json) {
    return DocumentTemplateSettings(
      milkLogFormat: _parseFormat(json['milk_log_format']),
      billingFormat: _parseFormat(json['billing_format']),
      paymentReceiptFormat: _parseFormat(json['payment_receipt_format']),
      includeFarmHeader: json['include_farm_header'] as bool? ?? true,
    );
  }

  static DocumentShareFormat _parseFormat(Object? value) {
    if (value == 'text') return DocumentShareFormat.text;
    if (value == 'pdf') return DocumentShareFormat.pdf;
    return DocumentShareFormat.image;
  }

  static String _formatToApi(DocumentShareFormat format) {
    return switch (format) {
      DocumentShareFormat.text => 'text',
      DocumentShareFormat.pdf => 'pdf',
      DocumentShareFormat.image => 'image',
    };
  }

  Map<String, dynamic> toJson() => {
        'milk_log_format': _formatToApi(milkLogFormat),
        'billing_format': _formatToApi(billingFormat),
        'payment_receipt_format': _formatToApi(paymentReceiptFormat),
        'include_farm_header': includeFarmHeader,
      };

  DocumentShareFormat formatFor(CustomerShareDocument type) {
    return switch (type) {
      CustomerShareDocument.milkLog => milkLogFormat,
      CustomerShareDocument.billing => billingFormat,
      CustomerShareDocument.paymentReceipt => paymentReceiptFormat,
      CustomerShareDocument.subscriptionPlan => milkLogFormat,
    };
  }
}

enum CustomerShareDocument {
  subscriptionPlan,
  milkLog,
  billing,
  paymentReceipt,
}

// ── OR-07: Container type with grouped sizes ───────────────────────────────

/// Formats a litre value as a display label.
/// 0.5 → "500 ml", 1.0 → "1 L", 1.5 → "1.5 L"
String formatSizeLabel(double litres) {
  if (litres < 1.0) {
    final ml = (litres * 1000).round();
    return '$ml ml';
  }
  if (litres == litres.roundToDouble()) {
    return '${litres.toInt()} L';
  }
  return '$litres L';
}

/// Container type returned by the new OR-07 API:
/// GET /v1/owner/container-types → data.container_types[]
class OwnerContainerType {
  const OwnerContainerType({
    required this.id,
    required this.name,
    required this.isSystem,
    required this.isActive,
    required this.sizes,
  });

  final int id;
  final String name;
  final bool isSystem;
  final bool isActive;
  /// Sizes in litres, e.g. [0.5, 1.0].
  final List<double> sizes;

  /// Formatted size labels, e.g. ["500 ml", "1 L"].
  List<String> get sizeLabels => sizes.map(formatSizeLabel).toList();

  factory OwnerContainerType.fromJson(Map<String, dynamic> json) {
    final rawSizes = json['sizes'] as List<dynamic>? ?? [];
    return OwnerContainerType(
      id: json['id'] as int,
      name: json['name'] as String,
      isSystem: json['is_system'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      sizes: rawSizes.map((e) => (e as num).toDouble()).toList(),
    );
  }
}

// ── OR-08: Product with new API shape ─────────────────────────────────────

/// Product returned by the new OR-08 API:
/// GET /v1/owner/products → data.products[]
class OwnerProduct {
  const OwnerProduct({
    required this.id,
    required this.name,
    required this.milkType,
    required this.containerType,
    required this.rate,
  });

  final int id;
  final String name;
  final _ProductMilkType milkType;
  final _ProductContainerType containerType;
  final double rate;

  /// Subtitle line: "{milkType} · {containerType} · {sizes} · ₹{rate}/ltr"
  String get subtitleLine {
    final sizes = containerType.sizes.map(formatSizeLabel).join(', ');
    return '${milkType.name} · ${containerType.name} · $sizes · ₹${rate.toStringAsFixed(0)}/ltr';
  }

  /// Title line: auto-generated name from API, e.g. "Gir Cow - ₹80"
  String get titleLine => name;

  factory OwnerProduct.fromJson(Map<String, dynamic> json) {
    final rawMilkType = json['milk_type'];
    final rawContainerType = json['container_type'];
    return OwnerProduct(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      milkType: rawMilkType != null
          ? _ProductMilkType.fromJson(Map<String, dynamic>.from(rawMilkType as Map))
          : const _ProductMilkType(id: 0, name: ''),
      containerType: rawContainerType != null
          ? _ProductContainerType.fromJson(Map<String, dynamic>.from(rawContainerType as Map))
          : const _ProductContainerType(id: 0, name: '', sizes: []),
      rate: (json['rate'] as Object?) is String
          ? double.tryParse(json['rate'] as String) ?? 0
          : (json['rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class _ProductMilkType {
  const _ProductMilkType({required this.id, required this.name});
  final int id;
  final String name;
  factory _ProductMilkType.fromJson(Map<String, dynamic> json) =>
      _ProductMilkType(id: json['id'] as int, name: json['name'] as String);
}

class _ProductContainerType {
  const _ProductContainerType({
    required this.id,
    required this.name,
    required this.sizes,
  });
  final int id;
  final String name;
  final List<double> sizes;
  factory _ProductContainerType.fromJson(Map<String, dynamic> json) {
    final rawSizes = json['sizes'] as List<dynamic>? ?? [];
    return _ProductContainerType(
      id: json['id'] as int,
      name: json['name'] as String,
      sizes: rawSizes.map((e) => (e as num).toDouble()).toList(),
    );
  }
}

class OwnerSettingsUpdate {
  const OwnerSettingsUpdate({
    this.farm,
    this.owner,
    this.documentSettings,
  });

  final SettingsFarm? farm;
  final SettingsOwner? owner;
  final DocumentTemplateSettings? documentSettings;

  Map<String, dynamic> toJson() => {
        if (farm != null) 'farm': farm!.toUpdateJson(),
        if (owner != null) 'owner': owner!.toUpdateJson(),
        if (documentSettings != null) 'document_settings': documentSettings!.toJson(),
      };
}
