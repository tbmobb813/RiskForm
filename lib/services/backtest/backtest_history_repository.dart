import 'package:flutter/foundation.dart';
import '../../models/backtest/backtest_result.dart';

class BacktestHistoryEntry {
  final String id;
  final String label;
  final DateTime timestamp;
  final BacktestResult result;

  BacktestHistoryEntry({
    required this.id,
    required this.label,
    required this.timestamp,
    required this.result,
  });
}

class BacktestHistoryRepository {
  final List<BacktestHistoryEntry> _entries = [];

  List<BacktestHistoryEntry> getAll() => List.unmodifiable(_entries);

  void add(BacktestHistoryEntry entry) {
    _entries.insert(0, entry);
  }

  void clear() {
    _entries.clear();
  }
}
