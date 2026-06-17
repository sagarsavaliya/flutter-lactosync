import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeliveryBoySession {
  const DeliveryBoySession({
    this.shift = 'morning',
    this.cartChecked = false,
    this.routeStarted = false,
    this.cashHandedOver = false,
  });

  final String shift;
  final bool cartChecked;
  final bool routeStarted;
  final bool cashHandedOver;

  DeliveryBoySession copyWith({
    String? shift,
    bool? cartChecked,
    bool? routeStarted,
    bool? cashHandedOver,
  }) {
    return DeliveryBoySession(
      shift: shift ?? this.shift,
      cartChecked: cartChecked ?? this.cartChecked,
      routeStarted: routeStarted ?? this.routeStarted,
      cashHandedOver: cashHandedOver ?? this.cashHandedOver,
    );
  }
}

class DeliveryBoySessionNotifier extends Notifier<DeliveryBoySession> {
  @override
  DeliveryBoySession build() => const DeliveryBoySession();

  void setShift(String shift) => state = state.copyWith(shift: shift);

  void toggleCartChecked(bool value) => state = state.copyWith(cartChecked: value);

  void startRoute() => state = state.copyWith(routeStarted: true);

  void handOverCash() => state = state.copyWith(cashHandedOver: true);

  void resetForNewDay() => state = const DeliveryBoySession();
}

final deliveryBoySessionProvider =
    NotifierProvider<DeliveryBoySessionNotifier, DeliveryBoySession>(
  DeliveryBoySessionNotifier.new,
);
