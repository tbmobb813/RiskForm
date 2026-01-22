import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/strategy_cycle.dart';
import '../../planner/models/planner_strategy_context.dart';

import '../analytics/strategy_performance_analyzer.dart';
import '../analytics/strategy_discipline_analyzer.dart';
import '../analytics/strategy_regime_analyzer.dart';

class StrategyCycleService {
  final FirebaseFirestore? _firestore;

  StrategyCycleService({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference get _cycles => _db.collection('strategyCycles');

  // ------------------------------------------------------------
  // Transaction-aware append: used by ExecutionService
  // ------------------------------------------------------------
  Future<String> appendExecutionToCycleInTx({
    required Transaction tx,
    required String strategyId,
    required Map<String, dynamic> execution,
    required PlannerStrategyContext strategyContext,
    String? existingCycleId,
  }) async {
    // 1) Resolve active cycle
    final cycleRef = await _resolveActiveCycleRefInTx(
      tx: tx,
      strategyId: strategyId,
      existingCycleId: existingCycleId,
    );

    var createdNewCycle = false;

    final snapshot = await tx.get(cycleRef);
    StrategyCycle cycle;

    if (!snapshot.exists) {
      // New cycle
      cycle = _createNewCycle(
        id: cycleRef.id,
        strategyId: strategyId,
        execution: execution,
        strategyContext: strategyContext,
      );
      createdNewCycle = true;
    } else {
      cycle = StrategyCycle.fromFirestore(snapshot);
      cycle = _appendExecutionAndRecompute(
        cycle: cycle,
        execution: execution,
        strategyContext: strategyContext,
      );
    }

    tx.set(cycleRef, cycle.toFirestore(), SetOptions(merge: false));

    // If we created a new cycle, write a lightweight meta document keyed by
    // the strategy id that stores the activeCycleId. This allows subsequent
    // executions to locate and append to the active cycle instead of creating
    // a new one each time.
    if (createdNewCycle) {
      final metaRef = _cycles.doc(strategyId);
      tx.set(metaRef, {
        'activeCycleId': cycleRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return cycleRef.id;
  }

  // ------------------------------------------------------------
  // Resolve or create active cycle ref
  // ------------------------------------------------------------
  Future<DocumentReference> _resolveActiveCycleRefInTx({
    required Transaction tx,
    required String strategyId,
    String? existingCycleId,
  }) async {
    if (existingCycleId != null) {
      return _cycles.doc(existingCycleId);
    }
    // Prefer reading a meta doc that holds activeCycleId
    final metaRef = _cycles.doc(strategyId);
    final metaSnap = await tx.get(metaRef);
    if (metaSnap.exists) {
      final meta = metaSnap.data() as Map<String, dynamic>;
      final active = meta['activeCycleId'] as String?;
      if (active != null) return _cycles.doc(active);
    }

    // No active cycle → create new doc ref
    return _cycles.doc();
  }

  // ------------------------------------------------------------
  // New cycle factory
  // ------------------------------------------------------------
  StrategyCycle _createNewCycle({
    required String id,
    required String strategyId,
    required Map<String, dynamic> execution,
    required PlannerStrategyContext strategyContext,
  }) {
    final now = DateTime.now();
    final executions = <Map<String, dynamic>>[
      _executionSummary(execution),
    ];

    final metrics = _computeMetrics(
      executions: executions,
      strategyContext: strategyContext,
    );

    return StrategyCycle(
      id: id,
      strategyId: strategyId,
      state: 'active',
      startedAt: now,
      closedAt: null,
      realizedPnl: metrics.realizedPnl,
      unrealizedPnl: metrics.unrealizedPnl,
      disciplineScore: metrics.disciplineScore,
      tradeCount: executions.length,
      dominantRegime: metrics.dominantRegime,
      executions: executions,
    );
  }

  // ------------------------------------------------------------
  // Append + recompute metrics
  // ------------------------------------------------------------
  StrategyCycle _appendExecutionAndRecompute({
    required StrategyCycle cycle,
    required Map<String, dynamic> execution,
    required PlannerStrategyContext strategyContext,
  }) {
    final executions = List<Map<String, dynamic>>.from(cycle.executions)
      ..add(_executionSummary(execution));

    final metrics = _computeMetrics(
      executions: executions,
      strategyContext: strategyContext,
    );

    return cycle.copyWith(
      realizedPnl: metrics.realizedPnl,
      unrealizedPnl: metrics.unrealizedPnl,
      disciplineScore: metrics.disciplineScore,
      tradeCount: executions.length,
      dominantRegime: metrics.dominantRegime,
      executions: executions,
    );
  }

  // ------------------------------------------------------------
  // Lightweight execution summary stored on cycle
  // ------------------------------------------------------------
  Map<String, dynamic> _executionSummary(Map<String, dynamic> execution) {
    return {
      'timestamp': execution['timestamp'],
      'symbol': execution['symbol'],
      'type': execution['type'],
      'qty': execution['qty'],
      'premium': execution['premium'],
      'strike': execution['strike'],
      'expiry': execution['expiry'],
      // add more if needed, but keep this lean
    };
  }

  // ------------------------------------------------------------
  // Metrics computation hook
  // ------------------------------------------------------------
  _CycleMetrics _computeMetrics({
    required List<Map<String, dynamic>> executions,
    required PlannerStrategyContext strategyContext,
  }) {
    // ------------------------------------------------------------
    // 1. PERFORMANCE ANALYTICS
    // ------------------------------------------------------------
    final performance = StrategyPerformanceAnalyzer.computeCyclePerformance(
      executions: executions,
    );

    // ------------------------------------------------------------
    // 2. DISCIPLINE ANALYTICS
    // ------------------------------------------------------------
    final discipline = StrategyDisciplineAnalyzer.computeCycleDiscipline(
      executions: executions,
      disciplineFlags: strategyContext.disciplineFlags,
      constraints: strategyContext.constraints,
    );

    // ------------------------------------------------------------
    // 3. REGIME ANALYTICS
    // ------------------------------------------------------------
    final regime = StrategyRegimeAnalyzer.computeCycleRegime(
      executions: executions,
      currentRegime: strategyContext.currentRegime,
    );

    // ------------------------------------------------------------
    // 4. Return unified metrics
    // ------------------------------------------------------------
    return _CycleMetrics(
      realizedPnl: performance.realizedPnl,
      unrealizedPnl: performance.unrealizedPnl,
      disciplineScore: discipline.score,
      dominantRegime: regime.dominantRegime,
    );
  }
}

class _CycleMetrics {
  final double realizedPnl;
  final double unrealizedPnl;
  final double disciplineScore;
  final String? dominantRegime;

  _CycleMetrics({
    required this.realizedPnl,
    required this.unrealizedPnl,
    required this.disciplineScore,
    required this.dominantRegime,
  });
}

