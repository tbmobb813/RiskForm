import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/backtest/backtest_history_repository.dart';

class BacktestHistoryScreen extends ConsumerWidget {
  final BacktestHistoryRepository repository;

  const BacktestHistoryScreen({super.key, required this.repository});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = repository.getAll();
    return Scaffold(
      appBar: AppBar(title: const Text('Backtest History')),
      body: items.isEmpty
          ? const Center(child: Text('No backtests recorded'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final e = items[i];
                return Card(
                  child: ListTile(
                    title: Text(e.label),
                    subtitle: Text('${e.timestamp.toLocal()} • ${e.result.strategyId} • v${e.result.engineVersion}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        // Navigate to BacktestScreen? For now, show details.
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: Text(e.label),
                            content: Text('Cycles: ${e.result.cyclesCompleted}\nTotal Return: ${(e.result.totalReturn * 100).toStringAsFixed(2)}%'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Close')),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
