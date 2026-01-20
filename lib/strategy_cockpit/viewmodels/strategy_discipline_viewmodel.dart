import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/strategy_health_snapshot.dart';
import '../analytics/strategy_discipline_analyzer.dart';
import '../services/strategy_health_service.dart';

class StrategyDisciplineViewModel extends ChangeNotifier {
  final String strategyId;
  final StrategyHealthService _healthService;

  // -----------------------------
  // Reactive Data
  // -----------------------------
  List<double> disciplineTrend = [];
  Map<String, int> violationBreakdown = {
    'adherence': 0,
    'timing': 0,
    'risk': 0,
  };

  int cleanCycleStreak = 0;
  int adherenceStreak = 0;
  int riskStreak = 0;

  List<Map<String, dynamic>> recentEvents = [];
  String mostCommonViolation = 'none';

  bool isLoading = true;
  bool hasError = false;

  StreamSubscription? _healthSub;

  StrategyDisciplineViewModel({
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
          _computeDiscipline(snapshot);
        }
        _setLoaded();
      },
      onError: (_) => _setError(),
    );
  }

  // -----------------------------
  // Compute Discipline Metrics
  // -----------------------------
  void _computeDiscipline(StrategyHealthSnapshot snapshot) {
    disciplineTrend = StrategyDisciplineAnalyzer.getTrend(snapshot);

    violationBreakdown =
        StrategyDisciplineAnalyzer.computeViolationBreakdown(snapshot);

    cleanCycleStreak =
        StrategyDisciplineAnalyzer.computeCleanCycleStreak(snapshot);

    adherenceStreak =
        StrategyDisciplineAnalyzer.computeAdherenceStreak(snapshot);

    riskStreak = StrategyDisciplineAnalyzer.computeRiskStreak(snapshot);

    recentEvents =
        StrategyDisciplineAnalyzer.recentDisciplineEvents(snapshot);

    mostCommonViolation =
        StrategyDisciplineAnalyzer.computeMostCommonViolation(snapshot);

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
