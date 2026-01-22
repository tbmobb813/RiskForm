import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../models/strategy_health_snapshot.dart';
import '../analytics/strategy_performance_analyzer.dart';
import '../services/strategy_health_service.dart';

class StrategyPerformanceViewModel extends ChangeNotifier {
  final String strategyId;
  final StrategyHealthService _healthService;

  // -----------------------------
  // Reactive Data
  // -----------------------------
  List<double> pnlTrend = [];
  double winRate = 0;
  double maxDrawdown = 0;
  Map<String, dynamic>? bestCycle;
  Map<String, dynamic>? worstCycle;

  bool isLoading = true;
  bool hasError = false;

  StreamSubscription? _healthSub;

  StrategyPerformanceViewModel({
    required this.strategyId,
    StrategyHealthService? healthService,
  }) : _healthService = healthService ?? StrategyHealthService() {
    _init();
  }

  // -----------------------------
  // Initialization
  // -----------------------------
  void _init() {
    _healthSub = _healthService.watchHealth(strategyId).listen(
      (snapshot) {
        if (snapshot != null) {
          _computePerformance(snapshot);
        }
        _setLoaded();
      },
      onError: (_) => _setError(),
    );
  }

  // -----------------------------
  // Compute Performance Metrics
  // -----------------------------
  void _computePerformance(StrategyHealthSnapshot snapshot) {
    pnlTrend = snapshot.pnlTrend;

    winRate = StrategyPerformanceAnalyzer.computeWinRate(snapshot);
    maxDrawdown = StrategyPerformanceAnalyzer.computeMaxDrawdown(snapshot);

    bestCycle = StrategyPerformanceAnalyzer.computeBestCycle(snapshot);
    worstCycle = StrategyPerformanceAnalyzer.computeWorstCycle(snapshot);

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
  // Cleanup
  // -----------------------------
  @override
  void dispose() {
    _healthSub?.cancel();
    super.dispose();
  }
}
