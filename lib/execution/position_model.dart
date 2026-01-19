import 'package:cloud_firestore/cloud_firestore.dart';

class Position {
  final String id;
  final DateTime openedAt;
  final String strategyId;
  final String planId;
  final double entryPrice;
  final int contracts;
  final String cycleState; // opened, managed, closed

  Position({
    required this.id,
    required this.openedAt,
    required this.strategyId,
    required this.planId,
    required this.entryPrice,
    required this.contracts,
    required this.cycleState,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'openedAt': Timestamp.fromDate(openedAt),
      'strategyId': strategyId,
      'planId': planId,
      'entryPrice': entryPrice,
      'contracts': contracts,
      'cycleState': cycleState,
    };
  }

  factory Position.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['openedAt'];
    DateTime opened = DateTime.now();
    if (ts is Timestamp) opened = ts.toDate();

    return Position(
      id: doc.id,
      openedAt: opened,
      strategyId: data['strategyId'] as String? ?? 'unknown',
      planId: data['planId'] as String? ?? '',
      entryPrice: (data['entryPrice'] is num) ? (data['entryPrice'] as num).toDouble() : 0.0,
      contracts: data['contracts'] as int? ?? 0,
      cycleState: data['cycleState'] as String? ?? 'opened',
    );
  }
}
