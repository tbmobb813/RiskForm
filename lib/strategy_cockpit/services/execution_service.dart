import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/journal/journal_entry.dart';
import '../../services/journal/journal_repository.dart';
import '../../services/strategy/strategy_service.dart';
import 'strategy_cycle_service.dart';
import 'strategy_health_service.dart';
import '../../planner/models/planner_strategy_context.dart';

/// Minimal, production-minded ExecutionService that accepts a
/// strategy-aware execution envelope, journals the trade, enforces
/// basic constraints and routes it to the cycle service.
class ExecutionService {
  final FirebaseFirestore _firestore;
  final JournalRepository _journalRepo;
  final StrategyService _strategyService;
  final StrategyCycleService _cycleService;
  final StrategyHealthService _healthService;

  ExecutionService({
    FirebaseFirestore? firestore,
    required JournalRepository journalRepo,
    StrategyService? strategyService,
    StrategyCycleService? cycleService,
    StrategyHealthService? healthService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _journalRepo = journalRepo,
        _strategyService = strategyService ?? StrategyService(firestore: firestore),
        _cycleService = cycleService ?? StrategyCycleService(firestore: firestore),
        _healthService = healthService ?? StrategyHealthService(firestore: firestore);

  Future<void> executeStrategyTrade(Map<String, dynamic> envelope) async {
    final strategyId = envelope['strategyId'] as String?;
    if (strategyId == null) throw Exception('Missing strategyId');

    final strategyDoc = await _firestore.collection('strategies').doc(strategyId).get();
    if (!strategyDoc.exists) throw Exception('Strategy not found: $strategyId');

    final strategyData = strategyDoc.data() as Map<String, dynamic>;
    final state = (strategyData['state'] as String?) ?? 'active';
    if (state == 'paused' || state == 'retired') {
      throw Exception('Strategy is not active: $state');
    }

    final context = envelope['context'] as Map<String, dynamic>? ?? {};
    final execution = envelope['execution'] as Map<String, dynamic>? ?? {};

    // Basic constraint enforcement (example: maxPositions)
    final constraints = Map<String, dynamic>.from(strategyData['constraints'] ?? {});
    final maxPositions = constraints['maxPositions'] as int?;
    if (maxPositions != null) {
      // count positions (simplified): read positions collection for strategy
      final q = await _firestore
          .collection('positions')
          .where('strategyId', isEqualTo: strategyId)
          .get();
      if (q.docs.length >= maxPositions) {
        throw Exception('Strategy has reached max positions: $maxPositions');
      }
    }

    // Journal the trade
    final entry = JournalEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.now().toUtc(),
      type: 'strategyExecution',
      data: {
        'strategyId': strategyId,
        'strategyName': strategyData['name'],
        'execution': execution,
        'context': context,
      },
    );

    await _journalRepo.addEntry(entry);

    // Persist trade inside a transaction and mark health dirty
    await _firestore.runTransaction((tx) async {
      // Build a minimal PlannerStrategyContext from strategy doc + context hints
      final plannerContext = PlannerStrategyContext(
        strategyId: strategyId,
        strategyName: strategyData['name'] as String? ?? '',
        state: state,
        tags: List<String>.from(strategyData['tags'] ?? []),
        constraintsSummary: strategyData['constraintsSummary'],
        constraints: Map<String, dynamic>.from(strategyData['constraints'] ?? {}),
        currentRegime: strategyData['currentRegime'],
        disciplineFlags: List<String>.from(strategyData['disciplineFlags'] ?? []),
        updatedAt: DateTime.now(),
      );

      await _cycleService.appendExecutionToCycleInTx(
        tx: tx,
        strategyId: strategyId,
        execution: execution,
        strategyContext: plannerContext,
      );

      await _healthService.markHealthDirtyInTx(tx: tx, strategyId: strategyId);
    });
  }
}
