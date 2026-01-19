import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/controllers/meta_strategy_controller.dart';
import 'package:flutter_application_2/models/account_snapshot.dart';
import 'package:flutter_application_2/models/position.dart';
import 'package:flutter_application_2/models/wheel_cycle.dart';
import 'package:flutter_application_2/models/risk_profile.dart';

void main() {
  final controller = MetaStrategyController();

  group('MetaStrategyController wheel state detection', () {
    test('CSP open only -> cspOpen', () {
      final positions = [
        Position(
          type: PositionType.csp,
          symbol: 'ABC',
          strategy: 'csp',
          quantity: 1,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
      ];

      final wheel = WheelCycle(state: WheelCycleState.idle);
      final account = AccountSnapshot(
        accountSize: 10000.0,
        buyingPower: 10000.0,
        sharesOwned: {},
        totalRiskExposurePercent: 0.0,
        wheelState: 'cash',
      );
      final risk = RiskProfile(id: 'r', maxRiskPercent: 1.0);

      final rec = controller.evaluate(
        account: account,
        positions: positions,
        wheel: wheel,
        riskProfile: risk,
      );

      expect(rec.wheelState, WheelCycleState.cspOpen);
    });

    test('Shares present and prior wheel cspOpen -> assigned', () {
      final positions = [
        Position(
          type: PositionType.csp,
          symbol: 'ABC',
          strategy: 'csp',
          quantity: 1,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
        Position(
          type: PositionType.shares,
          symbol: 'ABC',
          strategy: 'shares',
          quantity: 100,
          expiration: DateTime.now().add(const Duration(days: 90)),
          isOpen: true,
        ),
      ];

      final wheel = WheelCycle(state: WheelCycleState.cspOpen);
      final account = AccountSnapshot(
        accountSize: 10000.0,
        buyingPower: 10000.0,
        sharesOwned: {'ABC': 100},
        totalRiskExposurePercent: 0.0,
        wheelState: 'short_put',
      );
      final risk = RiskProfile(id: 'r', maxRiskPercent: 1.0);

      final rec = controller.evaluate(
        account: account,
        positions: positions,
        wheel: wheel,
        riskProfile: risk,
      );

      expect(rec.wheelState, WheelCycleState.assigned);
    });

    test('Shares and open covered call -> ccOpen', () {
      final positions = [
        Position(
          type: PositionType.shares,
          symbol: 'XYZ',
          strategy: 'shares',
          quantity: 100,
          expiration: DateTime.now().add(const Duration(days: 90)),
          isOpen: true,
        ),
        Position(
          type: PositionType.coveredCall,
          symbol: 'XYZ',
          strategy: 'cc',
          quantity: 1,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
      ];

      final wheel = WheelCycle(state: WheelCycleState.sharesOwned);
      final account = AccountSnapshot(
        accountSize: 10000.0,
        buyingPower: 10000.0,
        sharesOwned: {'XYZ': 100},
        totalRiskExposurePercent: 0.0,
        wheelState: 'shares_owned',
      );
      final risk = RiskProfile(id: 'r', maxRiskPercent: 1.0);

      final rec = controller.evaluate(
        account: account,
        positions: positions,
        wheel: wheel,
        riskProfile: risk,
      );

      expect(rec.wheelState, WheelCycleState.ccOpen);
    });

    test('Shares only -> sharesOwned', () {
      final positions = [
        Position(
          type: PositionType.shares,
          symbol: 'XYZ',
          strategy: 'shares',
          quantity: 150,
          expiration: DateTime.now().add(const Duration(days: 90)),
          isOpen: true,
        ),
      ];

      final wheel = WheelCycle(state: WheelCycleState.idle);
      final account = AccountSnapshot(
        accountSize: 10000.0,
        buyingPower: 10000.0,
        sharesOwned: {'XYZ': 150},
        totalRiskExposurePercent: 0.0,
        wheelState: 'shares_owned',
      );
      final risk = RiskProfile(id: 'r', maxRiskPercent: 1.0);

      final rec = controller.evaluate(
        account: account,
        positions: positions,
        wheel: wheel,
        riskProfile: risk,
      );

      expect(rec.wheelState, WheelCycleState.sharesOwned);
    });

    test('Transient: CSP marked open but shares + prior cspOpen -> assigned (duplicate CSP)', () {
      final positions = [
        // duplicate CSP record that might still be present
        Position(
          type: PositionType.csp,
          symbol: 'DUP',
          strategy: 'csp',
          quantity: 1,
          expiration: DateTime.now().add(const Duration(days: 2)),
          isOpen: true,
        ),
        // shares indicate assignment occurred
        Position(
          type: PositionType.shares,
          symbol: 'DUP',
          strategy: 'shares',
          quantity: 100,
          expiration: DateTime.now().add(const Duration(days: 90)),
          isOpen: true,
        ),
      ];

      final wheel = WheelCycle(state: WheelCycleState.cspOpen);
      final account = AccountSnapshot(
        accountSize: 10000.0,
        buyingPower: 10000.0,
        sharesOwned: {'DUP': 100},
        totalRiskExposurePercent: 0.0,
        wheelState: 'short_put',
      );
      final risk = RiskProfile(id: 'r', maxRiskPercent: 1.0);

      final rec = controller.evaluate(
        account: account,
        positions: positions,
        wheel: wheel,
        riskProfile: risk,
      );

      expect(rec.wheelState, WheelCycleState.assigned);
    });

    test('Edge: hasOpenCsp true but wheel not cspOpen and shares present -> sharesOwned', () {
      final positions = [
        Position(
          type: PositionType.csp,
          symbol: 'E1',
          strategy: 'csp',
          quantity: 1,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
        Position(
          type: PositionType.shares,
          symbol: 'E1',
          strategy: 'shares',
          quantity: 100,
          expiration: DateTime.now().add(const Duration(days: 90)),
          isOpen: true,
        ),
      ];

      // Wheel state does not indicate a prior CSP open
      final wheel = WheelCycle(state: WheelCycleState.idle);
      final account = AccountSnapshot(
        accountSize: 10000.0,
        buyingPower: 10000.0,
        sharesOwned: {'E1': 100},
        totalRiskExposurePercent: 0.0,
        wheelState: 'shares_owned',
      );
      final risk = RiskProfile(id: 'r', maxRiskPercent: 1.0);

      final rec = controller.evaluate(
        account: account,
        positions: positions,
        wheel: wheel,
        riskProfile: risk,
      );

      expect(rec.wheelState, WheelCycleState.cspOpen);
    });
  });
}
