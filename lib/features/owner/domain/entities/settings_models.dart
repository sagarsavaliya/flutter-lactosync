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

  factory SettingsProduct.fromJson(Map<String, dynamic> json) {
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
  final bool isSystem;
  final bool isHidden;
  final bool isActive;
  const ContainerTypeItem({
    required this.id,
    required this.name,
    required this.isSystem,
    required this.isHidden,
    required this.isActive,
  });
  factory ContainerTypeItem.fromJson(Map<String, dynamic> json) => ContainerTypeItem(
        id: json['id'] as int,
        name: json['name'] as String,
        isSystem: json['is_system'] as bool? ?? false,
        isHidden: json['is_hidden'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
      );
}

enum DocumentShareFormat { text, image }

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
    return DocumentShareFormat.image;
  }

  Map<String, dynamic> toJson() => {
        'milk_log_format': milkLogFormat == DocumentShareFormat.text ? 'text' : 'image',
        'billing_format': billingFormat == DocumentShareFormat.text ? 'text' : 'image',
        'payment_receipt_format':
            paymentReceiptFormat == DocumentShareFormat.text ? 'text' : 'image',
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
