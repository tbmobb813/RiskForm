import 'package:flutter_riverpod/legacy.dart';
import 'package:riskform/strategy_cockpit/strategies/trading_strategy.dart';
import 'package:riskform/strategy_cockpit/strategies/payoff_point.dart';
import 'package:riskform/strategy_cockpit/strategies/persistence/persisted_strategy.dart';
import 'package:riskform/strategy_cockpit/strategies/persistence/strategy_persistence_service.dart';
import 'package:riskform/strategy_cockpit/strategies/persistence/strategy_factory.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AccountMode { smallAccount, wheel }

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
  StrategyController() : super(const StrategyState(mode: AccountMode.smallAccount, strategy: null)) {
    _loadPersistedStrategy();
  }

  void setMode(AccountMode mode) => state = state.copyWith(mode: mode);

  /// Normal API to set the active strategy. This does not persist by itself;
  /// persistence is handled externally by a provider listener so we avoid
  /// coupling the controller to Riverpod internals.
  void setStrategy(TradingStrategy strategy) {
    state = state.copyWith(strategy: strategy);
    _saveStrategy(strategy);
  }

  /// Internal helper used when restoring state from persistence to avoid
  /// triggering persistence listeners.
  void setStrategySilently(TradingStrategy strategy) => state = state.copyWith(strategy: strategy);

  void clearStrategy() => state = state.copyWith(strategy: null);

  Future<void> _loadPersistedStrategy() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final persisted = await StrategyPersistenceService().loadStrategy(uid);
      if (persisted == null) return;

      final s = StrategyFactory.fromPersisted(persisted);
      if (s is TradingStrategy) setStrategySilently(s);
    } catch (_) {}
  }

  Future<void> _saveStrategy(TradingStrategy strategy) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final persisted = PersistedStrategy(type: strategy.typeId, data: strategy.toJson());
      await StrategyPersistenceService().saveStrategy(uid: uid, strategy: persisted);
    } catch (_) {}
  }

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
  final controller = StrategyController();

  return controller;
});
