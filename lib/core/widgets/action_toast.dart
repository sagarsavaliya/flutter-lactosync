import 'package:flutter/material.dart';

import 'app_snackbar.dart';

/// Short-lived status toasts for multi-step owner actions.
class ActionToast {
  static void show(
    BuildContext context,
    String message, {
    Duration? duration,
    bool defer = false,
  }) {
    AppSnackBar.show(context, message, duration: duration, defer: defer);
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
