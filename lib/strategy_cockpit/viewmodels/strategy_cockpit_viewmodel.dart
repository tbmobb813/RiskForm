import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/strategy.dart';
import '../../models/strategy_health_snapshot.dart';
import '../../services/strategy/strategy_service.dart' as strategy_service;
import '../services/strategy_health_service.dart';
import '../services/strategy_backtest_service.dart';
import '../../regime/regime_service.dart';
import '../analytics/strategy_recommendations_engine.dart';

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
  StrategyRecommendationsBundle? recommendations;

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
          _maybeGenerateRecommendations();
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
        _maybeGenerateRecommendations();
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
        _maybeGenerateRecommendations();
        _setLoaded();
      },
      onError: (_) => _setError(),
    );
  }

  void _maybeGenerateRecommendations() {
    // Require health + strategy + regime to generate meaningful recommendations.
    if (health == null || strategy == null || currentRegime == null) return;

    final healthScore = (health!.healthScore ?? 50).toInt();

    final pnlTrend = List<double>.from(health!.pnlTrend);

    // Convert discipline trend to ints [0..100]
    final disciplineTrend = health!.disciplineTrend.map((d) => d.round()).toList();

    // Recent cycles: map last up to 5 summaries to CycleSummary
    final cycleMaps = health!.cycleSummaries;
    final recent = <CycleSummary>[];
    for (var i = cycleMaps.length - 1; i >= 0 && recent.length < 5; i--) {
      final m = cycleMaps[i];
      final ds = (m['disciplineScore'] is num) ? (m['disciplineScore'] as num).toInt() : 50;
      final pnl = (m['pnl'] is num) ? (m['pnl'] as num).toDouble() : 0.0;
      final r = (m['regime'] is String) ? m['regime'] as String : currentRegime!;
      recent.add(CycleSummary(disciplineScore: ds, pnl: pnl, regime: r));
    }

    // Backtest summary
    final backtest = latestBacktest == null
        ? null
        : BacktestSummary(bestConfig: latestBacktest, weakConfig: null, summaryNote: null);

    // Constraints -> map to engine Constraints
    final c = strategy!.constraints;
    final constraints = Constraints(
      maxRisk: (c['maxRisk'] is int) ? c['maxRisk'] as int : 100,
      maxPositions: (c['maxPositions'] is int) ? c['maxPositions'] as int : 10,
      allowedDteRange: c['allowedDteRange'] is List ? List<int>.from(c['allowedDteRange']) : null,
      allowedDeltaRange: c['allowedDeltaRange'] is List ? List<double>.from(c['allowedDeltaRange'].map((v) => (v as num).toDouble())) : null,
    );

    // Compute drawdown from pnlTrend
    double drawdown = 0.0;
    if (pnlTrend.isNotEmpty) {
      double peak = double.negativeInfinity;
      double equity = 0.0;
      double maxDd = 0.0;
      for (final p in pnlTrend) {
        equity += p;
        if (equity > peak) peak = equity;
        final dd = peak - equity;
        if (dd > maxDd) maxDd = dd;
      }
      drawdown = maxDd;
    }

    final ctx = StrategyContext(
      healthScore: healthScore,
      pnlTrend: pnlTrend,
      disciplineTrend: disciplineTrend,
      recentCycles: recent,
      constraints: constraints,
      currentRegime: currentRegime ?? 'unknown',
      drawdown: drawdown,
      backtestComparison: backtest,
    );

    recommendations = generateRecommendations(ctx);
    notifyListeners();
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

// Note: we use Strategy.fromMap to construct models from Map data
