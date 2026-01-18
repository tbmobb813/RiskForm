import '../../models/backtest/backtest_config.dart';

/// Generate deterministic price paths for a simple parameter sweep.
List<BacktestConfig> generateSweepConfigs({
  required BacktestConfig base,
  required List<double> drifts,
  int length = 252,
}) {
  final out = <BacktestConfig>[];
  final basePrice = base.pricePath.isNotEmpty ? base.pricePath.first : 100.0;

  for (final drift in drifts) {
    final prices = <double>[];
    double p = basePrice;
    for (var i = 0; i < length; i++) {
      prices.add(p);
      p = p * (1 + drift); // deterministic trend per step
    }

    out.add(base.copyWith(pricePath: prices));
  }

  return out;
}
