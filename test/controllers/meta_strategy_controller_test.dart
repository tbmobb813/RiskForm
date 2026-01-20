import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/controllers/meta_strategy_controller.dart';
import 'package:riskform/models/account_snapshot.dart';
import 'package:riskform/models/position.dart';
import 'package:riskform/models/wheel_cycle.dart';
import 'package:riskform/models/risk_profile.dart';

void main() {
  final controller = MetaStrategyController();

  group('Basic Wheel Cycle State Transitions', () {
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
  });

  group('Assignment and Share Ownership States', () {
    test('cspOpen -> assigned when shares appear after CSP', () {
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
          symbol: 'XYZ',
          strategy: 'Shares',
          quantity: 100,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        )
      ];
      final wheel = WheelCycle(state: WheelCycleState.cspOpen);
      final risk = RiskProfile(id: 'r', maxRiskPercent: 2.0);

      final rec = controller.evaluate(
        account: account,
        positions: positions,
        wheel: wheel,
        riskProfile: risk,
      );

      expect(rec.wheelState, WheelCycleState.assigned);
      expect(rec.action, equals('Review Assignment'));
    });

    test('sharesOwned -> ccOpen when CC is sold', () {
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
          symbol: 'XYZ',
          strategy: 'Shares',
          quantity: 100,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
        Position(
          type: PositionType.coveredCall,
          symbol: 'XYZ',
          strategy: 'Covered Call',
          quantity: 1,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        )
      ];
      final wheel = WheelCycle(state: WheelCycleState.sharesOwned);
      final risk = RiskProfile(id: 'r', maxRiskPercent: 2.0);

      final rec = controller.evaluate(
        account: account,
        positions: positions,
        wheel: wheel,
        riskProfile: risk,
      );

      expect(rec.wheelState, WheelCycleState.ccOpen);
      expect(rec.action, equals('Manage Covered Call'));
    });
  });

  group('Edge Cases and Constraints', () {
    test('Idle state with insufficient buying power', () {
      final account = AccountSnapshot(
        accountSize: 10000,
        buyingPower: 50, // Below 2% of 10000 = 200
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

      expect(rec.action, equals('No new trade'));
      expect(rec.reason, contains('below your per-trade risk threshold'));
    });

    test('Called away with insufficient buying power to restart', () {
      final account = AccountSnapshot(
        accountSize: 10000,
        buyingPower: 50, // Below threshold
        sharesOwned: {},
        totalRiskExposurePercent: 0.0,
        wheelState: 'cash',
      );

      final positions = <Position>[];
      final wheel = WheelCycle(state: WheelCycleState.ccOpen);
      final risk = RiskProfile(id: 'r', maxRiskPercent: 2.0);

      final rec = controller.evaluate(
        account: account,
        positions: positions,
        wheel: wheel,
        riskProfile: risk,
      );

      expect(rec.wheelState, WheelCycleState.calledAway);
      expect(rec.action, equals('Wait'));
      expect(rec.reason, contains('below your risk threshold'));
    });

    test('Multiple positions with CSP priority', () {
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
        ),
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

      // CSP should take priority
      expect(rec.wheelState, WheelCycleState.cspOpen);
      expect(rec.action, equals('Manage Open CSP'));
    });
  });
}

