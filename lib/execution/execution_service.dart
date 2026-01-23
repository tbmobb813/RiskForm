import 'package:cloud_firestore/cloud_firestore.dart';

import '../planner/models/planner_strategy_context.dart';
import '../utils/firestore_helpers.dart' as fh;
import '../strategy_cockpit/services/strategy_cycle_service.dart';
import '../strategy_cockpit/services/strategy_health_service.dart';

/// Represents a single trade execution coming from the Planner.
class StrategyExecutionRequest {
  final PlannerStrategyContext strategyContext;
  final Map<String, dynamic> execution; // raw trade payload from Planner

  /// Optional: if Planner already knows the active cycle.
  final String? cycleId;

  StrategyExecutionRequest({
    required this.strategyContext,
    required this.execution,
    this.cycleId,
  });
}

/// Represents the result of an execution attempt.
class StrategyExecutionResult {
  final bool success;
  final String? errorMessage;
  final String? journalEntryId;
  final String? cycleId;

  const StrategyExecutionResult({
    required this.success,
    this.errorMessage,
    this.journalEntryId,
    this.cycleId,
  });

  factory StrategyExecutionResult.ok({
    required String journalEntryId,
    required String cycleId,
  }) {
    return StrategyExecutionResult(
      success: true,
      journalEntryId: journalEntryId,
      cycleId: cycleId,
    );
  }

  factory StrategyExecutionResult.fail(String message) {
    return StrategyExecutionResult(
      success: false,
      errorMessage: message,
    );
  }
}

class ExecutionService {
  final FirebaseFirestore? _firestore;
  final StrategyCycleService _cycleService;
  final StrategyHealthService _healthService;

  ExecutionService({
    FirebaseFirestore? firestore,
    StrategyCycleService? cycleService,
    StrategyHealthService? healthService,
  })  : _firestore = firestore,
        _cycleService = cycleService ?? StrategyCycleService(firestore: firestore),
        _healthService = healthService ?? StrategyHealthService(firestore: firestore);

  // ------------------------------------------------------------
  // Public entrypoint: execute a strategy-bound trade
  // ------------------------------------------------------------
  Future<StrategyExecutionResult> executeStrategyTrade(
    StrategyExecutionRequest request,
  ) async {
    // Require per-user context for enforcement and auditing.
    final userId = request.execution['userId'] as String?;
    if (userId == null) {
      return StrategyExecutionResult.fail('Authentication required: missing userId in execution payload.');
    }
    final ctx = request.strategyContext;

    // 1) Validate strategy state
    if (ctx.state == 'paused') {
      return StrategyExecutionResult.fail(
        'Strategy is paused. Resume before executing trades.',
      );
    }
    if (ctx.state == 'retired') {
      return StrategyExecutionResult.fail(
        'Strategy is retired. Cannot execute trades.',
      );
    }

    // 2) Validate constraints (lightweight, pluggable)
    final constraintError = _validateConstraints(ctx, request.execution);
    if (constraintError != null) {
      return StrategyExecutionResult.fail(constraintError);
    }

    // 3) Write journal entry + update cycle + health in a transaction
    try {
      final db = _firestore ?? FirebaseFirestore.instance;
      return await db.runTransaction<StrategyExecutionResult>(
        (tx) async {
          // 3a) Create journal entry (use canonical 'journalEntries' collection)
          final journalRef = db.collection('journalEntries').doc();
          final journalData = _buildJournalEntryData(ctx, request.execution);
          tx.set(journalRef, journalData);

          // 3b) Update / create strategy cycle
          final cycleId = await _cycleService.appendExecutionToCycleInTx(
            tx: tx,
            strategyId: ctx.strategyId,
            execution: request.execution,
            strategyContext: ctx,
            existingCycleId: request.cycleId,
          );

          // 3c) Trigger health recompute (enqueue marker)
          await _healthService.markHealthDirtyInTx(
            tx: tx,
            strategyId: ctx.strategyId,
          );

          return StrategyExecutionResult.ok(
            journalEntryId: journalRef.id,
            cycleId: cycleId,
          );
        },
      );
    } catch (e) {
      return StrategyExecutionResult.fail(
        'Execution failed: ${e.toString()}',
      );
    }
  }

  // ------------------------------------------------------------
  // Constraint validation (keep this simple + pluggable)
  // ------------------------------------------------------------
  String? _validateConstraints(
    PlannerStrategyContext ctx,
    Map<String, dynamic> execution,
  ) {
    final constraints = ctx.constraints;

    // Example: maxRisk check
    if (constraints.containsKey('maxRisk')) {
      final maxRisk = (constraints['maxRisk'] ?? 0).toDouble();
      final estRisk = _estimateRisk(execution);
      if (estRisk > maxRisk) {
        return 'Estimated risk (estRisk) exceeds max allowed risk (maxRisk) for this strategy.';
      }
    }

    return null; // no errors
  }

  double _estimateRisk(Map<String, dynamic> execution) {
    // Placeholder: you can wire this to a real risk engine.
    // For now, assume premium * 100 * qty for options.
    final premium = ((execution['premium'] as num?) ?? 0).toDouble();
    final qty = ((execution['qty'] as num?) ?? 1).toDouble();
    return premium * 100 * qty;
  }

  // ------------------------------------------------------------
  // Journal entry builder
  // ------------------------------------------------------------
  Map<String, dynamic> _buildJournalEntryData(
    PlannerStrategyContext ctx,
    Map<String, dynamic> execution,
  ) {
    final now = DateTime.now();

    return {
      'strategyId': ctx.strategyId,
      'strategyName': ctx.strategyName,
      'strategyState': ctx.state,
      'tags': ctx.tags,
      'constraintsSummary': ctx.constraintsSummary,
      'currentRegime': ctx.currentRegime,
      'disciplineFlags': ctx.disciplineFlags,
      'execution': execution,
      'createdAt': fh.toTimestamp(now),
      'updatedAt': fh.toTimestamp(now),
    };
  }
}
