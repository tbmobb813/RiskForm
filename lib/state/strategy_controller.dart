import 'package:flutter_riverpod/legacy.dart';
import 'package:riskform/strategy_cockpit/strategies/trading_strategy.dart';
import 'package:riskform/strategy_cockpit/strategies/payoff_point.dart';

enum AccountMode {
  smallAccount,
  wheel,
}

class StrategyState {
  final AccountMode mode;
  final TradingStrategy? strategy;

  const StrategyState({required this.mode, required this.strategy});

  StrategyState copyWith({AccountMode? mode, TradingStrategy? strategy}) {
    return StrategyState(
      mode: mode ?? this.mode,
      strategy: strategy ?? this.strategy,
    );
  }
}

class StrategyController extends StateNotifier<StrategyState> {
  StrategyController() : super(const StrategyState(mode: AccountMode.smallAccount, strategy: null));

  void setMode(AccountMode mode) => state = state.copyWith(mode: mode);

  void setStrategy(TradingStrategy strategy) => state = state.copyWith(strategy: strategy);

  void clearStrategy() => state = state.copyWith(strategy: null);

  double? get maxRisk => state.strategy?.maxRisk;
  double? get maxProfit => state.strategy?.maxProfit;
  double? get breakeven => state.strategy?.breakeven;

  List<PayoffPoint>? payoffCurve({
    required double underlyingPrice,
    double rangePercent = 0.3,
    int steps = 50,
  }) {
    final s = state.strategy;
    if (s == null) return null;

    return s.payoffCurve(
      underlyingPrice: underlyingPrice,
      rangePercent: rangePercent,
      steps: steps,
    );
  }
}

final strategyControllerProvider = StateNotifierProvider<StrategyController, StrategyState>((ref) {
  return StrategyController();
});
