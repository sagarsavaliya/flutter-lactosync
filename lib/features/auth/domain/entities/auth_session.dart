class OnboardingState {
  const OnboardingState({
    required this.currentStep,
    required this.route,
    required this.isCompleted,
    required this.checklist,
  });

  final String currentStep;
  final String route;
  final bool isCompleted;
  final Map<String, bool> checklist;

  factory OnboardingState.fromJson(Map<String, dynamic> json) {
    final checklistRaw = Map<String, dynamic>.from(json['checklist'] as Map? ?? {});
    return OnboardingState(
      currentStep: json['current_step'] as String? ?? 'farm_profile',
      route: json['route'] as String? ?? '/onboarding/farm',
      isCompleted: json['is_completed'] as bool? ?? false,
      checklist: checklistRaw.map((k, v) => MapEntry(k, v == true)),
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.ownerName,
    required this.firstName,
    required this.lastName,
    required this.mobile,
    required this.farmId,
    required this.farmName,
    required this.onboarding,
  });

  final String token;
  final String ownerName;
  final String firstName;
  final String lastName;
  final String mobile;
  final int farmId;
  final String farmName;
  final OnboardingState onboarding;

  String get onboardingRoute => onboarding.route;
}
