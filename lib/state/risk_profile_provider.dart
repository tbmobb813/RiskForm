import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/risk_profile.dart';

final riskProfileProvider = FutureProvider<RiskProfile>((ref) async {
  // TODO: Replace this hardcoded default with user-specific risk profile retrieval from a repository/storage layer.
  // This placeholder undermines the risk management system by returning the same profile for all users.
  return RiskProfile(id: 'default', maxRiskPercent: 2.0);
});
