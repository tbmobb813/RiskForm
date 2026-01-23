import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/strategy.dart';
import '../../models/strategy_health_snapshot.dart';
import '../../services/strategy/strategy_service.dart' as strategy_service;
import '../services/strategy_health_service.dart';
import '../services/strategy_backtest_service.dart';
import '../../regime/regime_service.dart';
import '../analytics/strategy_recommendations_engine.dart';
import '../analytics/strategy_narrative_engine.dart';
import 'package:riskform/services/market_data_service.dart';
import '../live_sync_manager.dart';


class StrategyCockpitViewModel extends ChangeNotifier {
  final strategy_service.StrategyService _strategyService;
  final StrategyHealthService _healthService;
  final StrategyBacktestService _backtestService;
  final RegimeService _regimeService;
  final MarketDataService? _marketDataService;
  final StrategyRecommendationsEngine? _recsEngine;
  final StrategyNarrativeEngine? _narrativeEngine;
  final LiveSyncManager? _liveSyncManager;

  final String strategyId;

  Strategy? strategy;
  StrategyHealthSnapshot? health;
  Map<String, dynamic>? latestBacktest;
  String? currentRegime;
  StrategyRecommendationsBundle? recommendations;
  StrategyNarrative? narrative;

  bool isLoading = true;
  bool hasError = false;

  StreamSubscription? _strategySub;
  StreamSubscription? _healthSub;
  StreamSubscription? _backtestSub;
  StreamSubscription? _regimeSub;

  // Cancellation-token mechanism for in-flight async callbacks. Each async
  // generation flow obtains a token via `_beginAsyncCallback()` and must
  // call `_endAsyncCallback(token)` when complete. `dispose()` clears all
  // active tokens so outstanding callbacks will early-return when they try
  // to update state or call `notifyListeners()`.
  int _nextCallbackToken = 0;
  final Set<int> _activeCallbackTokens = <int>{};

  int _beginAsyncCallback() {
    final t = _nextCallbackToken++;
    _activeCallbackTokens.add(t);
    return t;
  }

  void _endAsyncCallback(int t) {
    _activeCallbackTokens.remove(t);
  }

  StrategyCockpitViewModel({
    required this.strategyId,
    strategy_service.StrategyService? strategyService,
    StrategyHealthService? healthService,
    StrategyBacktestService? backtestService,
    RegimeService? regimeService,
    MarketDataService? marketDataService,
    StrategyRecommendationsEngine? recsEngine,
    StrategyNarrativeEngine? narrativeEngine,
    LiveSyncManager? liveSyncManager,
  })  : _strategyService = strategyService ?? strategy_service.StrategyService(),
        _healthService = healthService ?? StrategyHealthService(),
        _backtestService = backtestService ?? StrategyBacktestService(),
        _regimeService = regimeService ?? RegimeService(),
        _marketDataService = marketDataService,
        _recsEngine = recsEngine,
      _narrativeEngine = narrativeEngine ?? const StrategyNarrativeEngine(),
      _liveSyncManager = liveSyncManager {
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
    final healthLocal = health!;
    final strategyLocal = strategy!;
    final currentRegimeLocal = currentRegime!;

    final healthScore = (healthLocal.healthScore ?? 50).toInt();

    final pnlTrend = List<double>.from(healthLocal.pnlTrend);

    // Convert discipline trend to ints [0..100]
    final disciplineTrend = healthLocal.disciplineTrend.map((d) => d.round()).toList();

    // Recent cycles: map last up to 5 summaries to CycleSummary
    final cycleMaps = healthLocal.cycleSummaries;
    final recent = <CycleSummary>[];
    for (var i = cycleMaps.length - 1; i >= 0 && recent.length < 5; i--) {
      final m = cycleMaps[i];
      final ds = (m['disciplineScore'] is num) ? (m['disciplineScore'] as num).toInt() : 50;
      final pnl = (m['pnl'] is num) ? (m['pnl'] as num).toDouble() : 0.0;
      final r = (m['regime'] is String) ? m['regime'] as String : currentRegimeLocal;
      recent.add(CycleSummary(disciplineScore: ds, pnl: pnl, regime: r));
    }

    // Backtest summary
    final backtest = latestBacktest == null
        ? null
        : BacktestSummary(bestConfig: latestBacktest, weakConfig: null, summaryNote: null);

    // Constraints -> map to engine Constraints
    final c = strategyLocal.constraints;
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

    // Try live-aware generation when MarketDataService is available and a symbol can be determined
    String? symbol;
    final lb = latestBacktest;
    if (lb != null && lb['symbol'] is String) {
      symbol = lb['symbol'] as String;
    } else if (strategyLocal.constraints.containsKey('symbol') && strategyLocal.constraints['symbol'] is String) {
      symbol = strategyLocal.constraints['symbol'] as String;
    }

    if (_marketDataService != null && symbol != null) {
      final mds = _marketDataService;
      // Prefer LiveSyncManager if provided to orchestrate all live calls
      if (_liveSyncManager != null) {
        final lsm = _liveSyncManager;
        final token = _beginAsyncCallback();
        lsm.refresh(symbol, ctx).then((res) {
          if (!_activeCallbackTokens.contains(token)) {
            _endAsyncCallback(token);
            return;
          }
          recommendations = res.recommendations;
          narrative = res.narrative;
          notifyListeners();
          _endAsyncCallback(token);
        }).catchError((_) {
          if (!_activeCallbackTokens.contains(token)) {
            _endAsyncCallback(token);
            return;
          }
          recommendations = generateRecommendations(ctx);
          narrative = generateNarrative(ctx, recsBundle: recommendations);
          notifyListeners();
          _endAsyncCallback(token);
        });
      } else {
        // best-effort asynchronous fetch; update recommendations/narrative when ready
        final token = _beginAsyncCallback();
        final sym = symbol;
        mds.getRegime(sym).then((regimeSnap) async {
          if (!_activeCallbackTokens.contains(token)) {
            _endAsyncCallback(token);
            return;
          }
          final volSnap = await mds.getVolatility(sym);
          if (!_activeCallbackTokens.contains(token)) {
            _endAsyncCallback(token);
            return;
          }
          final liqSnap = await mds.getLiquidity(sym);
          if (!_activeCallbackTokens.contains(token)) {
            _endAsyncCallback(token);
            return;
          }

          final recs = await (_recsEngine?.generate(context: ctx, regime: regimeSnap, vol: volSnap, liq: liqSnap)
              ?? StrategyRecommendationsEngine().generate(context: ctx, regime: regimeSnap, vol: volSnap, liq: liqSnap));
          if (!_activeCallbackTokens.contains(token)) {
            _endAsyncCallback(token);
            return;
          }

          final narr = _narrativeEngine?.generate(context: ctx, recs: recs, regime: regimeSnap, vol: volSnap, liq: liqSnap)
              ?? const StrategyNarrativeEngine().generate(context: ctx, recs: recs, regime: regimeSnap, vol: volSnap, liq: liqSnap);

          if (!_activeCallbackTokens.contains(token)) {
            _endAsyncCallback(token);
            return;
          }
          recommendations = recs;
          narrative = narr;
          notifyListeners();
          _endAsyncCallback(token);
        }).catchError((_) {
          if (!_activeCallbackTokens.contains(token)) {
            _endAsyncCallback(token);
            return;
          }
          // fallback to pure deterministic generator on any failure
          recommendations = generateRecommendations(ctx);
          narrative = generateNarrative(ctx, recsBundle: recommendations);
          notifyListeners();
          _endAsyncCallback(token);
        });
      }
    } else {
      final token = _beginAsyncCallback();
      recommendations = generateRecommendations(ctx);
      // Also generate and cache the human-friendly narrative alongside recommendations
      narrative = generateNarrative(ctx, recsBundle: recommendations);
      if (_activeCallbackTokens.contains(token)) {
        notifyListeners();
      }
      _endAsyncCallback(token);
    }
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
    // Invalidate any in-flight async callbacks and cancel stream subscriptions.
    _activeCallbackTokens.clear();
    _strategySub?.cancel();
    _healthSub?.cancel();
    _backtestSub?.cancel();
    _regimeSub?.cancel();
    super.dispose();
  }
}

// Note: we use Strategy.fromMap to construct models from Map data
