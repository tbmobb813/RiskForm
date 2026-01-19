import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backtest/backtest_history_repository.dart';
import '../services/firebase/cloud_backtest_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final backtestHistoryRepositoryProvider = Provider<BacktestHistoryRepository>((ref) {
  return BacktestHistoryRepository();
});

final cloudBacktestServiceProvider = Provider<CloudBacktestService>((ref) {
  return CloudBacktestService(firestore: FirebaseFirestore.instance);
});