import '../../models/journal/journal_entry.dart';
import '../../models/journal/discipline_score.dart';
import '../../models/analytics/market_regime.dart';

class DisciplineScoringService {
  DisciplineScore compute(List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return DisciplineScore(
        score: 0.0,
        planAdherence: 0.0,
        cycleQuality: 0.0,
        assignmentBehavior: 0.0,
        regimeAwareness: 0.0,
      );
    }

    final cycles = entries.where((e) => e.type == 'cycle').toList();
    final completedCycles = entries.where((e) => e.type == 'calledAway').length;

    final planAdherence = cycles.isEmpty
      ? 0.0
      : (completedCycles / cycles.length).clamp(0, 1).toDouble();

    final avgCycleReturn = cycles.isEmpty
        ? 0.0
        : cycles
            .map((e) => (e.data['cycleReturn'] is num) ? (e.data['cycleReturn'] as num).toDouble() : 0.0)
            .fold(0.0, (a, b) => a + b) /
            cycles.length;

    final cycleQuality = ((avgCycleReturn + 0.05) / 0.10).clamp(0, 1).toDouble();

    final assignments = entries.where((e) => e.type == 'assignment').length;
    final calledAway = entries.where((e) => e.type == 'calledAway').length;

    final assignmentBehavior = assignments == 0 ? 1.0 : (calledAway / assignments).clamp(0, 1).toDouble();

    final downCycles = cycles.where((e) => e.data['dominantRegime'] == MarketRegime.downtrend.toString()).toList();

    double regimeAwareness = 1.0;
    if (downCycles.isNotEmpty) {
      final avgDownReturn = downCycles
          .map((e) => (e.data['cycleReturn'] is num) ? (e.data['cycleReturn'] as num).toDouble() : 0.0)
          .fold(0.0, (a, b) => a + b) /
          downCycles.length;

      regimeAwareness = ((avgDownReturn + 0.10) / 0.20).clamp(0, 1).toDouble();
    }

    final score = (planAdherence * 0.35 + cycleQuality * 0.25 + assignmentBehavior * 0.20 + regimeAwareness * 0.20) * 100;

    return DisciplineScore(
      score: score,
      planAdherence: planAdherence,
      cycleQuality: cycleQuality,
      assignmentBehavior: assignmentBehavior,
      regimeAwareness: regimeAwareness,
    );
  }
}
