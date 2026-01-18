import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/controllers/meta_strategy_controller.dart';
import 'package:flutter_application_2/models/account_snapshot.dart';
import 'package:flutter_application_2/models/position.dart';
import 'package:flutter_application_2/models/wheel_cycle.dart';
import 'package:flutter_application_2/models/risk_profile.dart';

void main() {
  final controller = MetaStrategyController();

  test('Idle -> Sell CSP when buying power sufficient', () {
    final account = AccountSnapshot(
      accountSize: 10000,
      buyingPower: 1000,
      sharesOwned: {},
      totalRiskExposurePercent: 0.0,
      wheelState: 'cash',
    );

    final positions = <Position>[];
    final wheel = WheelCycle(state: WheelCycleState.idle);
    final risk = RiskProfile(id: 'r', maxRiskPercent: 2.0);

    final rec = controller.evaluate(
      account: account,
      positions: positions,
      wheel: wheel,
      riskProfile: risk,
    );

    expect(rec.action, equals('Sell Cash-Secured Put'));
    expect(rec.wheelState, WheelCycleState.idle);
  });

  test('CSP open -> Manage Open CSP', () {
    final account = AccountSnapshot(
      accountSize: 10000,
      buyingPower: 1000,
      sharesOwned: {},
      totalRiskExposurePercent: 0.0,
      wheelState: 'cash',
    );

    final positions = [
      Position(
        type: PositionType.csp,
        symbol: 'XYZ',
        strategy: 'CSP',
        quantity: 1,
        expiration: DateTime.now().add(const Duration(days: 30)),
        isOpen: true,
      )
    ];
    final wheel = WheelCycle(state: WheelCycleState.idle);
    final risk = RiskProfile(id: 'r', maxRiskPercent: 2.0);

    final rec = controller.evaluate(
      account: account,
      positions: positions,
      wheel: wheel,
      riskProfile: risk,
    );

    expect(rec.action, equals('Manage Open CSP'));
    expect(rec.wheelState, WheelCycleState.cspOpen);
  });

  test('Shares owned -> Sell Covered Call', () {
    final account = AccountSnapshot(
      accountSize: 10000,
      buyingPower: 1000,
      sharesOwned: {},
      totalRiskExposurePercent: 0.0,
      wheelState: 'cash',
    );

    final positions = [
      Position(
        type: PositionType.shares,
        symbol: 'ABC',
        strategy: 'Shares',
        quantity: 100,
        expiration: DateTime.now().add(const Duration(days: 30)),
        isOpen: true,
      )
    ];
    final wheel = WheelCycle(state: WheelCycleState.idle);
    final risk = RiskProfile(id: 'r', maxRiskPercent: 2.0);

    final rec = controller.evaluate(
      account: account,
      positions: positions,
      wheel: wheel,
      riskProfile: risk,
    );

    expect(rec.action, equals('Sell Covered Call'));
    expect(rec.wheelState, WheelCycleState.sharesOwned);
  });

  test('Called away detection -> Restart Wheel', () {
    final account = AccountSnapshot(
      accountSize: 10000,
      buyingPower: 1000,
      sharesOwned: {},
      totalRiskExposurePercent: 0.0,
      wheelState: 'cash',
    );

    final positions = <Position>[]; // no positions
    final wheel = WheelCycle(state: WheelCycleState.ccOpen);
    final risk = RiskProfile(id: 'r', maxRiskPercent: 2.0);

    final rec = controller.evaluate(
      account: account,
      positions: positions,
      wheel: wheel,
      riskProfile: risk,
    );

    expect(rec.wheelState, WheelCycleState.calledAway);
    expect(rec.action, equals('Restart Wheel with CSP'));
  });
}
