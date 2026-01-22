import 'dart:async';
import 'package:flutter/foundation.dart';

import '../services/strategy_backtest_service.dart';

class StrategyBacktestViewModel extends ChangeNotifier {
  final String strategyId;
  final StrategyBacktestService _backtestService;

  // -----------------------------
  // Reactive Data
  // -----------------------------
  Map<String, dynamic>? latestBacktest;
  List<Map<String, dynamic>> backtestHistory = [];

  bool isLoading = true;
  bool hasError = false;

  StreamSubscription? _latestSub;
  StreamSubscription? _historySub;

  StrategyBacktestViewModel({
    required this.strategyId,
    StrategyBacktestService? backtestService,
  }) : _backtestService = backtestService ?? StrategyBacktestService() {
    _init();
  }

  // -----------------------------
  // Initialization
  // -----------------------------
  void _init() {
    _listenToLatest();
    _listenToHistory();
  }

  // -----------------------------
  // Latest Backtest
  // -----------------------------
  void _listenToLatest() {
    _latestSub =
        _backtestService.watchLatestBacktest(strategyId).listen(
      (data) {
        latestBacktest = data;
        _setLoaded();
      },
      onError: (_) => _setError(),
    );
  }

  // -----------------------------
  // Backtest History
  // -----------------------------
  void _listenToHistory() {
    _historySub =
        _backtestService.watchBacktestHistory(strategyId).listen(
      (list) {
        backtestHistory = list;
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
  // Cleanup
  // -----------------------------
  @override
  void dispose() {
    _latestSub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }
}
