import 'package:cloud_firestore/cloud_firestore.dart';
import 'trade_inputs.dart';
import 'payoff_result.dart';
import 'risk_result.dart';

class TradePlan {
  final String id;
  final String strategyId;
  final String strategyName;

  final TradeInputs inputs;
  final PayoffResult payoff;
  final RiskResult risk;

  final String notes;
  final List<String> tags;

  final DateTime createdAt;
  final DateTime updatedAt;

  TradePlan({
    required this.id,
    required this.strategyId,
    required this.strategyName,
    required this.inputs,
    required this.payoff,
    required this.risk,
    required this.notes,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      "strategyId": strategyId,
      "strategyName": strategyName,
      "inputs": inputs.toJson(),
      "payoff": {
        "maxGain": payoff.maxGain,
        "maxLoss": payoff.maxLoss,
        "breakeven": payoff.breakeven,
        "capitalRequired": payoff.capitalRequired,
      },
      "risk": {
        "riskPercentOfAccount": risk.riskPercentOfAccount,
        "assignmentExposure": risk.assignmentExposure,
        "capitalLocked": risk.capitalLocked,
        "warnings": risk.warnings,
      },
      "notes": notes,
      "tags": tags,
      "createdAt": Timestamp.fromDate(createdAt),
      "updatedAt": Timestamp.fromDate(updatedAt),
    };
  }

  factory TradePlan.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TradePlan(
      id: doc.id,
      strategyId: data["strategyId"],
      strategyName: data["strategyName"],
      inputs: TradeInputs.fromJson(data["inputs"]),
      payoff: PayoffResult(
        maxGain: data["payoff"]["maxGain"],
        maxLoss: data["payoff"]["maxLoss"],
        breakeven: data["payoff"]["breakeven"],
        capitalRequired: data["payoff"]["capitalRequired"],
      ),
      risk: RiskResult(
        riskPercentOfAccount: data["risk"]["riskPercentOfAccount"],
        assignmentExposure: data["risk"]["assignmentExposure"],
        capitalLocked: data["risk"]["capitalLocked"],
        warnings: List<String>.from(data["risk"]["warnings"]),
      ),
      notes: data["notes"],
      tags: List<String>.from(data["tags"]),
      createdAt: (data["createdAt"] as Timestamp).toDate(),
      updatedAt: (data["updatedAt"] as Timestamp).toDate(),
    );
  }

  factory TradePlan.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseTs(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.parse(v);
      if (v is Map && v.containsKey('_seconds')) {
        final s = v['_seconds'] as int;
        final ns = v['_nanoseconds'] as int? ?? 0;
        final ms = s * 1000 + (ns ~/ 1000000);
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
      throw ArgumentError('Unsupported timestamp format');
    }

    return TradePlan(
      id: id,
      strategyId: data["strategyId"],
      strategyName: data["strategyName"],
      inputs: TradeInputs.fromJson(data["inputs"]),
      payoff: PayoffResult(
        maxGain: (data["payoff"]["maxGain"] as num).toDouble(),
        maxLoss: (data["payoff"]["maxLoss"] as num).toDouble(),
        breakeven: (data["payoff"]["breakeven"] as num).toDouble(),
        capitalRequired: (data["payoff"]["capitalRequired"] as num).toDouble(),
      ),
      risk: RiskResult(
        riskPercentOfAccount: (data["risk"]["riskPercentOfAccount"] as num).toDouble(),
        assignmentExposure: data["risk"]["assignmentExposure"],
        capitalLocked: (data["risk"]["capitalLocked"] as num).toDouble(),
        warnings: List<String>.from(data["risk"]["warnings"]),
      ),
      notes: data["notes"],
      tags: List<String>.from(data["tags"]),
      createdAt: parseTs(data["createdAt"]),
      updatedAt: parseTs(data["updatedAt"]),
    );
  }
}