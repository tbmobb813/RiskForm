import 'package:cloud_firestore/cloud_firestore.dart';

class StrategyCycle {
  final String id;
  final String strategyId;

  // Lifecycle
  final String state; // active | closed
  final DateTime startedAt;
  final DateTime? closedAt;

  // Metrics
  final double realizedPnl;
  final double unrealizedPnl;
  final double disciplineScore; // 0–100
  final int tradeCount;

  // Regime context
  final String? dominantRegime;

  // Raw executions (lightweight summary, not full journal)
  final List<Map<String, dynamic>> executions;

  const StrategyCycle({
    required this.id,
    required this.strategyId,
    required this.state,
    required this.startedAt,
    required this.closedAt,
    required this.realizedPnl,
    required this.unrealizedPnl,
    required this.disciplineScore,
    required this.tradeCount,
    required this.dominantRegime,
    required this.executions,
  });

  factory StrategyCycle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StrategyCycle(
      id: doc.id,
      strategyId: data['strategyId'] as String,
      state: data['state'] as String,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      closedAt: data['closedAt'] != null
          ? (data['closedAt'] as Timestamp).toDate()
          : null,
      realizedPnl: (data['realizedPnl'] ?? 0).toDouble(),
      unrealizedPnl: (data['unrealizedPnl'] ?? 0).toDouble(),
      disciplineScore: (data['disciplineScore'] ?? 0).toDouble(),
      tradeCount: (data['tradeCount'] ?? 0) as int,
      dominantRegime: data['dominantRegime'],
      executions: List<Map<String, dynamic>>.from(
        data['executions'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'strategyId': strategyId,
      'state': state,
      'startedAt': startedAt,
      'closedAt': closedAt,
      'realizedPnl': realizedPnl,
      'unrealizedPnl': unrealizedPnl,
      'disciplineScore': disciplineScore,
      'tradeCount': tradeCount,
      'dominantRegime': dominantRegime,
      'executions': executions,
    };
  }

  StrategyCycle copyWith({
    String? state,
    DateTime? startedAt,
    DateTime? closedAt,
    double? realizedPnl,
    double? unrealizedPnl,
    double? disciplineScore,
    int? tradeCount,
    String? dominantRegime,
    List<Map<String, dynamic>>? executions,
  }) {
    return StrategyCycle(
      id: id,
      strategyId: strategyId,
      state: state ?? this.state,
      startedAt: startedAt ?? this.startedAt,
      closedAt: closedAt ?? this.closedAt,
      realizedPnl: realizedPnl ?? this.realizedPnl,
      unrealizedPnl: unrealizedPnl ?? this.unrealizedPnl,
      disciplineScore: disciplineScore ?? this.disciplineScore,
      tradeCount: tradeCount ?? this.tradeCount,
      dominantRegime: dominantRegime ?? this.dominantRegime,
      executions: executions ?? this.executions,
    );
  }
}
