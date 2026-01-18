import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trade_inputs.dart';
import '../../models/payoff_result.dart';
import '../../models/risk_result.dart';

final plannerRepositoryProvider = Provider<PlannerRepository>((ref) {
  return PlannerRepository();
});

class PlannerRepository {
  Future<void> savePlan({
    required String strategyId,
    required String strategyName,
    required TradeInputs inputs,
    required PayoffResult payoff,
    required RiskResult risk,
    required String notes,
    required List<String> tags,
  }) async {
    // TODO: implement Firestore write
    await Future.delayed(const Duration(milliseconds: 300));
  }
}