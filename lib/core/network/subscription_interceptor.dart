// Dio interceptor that listens for subscription signals from the Laravel
// CheckTenantSubscription middleware (T1-21) and updates the in-memory
// SubscriptionStatusNotifier accordingly.
//
// Behaviour on 2xx responses:
//   - If `subscription_warning` key is present in the response body, extract it
//     and call notifier.markGracePeriod().
//   - If no warning key is present, call notifier.markActive() so that a
//     previously-suspended screen is dismissed after payment.
//   - The response is never blocked — it always passes to the next handler.
//
// Behaviour on error responses:
//   - 403 with error == "SUBSCRIPTION_SUSPENDED": call notifier.markSuspended()
//     and re-throw a SubscriptionSuspendedException so the caller can react.
//   - All other errors pass through untouched.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subscription_status.dart';
import '../providers/subscription_status_provider.dart';

class SubscriptionInterceptor extends Interceptor {
  SubscriptionInterceptor(this._ref);

  final Ref _ref;

  SubscriptionStatusNotifier get _notifier =>
      _ref.read(subscriptionStatusProvider.notifier);

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final rawWarning = data['subscription_warning'];
      if (rawWarning is Map<String, dynamic>) {
        // Grace period: middleware injected warning payload alongside normal data.
        final warning = SubscriptionWarning.fromJson(rawWarning);
        _notifier.markGracePeriod(warning);
      } else {
        // Clean response — subscription is active (or just resumed).
        // Only clear a previously-signalled state so we don't thrash on every call.
        final current = _ref.read(subscriptionStatusProvider);
        if (current.status != SubscriptionStatus.active) {
          _notifier.markActive();
        }
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;

    if (statusCode == 403 &&
        data is Map<String, dynamic> &&
        data['error'] == 'SUBSCRIPTION_SUSPENDED') {
      final suspension = SubscriptionSuspension.fromJson(data);
      _notifier.markSuspended(suspension);

      // Re-throw as a typed exception so callers can react if needed.
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: SubscriptionSuspendedException(suspension),
        ),
      );
      return;
    }

    handler.next(err);
  }
}

/// Thrown (wrapped in a DioException) when the server responds with
/// 403 SUBSCRIPTION_SUSPENDED.  Callers can catch this specifically;
/// most callers will simply see a DioException and display a generic error,
/// which is fine because the suspended screen is shown globally via
/// ref.listen in the root widget.
class SubscriptionSuspendedException implements Exception {
  const SubscriptionSuspendedException(this.suspension);

  final SubscriptionSuspension suspension;

  @override
  String toString() => 'SubscriptionSuspendedException: subscription is suspended';
}
