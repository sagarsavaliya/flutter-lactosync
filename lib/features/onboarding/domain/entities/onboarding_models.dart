class OnboardingStatus {
  const OnboardingStatus({
    required this.currentStep,
    required this.isCompleted,
    required this.checklist,
    required this.farm,
    required this.counts,
  });

  final String currentStep;
  final bool isCompleted;
  final Map<String, bool> checklist;
  final FarmProfile farm;
  final Map<String, int> counts;

  factory OnboardingStatus.fromJson(Map<String, dynamic> json) {
    final checklistRaw = Map<String, dynamic>.from(json['checklist'] as Map? ?? {});
    final countsRaw = Map<String, dynamic>.from(json['counts'] as Map? ?? {});
    return OnboardingStatus(
      currentStep: json['current_step'] as String,
      isCompleted: json['is_completed'] as bool? ?? false,
      checklist: checklistRaw.map((k, v) => MapEntry(k, v == true)),
      farm: FarmProfile.fromJson(Map<String, dynamic>.from(json['farm'] as Map)),
      counts: countsRaw.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }
}

class FarmProfile {
  const FarmProfile({
    required this.id,
    this.name,
    this.addressLine,
    this.city,
    this.state,
    this.zip,
  });

  final int id;
  final String? name;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? zip;

  factory FarmProfile.fromJson(Map<String, dynamic> json) {
    return FarmProfile(
      id: json['id'] as int,
      name: json['name'] as String?,
      addressLine: json['address_line'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      zip: json['zip'] as String?,
    );
  }
}

class ProductItem {
  const ProductItem({
    required this.id,
    required this.name,
    required this.milkType,
    required this.milkTypeLabel,
    required this.rate,
    required this.unit,
    required this.containerType,
    required this.containerTypeLabel,
  });

  final int id;
  final String name;
  final String milkType;
  final String milkTypeLabel;
  final double rate;
  final String unit;
  final String containerType;
  final String containerTypeLabel;

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] as int,
      name: json['name'] as String,
      milkType: json['milk_type'] as String,
      milkTypeLabel: json['milk_type_label'] as String,
      rate: (json['rate'] as num).toDouble(),
      unit: json['unit'] as String,
      containerType: json['container_type'] as String,
      containerTypeLabel: json['container_type_label'] as String,
    );
  }
}

class CustomerItem {
  const CustomerItem({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.contact,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String contact;

  factory CustomerItem.fromJson(Map<String, dynamic> json) {
    return CustomerItem(
      id: json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      fullName: json['full_name'] as String,
      contact: json['contact'] as String,
    );
  }
}
