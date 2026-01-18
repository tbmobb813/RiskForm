import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/risk_exposure.dart';
import '../models/position.dart';
import '../screens/dashboard/active_positions_section.dart';
import 'account_context_provider.dart';
import 'risk_profile_provider.dart';

final riskExposureProvider = FutureProvider<RiskExposure>((ref) async {
  final account = await ref.watch(accountContextProvider.future);
  final positions = ref.watch(activePositionsProvider);
  final riskProfile = await ref.watch(riskProfileProvider.future);

  // Simple heuristic: each position counts as ~1% risk of account by default
  final base = positions.length * 1.0;

  // Normalize by account size (very small accounts get higher percent)
  final normalized = account.accountSize > 0 ? (base / (account.accountSize / 1000)) : base;
  final totalRisk = normalized.clamp(0.0, 100.0);

  final assignmentExposure = positions.any((p) => p.type == PositionType.csp || p.type == PositionType.coveredCall);

  final warnings = <String>[];
  if (totalRisk > (riskProfile.maxRiskPercent * 2)) {
    warnings.add('High portfolio risk relative to profile');
  }

  return RiskExposure(
    totalRiskPercent: totalRisk,
    assignmentExposure: assignmentExposure,
    warnings: warnings,
  );
});
