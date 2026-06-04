import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

// Wraps TextFormField with a label above (token-sized) and consistent styling.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixText,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.showLabel = true,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final String? errorText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final String? suffixText;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final int? maxLines;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(label, style: AppText.label.copyWith(color: AppColors.inkMuted)),
          const SizedBox(height: AppSpace.xs),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          validator: validator,
          enabled: enabled,
          maxLines: maxLines,
          style: AppText.body,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixText != null
                ? Padding(
                    padding: const EdgeInsets.only(right: AppSpace.sm),
                    child: Text(
                      suffixText!,
                      style: AppText.label.copyWith(color: AppColors.inkMuted),
                    ),
                  )
                : suffixIcon != null
                    ? IconButton(
                        icon: Icon(suffixIcon),
                        onPressed: onSuffixTap,
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
          ),
        ),
      ],
    );
  }
}
