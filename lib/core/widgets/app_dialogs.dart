import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: AppText.sectionTitle),
      content: Text(message, style: AppText.body),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: cancelLabel,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: AppButton(
                label: confirmLabel,
                variant: destructive ? AppButtonVariant.destructive : AppButtonVariant.primary,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Single helper for all modal dialogs — consistent shape/padding/dismiss behavior.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  String? confirmLabel,
  String? cancelLabel,
  VoidCallback? onConfirm,
  bool barrierDismissible = true,
  bool destructive = false,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: AppText.sectionTitle),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.lg,
      ),
      content: content,
      actionsPadding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
      actions: [
        if (cancelLabel != null || confirmLabel != null)
          Row(
            children: [
              if (cancelLabel != null)
                Expanded(
                  child: AppButton(
                    label: cancelLabel,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              if (cancelLabel != null && confirmLabel != null) const SizedBox(width: AppSpace.sm),
              if (confirmLabel != null)
                Expanded(
                  child: AppButton(
                    label: confirmLabel,
                    variant: destructive ? AppButtonVariant.destructive : AppButtonVariant.primary,
                    onPressed: () {
                      onConfirm?.call();
                      Navigator.of(ctx).pop(true);
                    },
                  ),
                ),
            ],
          ),
      ],
    ),
  );
}

// Convenience: simple message dialog with a single OK action.
Future<void> showAppAlert({
  required BuildContext context,
  required String title,
  required String message,
}) {
  return showAppDialog(
    context: context,
    title: title,
    content: Text(message, style: AppText.body),
    confirmLabel: 'OK',
  );
}
