import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/strategy.dart';
import '../../models/strategy_health_snapshot.dart';
import '../../services/strategy/strategy_service.dart' as strategy_service;
import '../services/strategy_health_service.dart';
import '../services/strategy_backtest_service.dart';
import '../../regime/regime_service.dart';

class StrategyCockpitViewModel extends ChangeNotifier {
  final strategy_service.StrategyService _strategyService;
  final StrategyHealthService _healthService;
  final StrategyBacktestService _backtestService;
  final RegimeService _regimeService;

  final String strategyId;

  Strategy? strategy;
  StrategyHealthSnapshot? health;
  Map<String, dynamic>? latestBacktest;
  String? currentRegime;

  bool isLoading = true;
  bool hasError = false;

  StreamSubscription? _strategySub;
  StreamSubscription? _healthSub;
  StreamSubscription? _backtestSub;
  StreamSubscription? _regimeSub;

  StrategyCockpitViewModel({
    required this.strategyId,
    strategy_service.StrategyService? strategyService,
    StrategyHealthService? healthService,
    StrategyBacktestService? backtestService,
    RegimeService? regimeService,
  })  : _strategyService = strategyService ?? strategy_service.StrategyService(),
        _healthService = healthService ?? StrategyHealthService(),
        _backtestService = backtestService ?? StrategyBacktestService(),
        _regimeService = regimeService ?? RegimeService() {
    // Initialize listeners asynchronously so `isLoading` remains true
    // for the first build frame. This ensures widgets can show a
    // loading indicator before synchronous stream emits occur.
    Future.microtask(_init);
  }

  // -----------------------------
  // Initialization
  // -----------------------------
  void _init() {
    _listenToStrategy();
    _listenToHealth();
    _listenToBacktests();
    _listenToRegime();
  }

  // -----------------------------
  // Strategy Document
  // -----------------------------
  void _listenToStrategy() {
    _strategySub = _strategyService.watchStrategy(strategyId).listen(
      (data) {
        if (data == null) return;
        strategy = Strategy.fromMap(strategyId, data);
        _setLoaded();
      },
      onError: (_) => _setError(),
    );
  }

  // -----------------------------
  // Strategy Health Snapshot
  // -----------------------------
  void _listenToHealth() {
    _healthSub = _healthService.watchHealth(strategyId).listen(
      (snapshot) {
        if (snapshot != null) {
          health = snapshot;
        }
        _setLoaded();
      },
      onError: (_) => _setError(),
    );
  }

  // -----------------------------
  // Latest Backtest
  // -----------------------------
  void _listenToBacktests() {
    _backtestSub = _backtestService.watchLatestBacktest(strategyId).listen(
      (data) {
        latestBacktest = data;
        _setLoaded();
      },
      onError: (_) => _setError(),
    );
  }

  // -----------------------------
  // Current Regime
  // -----------------------------
  void _listenToRegime() {
    _regimeSub = _regimeService.watchCurrentRegime().listen(
      (regime) {
        currentRegime = regime;
        _setLoaded();
      },
      onError: (_) => _setError(),
    );
  }

  // -----------------------------
  // Helpers
  // -----------------------------
  void _setLoaded() {
    if (isLoading) {
      isLoading = false;
    }
    notifyListeners();
  }

  void _setError() {
    hasError = true;
    isLoading = false;
    notifyListeners();
  }

  // -----------------------------
  // Lifecycle Actions
  // -----------------------------
  Future<void> pauseStrategy({String? reason}) async {
    await _strategyService.changeStrategyState(
      strategyId: strategyId,
      nextState: strategy_service.StrategyState.paused,
      reason: reason,
    );
  }

  Future<void> resumeStrategy({String? reason}) async {
    await _strategyService.changeStrategyState(
      strategyId: strategyId,
      nextState: strategy_service.StrategyState.active,
      reason: reason,
    );
  }

  Future<void> retireStrategy({String? reason}) async {
    await _strategyService.changeStrategyState(
      strategyId: strategyId,
      nextState: strategy_service.StrategyState.retired,
      reason: reason,
    );
  }

  // -----------------------------
  // Cleanup
  // -----------------------------
  @override
  void dispose() {
    _strategySub?.cancel();
    _healthSub?.cancel();
    _backtestSub?.cancel();
    _regimeSub?.cancel();
    super.dispose();
  }
}

// Note: we use Strategy.fromMap to construct models from Map data
