// Riverpod state for the tenant's current SaaS subscription status.
//
// This is pure in-memory state — nothing is persisted. The
// SubscriptionInterceptor writes to this notifier as API responses arrive.
// UI layers read from it to decide whether to show the warning banner or push
// the suspended screen.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subscription_status.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class SubscriptionState {
  const SubscriptionState({
    this.status = SubscriptionStatus.active,
    this.warning,
    this.suspension,
  });

  final SubscriptionStatus status;

  /// Populated when [status] is [SubscriptionStatus.gracePeriod].
  final SubscriptionWarning? warning;

  /// Populated when [status] is [SubscriptionStatus.suspended].
  final SubscriptionSuspension? suspension;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    SubscriptionWarning? warning,
    SubscriptionSuspension? suspension,
    bool clearWarning = false,
    bool clearSuspension = false,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      warning: clearWarning ? null : (warning ?? this.warning),
      suspension: clearSuspension ? null : (suspension ?? this.suspension),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SubscriptionStatusNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionStatusNotifier() : super(const SubscriptionState());

  /// Called by the interceptor when a response includes `subscription_warning`.
  void markGracePeriod(SubscriptionWarning warning) {
    state = state.copyWith(
      status: SubscriptionStatus.gracePeriod,
      warning: warning,
      clearSuspension: true,
    );
  }

  /// Called by the interceptor when a 403 SUBSCRIPTION_SUSPENDED is received.
  void markSuspended(SubscriptionSuspension suspension) {
    state = state.copyWith(
      status: SubscriptionStatus.suspended,
      suspension: suspension,
      clearWarning: true,
    );
  }

  /// Called when a subsequent request succeeds without a warning or 403 —
  /// meaning the admin has re-activated the subscription.
  void markActive() {
    state = const SubscriptionState();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final subscriptionStatusProvider =
    StateNotifierProvider<SubscriptionStatusNotifier, SubscriptionState>(
  (ref) => SubscriptionStatusNotifier(),
);
