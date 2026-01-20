import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../strategy_cockpit/models/strategy_health_snapshot.dart';
import '../../strategy_cockpit/analytics/strategy_regime_analyzer.dart';
import '../../strategy_cockpit/services/strategy_health_service.dart';
import '../../regime/regime_service.dart';

class StrategyRegimeViewModel extends ChangeNotifier {
  final String strategyId;
  final StrategyHealthService _healthService;
  final RegimeService _regimeService;

  // -----------------------------
  // Reactive Data
  // -----------------------------
  Map<String, Map<String, dynamic>> regimePerformance = {};
  List<String> regimeWeaknesses = [];
  String currentRegime = "";
  String currentRegimeHint = "";

  bool isLoading = true;
  bool hasError = false;

  StreamSubscription? _healthSub;
  StreamSubscription? _regimeSub;

  StrategyRegimeViewModel({
    required this.strategyId,
    StrategyHealthService? healthService,
    RegimeService? regimeService,
  })  : _healthService = healthService ?? StrategyHealthService(),
        _regime_service = regimeService ?? RegimeService() {
    _init();
  }

  // -----------------------------
  // Initialization
  // -----------------------------
  void _init() {
    _listenToHealth();
    _listenToRegime();
  }

  // -----------------------------
  // Strategy Health Snapshot
  // -----------------------------
  void _listenToHealth() {
    _healthSub = _healthService.watchHealth(strategyId).listen(
      (snapshot) {
        if (snapshot != null) {
          _computeRegimeAnalytics(snapshot);
        }
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
        currentRegime = regime ?? "";
        _setLoaded();
      },
      onError: (_) => _setError(),
    );
  }

  // -----------------------------
  // Compute Regime Analytics
  // -----------------------------
  void _computeRegimeAnalytics(StrategyHealthSnapshot snapshot) {
    regimePerformance =
        StrategyRegimeAnalyzer.computeRegimePerformance(snapshot);

    regimeWeaknesses =
        StrategyRegimeAnalyzer.computeRegimeWeaknesses(snapshot);

    currentRegimeHint = StrategyRegimeAnalyzer.computeCurrentRegimeHint(
      snapshot: snapshot,
      currentRegime: currentRegime,
    );

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
    _regimeSub?.cancel();
    super.dispose();
  }
}
