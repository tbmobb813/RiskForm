import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backtest/backtest_history_repository.dart';

final backtestHistoryRepositoryProvider = Provider<BacktestHistoryRepository>((ref) {
  return BacktestHistoryRepository();
});
