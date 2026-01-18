import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/controllers/meta_strategy_controller.dart';
import 'package:flutter_application_2/models/wheel_cycle.dart';
import 'package:flutter_application_2/models/position.dart';
import 'package:flutter_application_2/models/account_snapshot.dart';
import 'package:flutter_application_2/models/risk_profile.dart';

void main() {
  test('MetaStrategyController returns assigned when previous wheel state was cspOpen and shares are present', () {
    final controller = MetaStrategyController();

    final account = AccountSnapshot(
      accountSize: 10000.0,
      buyingPower: 10000.0,
      sharesOwned: {'AAPL': 100},
      totalRiskExposurePercent: 0.0,
      wheelState: 'cash',
    );
    final risk = RiskProfile(id: 'default', maxRiskPercent: 2.0);

    final wheel = WheelCycle(state: WheelCycleState.cspOpen);

    final positions = [
      Position(
        type: PositionType.shares,
        symbol: 'AAPL',
        strategy: 'Shares',
        quantity: 100,
        expiration: DateTime.now().add(const Duration(days: 30)),
        isOpen: true,
      )
    ];

    final rec = controller.evaluate(
      account: account,
      positions: positions,
      wheel: wheel,
      riskProfile: risk,
    );

    expect(rec.wheelState, WheelCycleState.assigned);
  });
}
