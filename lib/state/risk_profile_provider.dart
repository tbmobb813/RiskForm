import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/risk_profile.dart';
import '../services/data/risk_profile_repository.dart';

final riskProfileProvider = FutureProvider<RiskProfile>((ref) async {
  final repository = ref.read(riskProfileRepositoryProvider);
  return repository.fetchRiskProfile();
});
