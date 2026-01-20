import 'package:flutter/foundation.dart';

import '../../services/backtest_comparison_service.dart';
import '../../models/backtest_comparison_result.dart';

class BacktestComparisonViewModel extends ChangeNotifier {
  final BacktestComparisonService _service;
  final String strategyId;

  BacktestComparisonResult? result;
  bool loading = true;

  BacktestComparisonViewModel({
    required this.strategyId,
    BacktestComparisonService? service,
  }) : _service = service ?? BacktestComparisonService() {
    _load();
  }

  Future<void> _load() async {
    loading = true;
    notifyListeners();

    try {
      result = await _service.compareLastN(strategyId: strategyId, limit: 5);
    } catch (_) {
      result = null;
    }

    loading = false;
    notifyListeners();
  }
}
