import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/journal/journal_entry.dart';
import '../../services/journal/journal_repository.dart';
import 'strategy_cycle_service.dart';
import 'strategy_health_service.dart';
import '../../planner/models/planner_strategy_context.dart';

/// Minimal, production-minded ExecutionService that accepts a
/// strategy-aware execution envelope, journals the trade, enforces
/// basic constraints and routes it to the cycle service.
class ExecutionService {
  final FirebaseFirestore _firestore;
  final JournalRepository _journalRepo;
  final StrategyCycleService _cycleService;
  final StrategyHealthService _healthService;

  ExecutionService({
    FirebaseFirestore? firestore,
    required JournalRepository journalRepo,
    StrategyCycleService? cycleService,
    StrategyHealthService? healthService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _journalRepo = journalRepo,
        _cycleService = cycleService ?? StrategyCycleService(firestore: firestore),
        _healthService = healthService ?? StrategyHealthService(firestore: firestore);

  Future<void> executeStrategyTrade(Map<String, dynamic> envelope) async {
    final strategyId = envelope['strategyId'] as String?;
    if (strategyId == null) throw Exception('Missing strategyId');

    final userId = envelope['userId'] as String? ?? envelope['uid'] as String?;
    if (userId == null) throw Exception('Missing userId in execution envelope');

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
      // Count open positions for this strategy. Positions are stored under
      // users/{uid}/positions with a `strategy` field (not `strategyId`). If
      // the caller supplies a `userId` in the envelope we'll scope the
      // query to that user's positions; otherwise fall back to a
      // collection-group query across all users' positions (requires an
      // index and is less precise for per-user enforcement).
      final userId = envelope['userId'] as String? ?? envelope['uid'] as String?;
      QuerySnapshot q;
      if (userId != null) {
        q = await _firestore
            .collection('users')
            .doc(userId)
            .collection('positions')
            .where('strategy', isEqualTo: strategyId)
            .where('isOpen', isEqualTo: true)
            .get();
      } else {
        q = await _firestore
            .collectionGroup('positions')
            .where('strategy', isEqualTo: strategyId)
            .where('isOpen', isEqualTo: true)
            .get();
      }

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
