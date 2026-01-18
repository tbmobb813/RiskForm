import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trade_plan.dart';
import '../../models/position.dart';
import '../../models/wheel_cycle.dart';
import '../firebase/trade_plan_service.dart';
import '../firebase/auth_service.dart';
import '../firebase/wheel_cycle_service.dart';
import 'position_repository.dart';

final tradePlanRepositoryProvider = Provider<TradePlanRepository>((ref) {
  final service = ref.read(tradePlanServiceProvider);
  final auth = ref.read(authServiceProvider);
  final wheel = ref.read(wheelCycleServiceProvider);
  final positions = ref.read(positionRepositoryProvider);
  return TradePlanRepository(service, auth, wheel, positions);
});

class TradePlanRepository {
  final TradePlanService _service;
  final AuthService _auth;
  final WheelCycleService _wheelService;
  final PositionRepository _positionsRepository;

  TradePlanRepository(this._service, this._auth, [WheelCycleService? wheel, PositionRepository? positions])
      : _wheelService = wheel ?? WheelCycleService(),
        _positionsRepository = positions ?? PositionRepository();

  Future<void> savePlan(TradePlan plan) async {
    final uid = _auth.currentUserId;
    if (uid == null) throw Exception("User not logged in.");

    await _service.savePlan(uid: uid, plan: plan);
  }

  /// Save the plan and recompute the wheel cycle.
  /// If [persistPlan] is false, the method will only run the wheel update
  /// (useful when the plan was already persisted by another path).
  Future<void> savePlanAndUpdateWheel(TradePlan plan, {bool persistPlan = true}) async {
    final uid = _auth.currentUserId;
    if (uid == null) throw Exception("User not logged in.");

    if (persistPlan) {
      await _service.savePlan(uid: uid, plan: plan);
    }

    // 2) Try to fetch latest positions from the authoritative positions repository
    List<Position> positions = await _positionsRepository.listAll();

    // 3) If positions are empty (positions service not implemented), fall back to
    // inferring minimal positions from the plan intent so the wheel can still update.
    if (positions.isEmpty) {
      final inferred = <Position>[];
      if (plan.strategyId == "csp") {
        inferred.add(Position(
          type: PositionType.csp,
          symbol: plan.strategyName,
          strategy: plan.strategyName,
          quantity: plan.inputs.sharesOwned ?? 0,
          expiration: plan.inputs.expiration ?? DateTime.now(),
          isOpen: true,
        ));
      } else if (plan.strategyId == "cc") {
        inferred.add(Position(
          type: PositionType.coveredCall,
          symbol: plan.strategyName,
          strategy: plan.strategyName,
          quantity: plan.inputs.sharesOwned ?? 0,
          expiration: plan.inputs.expiration ?? DateTime.now(),
          isOpen: true,
        ));
      }

      positions = inferred;
    }

    if (positions.isEmpty) return;

    final previous = await _wheelService.getCycle(uid) ??
        WheelCycle(state: WheelCycleState.idle);

    await _wheelService.updateCycle(
      uid: uid,
      previous: previous,
      positions: positions,
    );
  }

  Future<List<TradePlan>> fetchPlans() async {
    final uid = _auth.currentUserId;
    if (uid == null) throw Exception("User not logged in.");

    return _service.fetchPlans(uid);
  }
}