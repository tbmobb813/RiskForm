import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/strategy.dart';
import '../../models/strategy_health_snapshot.dart';
import '../../services/strategy/strategy_service.dart';
import '../services/strategy_health_service.dart';
import '../services/strategy_backtest_service.dart';
import '../../regime/regime_service.dart';

class StrategyCockpitViewModel extends ChangeNotifier {
  final StrategyService _strategyService;
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
    StrategyService? strategyService,
    StrategyHealthService? healthService,
    StrategyBacktestService? backtestService,
    RegimeService? regimeService,
  })  : _strategyService = strategyService ?? StrategyService(),
        _healthService = healthService ?? StrategyHealthService(),
        _backtestService = backtestService ?? StrategyBacktestService(),
        _regimeService = regimeService ?? RegimeService() {
    _init();
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
        strategy = Strategy.fromFirestore(
          _wrapDoc(strategyId, data),
        );
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

  // Firestore doc wrapper for model parsing
  DocumentSnapshot _wrapDoc(String id, Map<String, dynamic> data) {
    return _FakeDoc(id, data);
  }

  // -----------------------------
  // Lifecycle Actions
  // -----------------------------
  Future<void> pauseStrategy({String? reason}) async {
    await _strategyService.changeStrategyState(
      strategyId: strategyId,
      nextState: StrategyState.paused,
      reason: reason,
    );
  }

  Future<void> resumeStrategy({String? reason}) async {
    await _strategyService.changeStrategyState(
      strategyId: strategyId,
      nextState: StrategyState.active,
      reason: reason,
    );
  }

  Future<void> retireStrategy({String? reason}) async {
    await _strategyService.changeStrategyState(
      strategyId: strategyId,
      nextState: StrategyState.retired,
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

// --------------------------------------------------
// Internal helper class to wrap Firestore data
// --------------------------------------------------
class _FakeDoc implements DocumentSnapshot {
  @override
  final String id;

  final Map<String, dynamic> _data;

  _FakeDoc(this.id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  // Unused members required by interface
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
