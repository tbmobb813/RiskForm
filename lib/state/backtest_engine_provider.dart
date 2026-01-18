import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/engines/backtest_engine.dart';
import '../services/engines/payoff_engine.dart';
import '../services/engines/risk_engine.dart';
import '../state/meta_strategy_provider.dart';

final backtestEngineProvider = Provider<BacktestEngine>((ref) {
  return BacktestEngine(
    payoffEngine: ref.read(payoffEngineProvider),
    riskEngine: ref.read(riskEngineProvider),
    metaStrategy: ref.read(metaStrategyControllerProvider),
  );
});
