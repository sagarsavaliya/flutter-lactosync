// Domain model for the tenant's SaaS subscription status as signalled by the
// Laravel CheckTenantSubscription middleware (T1-21).
//
// The interceptor (lib/core/network/subscription_interceptor.dart) populates
// SubscriptionStatusNotifier at runtime; nothing here is persisted.

enum SubscriptionStatus {
  /// Paid-up — no banner, no gate.
  active,

  /// Overdue but within the 5-day grace window.
  /// API returns 2xx + `subscription_warning` key.
  gracePeriod,

  /// Grace period expired — API returns 403 SUBSCRIPTION_SUSPENDED.
  suspended,

  /// Plan manually paused by the admin (future use).
  paused,

  /// No plan assigned yet (future use).
  noPlan,
}

/// Payload attached to a `gracePeriod` state.
class SubscriptionWarning {
  const SubscriptionWarning({
    required this.status,
    required this.daysOverdue,
    required this.graceDaysRemaining,
    required this.dueDate,
  });

  final SubscriptionStatus status;
  final int daysOverdue;
  final int graceDaysRemaining;

  /// ISO 8601 date string, e.g. "2026-06-01".
  final String dueDate;

  factory SubscriptionWarning.fromJson(Map<String, dynamic> json) {
    return SubscriptionWarning(
      status: _parseStatus(json['status'] as String? ?? ''),
      daysOverdue: (json['days_overdue'] as num?)?.toInt() ?? 0,
      graceDaysRemaining: (json['grace_days_remaining'] as num?)?.toInt() ?? 0,
      dueDate: json['due_date'] as String? ?? '',
    );
  }

  static SubscriptionStatus _parseStatus(String raw) {
    return switch (raw) {
      'PAYMENT_OVERDUE' => SubscriptionStatus.gracePeriod,
      'SUBSCRIPTION_SUSPENDED' => SubscriptionStatus.suspended,
      _ => SubscriptionStatus.active,
    };
  }
}

/// Payload attached to a `suspended` state.
class SubscriptionSuspension {
  const SubscriptionSuspension({
    required this.dueDate,
    required this.suspendedAt,
    this.message,
  });

  /// ISO 8601 date string for the original due date.
  final String dueDate;

  /// ISO 8601 timestamp when suspension took effect.
  final String suspendedAt;

  final String? message;

  factory SubscriptionSuspension.fromJson(Map<String, dynamic> json) {
    return SubscriptionSuspension(
      dueDate: json['due_date'] as String? ?? '',
      suspendedAt: json['suspended_at'] as String? ?? '',
      message: json['message'] as String?,
    );
  }
}
