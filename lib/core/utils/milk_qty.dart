/// Standard milk quantity presets in litres (0 = skip / no delivery).
const List<double> kMilkQtyStepperOptions = [
  0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0,
  5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0,
];

/// Subscription dropdown options (no zero).
const List<double> kMilkQtyOptions = [
  0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0,
  5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0,
];

String milkQtyLabel(double litres) {
  if (litres <= 0) return '0 ml';
  if (litres < 1) return '${(litres * 1000).round()} ml';
  if (litres == litres.roundToDouble()) return '${litres.toInt()} L';
  return '$litres L';
}

double nearestMilkQty(double value, {bool allowZero = false}) {
  final options = allowZero ? kMilkQtyStepperOptions : kMilkQtyOptions;
  if (value <= 0) return allowZero ? 0.0 : options.first;
  var best = options.first;
  var diff = (value - best).abs();
  for (final option in options) {
    final d = (value - option).abs();
    if (d < diff) {
      best = option;
      diff = d;
    }
  }
  return best;
}

int _indexForQty(double quantity) {
  var index = kMilkQtyStepperOptions.indexWhere((v) => (v - quantity).abs() < 0.01);
  if (index >= 0) return index;
  index = 0;
  for (var i = 0; i < kMilkQtyStepperOptions.length; i++) {
    if ((kMilkQtyStepperOptions[i] - quantity).abs() <
        (kMilkQtyStepperOptions[index] - quantity).abs()) {
      index = i;
    }
  }
  return index;
}

/// Steps through [kMilkQtyStepperOptions] by [direction] (−1 or +1).
double stepMilkQty(double quantity, int direction) {
  final index = _indexForQty(quantity);
  final next = (index + direction).clamp(0, kMilkQtyStepperOptions.length - 1);
  return kMilkQtyStepperOptions[next];
}

bool milkQtysEqual(double a, double b) => (a - b).abs() < 0.01;
