import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_typography.dart';
import '../theme/redesign_tokens.dart';

/// Frame 7 section header — customer add/edit forms.
class CustomerFormSectionHeader extends StatelessWidget {
  const CustomerFormSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 11),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: RedesignTokens.accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: RedesignTokens.accent),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: AppText.cardTitle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: RedesignTokens.ink,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Frame 7 import-from-contacts chip.
class CustomerFormImportChip extends StatelessWidget {
  const CustomerFormImportChip({super.key, required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RedesignTokens.accentLight,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: RedesignTokens.accentBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(LucideIcons.contact, size: 14, color: RedesignTokens.accent),
              const SizedBox(width: 6),
              Text(
                'Import',
                style: AppText.meta.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: RedesignTokens.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// All Indian states and union territories for the State dropdown.
const kIndianStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  'Andaman and Nicobar Islands',
  'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Jammu and Kashmir',
  'Ladakh',
  'Lakshadweep',
  'Puducherry',
];

/// Prefills empty city / PIN / state from farm settings when OR-10 toggle is on.
String? applyFarmAddressPrefill({
  required bool enabled,
  String? farmCity,
  String? farmState,
  String? farmZip,
  required TextEditingController cityController,
  required TextEditingController zipController,
  String? selectedState,
}) {
  if (!enabled) return selectedState;
  if (cityController.text.trim().isEmpty && (farmCity ?? '').trim().isNotEmpty) {
    cityController.text = farmCity!.trim();
  }
  if (zipController.text.trim().isEmpty && (farmZip ?? '').trim().isNotEmpty) {
    zipController.text = farmZip!.trim();
  }
  if ((selectedState ?? '').trim().isEmpty && (farmState ?? '').trim().isNotEmpty) {
    return farmState!.trim();
  }
  return selectedState;
}

/// Onboarding progress — frame 7 "Step 1 of 2".
class CustomerFormStepProgress extends StatelessWidget {
  const CustomerFormStepProgress({super.key, this.step = 1, this.total = 2});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 14),
      child: Row(
        children: [
          for (var i = 1; i <= total; i++) ...[
            if (i > 1) const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step ? RedesignTokens.accent : const Color(0xFFD7DECE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),
          Text(
            'Step $step of $total',
            style: AppText.meta.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: RedesignTokens.labelMuted,
            ),
          ),
        ],
      ),
    );
  }
}
