import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account_snapshot.dart';
import '../models/strategy_recommendation.dart';

import 'account_context_provider.dart';
import '../screens/dashboard/active_positions_section.dart';
import 'risk_profile_provider.dart';
import 'wheel_cycle_provider.dart';
import 'meta_strategy_provider.dart';

final metaStrategySnapshotProvider =
    FutureProvider<StrategyRecommendation>((ref) async {
  final accountCtx = await ref.watch(accountContextProvider.future);
  final positions = ref.watch(activePositionsProvider);
  final riskProfile = await ref.watch(riskProfileProvider.future);
  final wheel = await ref.watch(wheelCycleProvider.future);

  final controller = ref.read(metaStrategyControllerProvider);

  // Build a minimal AccountSnapshot from AccountContext
  final account = AccountSnapshot(
    accountSize: accountCtx.accountSize,
    buyingPower: accountCtx.buyingPower,
    sharesOwned: {},
    totalRiskExposurePercent: 0.0,
    wheelState: 'cash',
  );

  return controller.evaluate(
    account: account,
    positions: positions,
    wheel: wheel,
    riskProfile: riskProfile,
  );
});