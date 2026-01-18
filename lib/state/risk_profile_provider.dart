import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/risk_profile.dart';

final riskProfileProvider = FutureProvider<RiskProfile>((ref) async {
  // Placeholder: return a default risk profile. Replace with repo lookup later.
  return RiskProfile(id: 'default', maxRiskPercent: 2.0);
});
