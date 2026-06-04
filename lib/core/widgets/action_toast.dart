import 'package:flutter/material.dart';

/// Short-lived status toasts for multi-step owner actions.
class ActionToast {
  static void show(BuildContext context, String message, {Duration? duration}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration ?? const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  static Future<T> run<T>(
    BuildContext context, {
    required Future<T> Function() task,
    required String preparing,
    required String success,
    String? onError,
  }) async {
    show(context, preparing, duration: const Duration(seconds: 30));
    try {
      final result = await task();
      if (context.mounted) show(context, success);
      return result;
    } catch (e) {
      if (context.mounted) {
        show(context, onError ?? 'Something went wrong. Please try again.');
      }
      rethrow;
    }
  }
}
