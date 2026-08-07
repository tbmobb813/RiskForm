import '../analytics/market_regime.dart';

/// Display-only context describing which historical regime window a backtest
/// is replaying. Kept separate from `BacktestConfig` (defined in the shared
/// `riskform_core` package) so this feature doesn't need to touch that
/// package.
class RegimeReplayContext {
  final MarketRegime regime;
  final String symbol;
  final DateTime startDate;
  final DateTime endDate;

  const RegimeReplayContext({
    required this.regime,
    required this.symbol,
    required this.startDate,
    required this.endDate,
  });
}
