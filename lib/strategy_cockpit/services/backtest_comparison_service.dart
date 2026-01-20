import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/backtest_comparison_result.dart';

class BacktestComparisonService {
  final FirebaseFirestore _firestore;

  BacktestComparisonService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference _runs(String strategyId) =>
      _firestore.collection('strategyBacktests').doc(strategyId).collection('runs');

  // Compare last N completed backtests
  Future<BacktestComparisonResult> compareLastN({
    required String strategyId,
    int limit = 5,
  }) async {
    final snap = await _runs(strategyId)
        .where('status', isEqualTo: 'complete')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    final runs = snap.docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      return {
        'runId': d.id,
        ...data,
      };
    }).toList();

    if (runs.isEmpty) {
      return const BacktestComparisonResult(
        runs: [],
        bestConfig: null,
        worstConfig: null,
        regimeWeaknesses: {},
        summaryNote: 'No completed backtests available.',
      );
    }

    final best = _findBest(runs);
    final worst = _findWorst(runs);
    final regimeWeaknesses = _computeRegimeWeaknesses(runs);
    final summaryNote = _buildSummaryNote(best, worst, regimeWeaknesses);

    return BacktestComparisonResult(
      runs: runs,
      bestConfig: best,
      worstConfig: worst,
      regimeWeaknesses: regimeWeaknesses,
      summaryNote: summaryNote,
    );
  }

  Map<String, dynamic>? _findBest(List<Map<String, dynamic>> runs) {
    Map<String, dynamic>? best;
    double bestScore = double.negativeInfinity;

    for (final r in runs) {
      final m = (r['metrics'] as Map<String, dynamic>?) ?? {};
      final pnl = ((m['pnl'] as num?)?.toDouble()) ?? 0.0;
      final dd = ((m['maxDrawdown'] as num?)?.toDouble()) ?? 0.0;
      final winRate = ((m['winRate'] as num?)?.toDouble()) ?? 0.0;

      // Simple score: pnl - drawdown + winRate * 100
      final score = pnl - dd + winRate * 100.0;
      if (score > bestScore) {
        bestScore = score;
        best = r;
      }
    }
    return best;
  }

  Map<String, dynamic>? _findWorst(List<Map<String, dynamic>> runs) {
    Map<String, dynamic>? worst;
    double worstScore = double.infinity;

    for (final r in runs) {
      final m = (r['metrics'] as Map<String, dynamic>?) ?? {};
      final pnl = ((m['pnl'] as num?)?.toDouble()) ?? 0.0;
      final dd = ((m['maxDrawdown'] as num?)?.toDouble()) ?? 0.0;
      final winRate = ((m['winRate'] as num?)?.toDouble()) ?? 0.0;

      final score = pnl - dd + winRate * 100.0;
      if (score < worstScore) {
        worstScore = score;
        worst = r;
      }
    }
    return worst;
  }

  Map<String, String> _computeRegimeWeaknesses(List<Map<String, dynamic>> runs) {
    final Map<String, double> regimePnl = {};
    final Map<String, int> regimeCount = {};

    for (final r in runs) {
      final rb = (r['regimeBreakdown'] as Map<String, dynamic>?) ?? {};
      rb.forEach((regime, value) {
        final v = value as Map<String, dynamic>;
        final pnl = ((v['pnl'] as num?)?.toDouble()) ?? 0.0;
        regimePnl[regime] = (regimePnl[regime] ?? 0.0) + pnl;
        regimeCount[regime] = (regimeCount[regime] ?? 0) + 1;
      });
    }

    final Map<String, String> notes = {};
    regimePnl.forEach((regime, pnl) {
      final avg = pnl / (regimeCount[regime] ?? 1);
      if (avg < 0) {
        notes[regime] = 'Strategy tends to lose in $regime conditions.';
      } else if (avg > 0) {
        notes[regime] = 'Strategy tends to perform well in $regime conditions.';
      }
    });

    return notes;
  }

  String _buildSummaryNote(
    Map<String, dynamic>? best,
    Map<String, dynamic>? worst,
    Map<String, String> regimeWeaknesses,
  ) {
    if (best == null) return 'No comparison available.';

    final bestParams = best['parameters'] ?? {};
    final buffer = StringBuffer();

    buffer.writeln('Best configuration found: $bestParams.');

    if (worst != null) {
      final worstParams = worst['parameters'] ?? {};
      buffer.writeln('Weak configuration: $worstParams.');
    }

    if (regimeWeaknesses.isNotEmpty) {
      buffer.writeln('Regime notes:');
      regimeWeaknesses.forEach((regime, note) {
        buffer.writeln('- $note');
      });
    }

    return buffer.toString().trim();
  }
}
