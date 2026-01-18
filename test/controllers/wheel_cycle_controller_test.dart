import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/controllers/wheel_cycle_controller.dart';
import 'package:flutter_application_2/models/wheel_cycle.dart';
import 'package:flutter_application_2/models/position.dart';

void main() {
  final controller = WheelCycleController();

  group('WheelCycleController - State Transitions', () {
    test('idle -> cspOpen when CSP is opened', () {
      final previous = WheelCycle(state: WheelCycleState.idle);
      final positions = [
        Position(
          type: PositionType.csp,
          symbol: 'AAPL',
          strategy: 'CSP',
          quantity: 1,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
      ];

      final newState = controller.determineState(
        previous: previous,
        positions: positions,
      );

      expect(newState, equals(WheelCycleState.cspOpen));
    });

    test('cspOpen -> assigned when shares appear after CSP', () {
      final previous = WheelCycle(state: WheelCycleState.cspOpen);
      final positions = [
        Position(
          type: PositionType.shares,
          symbol: 'AAPL',
          strategy: 'Shares',
          quantity: 100,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
      ];

      final newState = controller.determineState(
        previous: previous,
        positions: positions,
      );

      expect(newState, equals(WheelCycleState.assigned));
    });

    test('assigned -> sharesOwned when CSP is closed and shares remain', () {
      final previous = WheelCycle(state: WheelCycleState.assigned);
      final positions = [
        Position(
          type: PositionType.shares,
          symbol: 'AAPL',
          strategy: 'Shares',
          quantity: 100,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
      ];

      final newState = controller.determineState(
        previous: previous,
        positions: positions,
      );

      expect(newState, equals(WheelCycleState.sharesOwned));
    });

    test('sharesOwned -> ccOpen when covered call is opened', () {
      final previous = WheelCycle(state: WheelCycleState.sharesOwned);
      final positions = [
        Position(
          type: PositionType.shares,
          symbol: 'AAPL',
          strategy: 'Shares',
          quantity: 100,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
        Position(
          type: PositionType.coveredCall,
          symbol: 'AAPL',
          strategy: 'Covered Call',
          quantity: 1,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
      ];

      final newState = controller.determineState(
        previous: previous,
        positions: positions,
      );

      expect(newState, equals(WheelCycleState.ccOpen));
    });

    test('ccOpen -> calledAway when shares and CC are closed', () {
      final previous = WheelCycle(state: WheelCycleState.ccOpen);
      final positions = <Position>[];

      final newState = controller.determineState(
        previous: previous,
        positions: positions,
      );

      expect(newState, equals(WheelCycleState.calledAway));
    });

    test('calledAway -> idle when new cycle begins', () {
      final previous = WheelCycle(state: WheelCycleState.calledAway);
      final positions = <Position>[];

      final newState = controller.determineState(
        previous: previous,
        positions: positions,
      );

      expect(newState, equals(WheelCycleState.idle));
    });

    test('returns idle when no positions and previous state is idle', () {
      final previous = WheelCycle(state: WheelCycleState.idle);
      final positions = <Position>[];

      final newState = controller.determineState(
        previous: previous,
        positions: positions,
      );

      expect(newState, equals(WheelCycleState.idle));
    });

    test('CSP takes priority over shares in state determination', () {
      final previous = WheelCycle(state: WheelCycleState.idle);
      final positions = [
        Position(
          type: PositionType.csp,
          symbol: 'AAPL',
          strategy: 'CSP',
          quantity: 1,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
        Position(
          type: PositionType.shares,
          symbol: 'AAPL',
          strategy: 'Shares',
          quantity: 100,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
      ];

      final newState = controller.determineState(
        previous: previous,
        positions: positions,
      );

      expect(newState, equals(WheelCycleState.cspOpen));
    });

    test('handles multiple positions of same type', () {
      final previous = WheelCycle(state: WheelCycleState.idle);
      final positions = [
        Position(
          type: PositionType.csp,
          symbol: 'AAPL',
          strategy: 'CSP',
          quantity: 1,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
        Position(
          type: PositionType.csp,
          symbol: 'MSFT',
          strategy: 'CSP',
          quantity: 1,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
      ];

      final newState = controller.determineState(
        previous: previous,
        positions: positions,
      );

      expect(newState, equals(WheelCycleState.cspOpen));
    });

    test('does not transition to assigned if shares existed before CSP', () {
      final previous = WheelCycle(state: WheelCycleState.idle);
      final positions = [
        Position(
          type: PositionType.shares,
          symbol: 'AAPL',
          strategy: 'Shares',
          quantity: 100,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
      ];

      final newState = controller.determineState(
        previous: previous,
        positions: positions,
      );

      expect(newState, equals(WheelCycleState.sharesOwned));
    });

    test('handles shares with quantity less than 100', () {
      final previous = WheelCycle(state: WheelCycleState.cspOpen);
      final positions = [
        Position(
          type: PositionType.shares,
          symbol: 'AAPL',
          strategy: 'Shares',
          quantity: 50,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: true,
        ),
      ];

      final newState = controller.determineState(
        previous: previous,
        positions: positions,
      );

      // Should transition to idle since we need >= 100 shares for wheel strategy
      expect(newState, equals(WheelCycleState.idle));
    });

    test('closed CSP does not trigger cspOpen state', () {
      final previous = WheelCycle(state: WheelCycleState.idle);
      final positions = [
        Position(
          type: PositionType.csp,
          symbol: 'AAPL',
          strategy: 'CSP',
          quantity: 1,
          expiration: DateTime.now().add(const Duration(days: 30)),
          isOpen: false,
        ),
      ];

      final newState = controller.determineState(
        previous: previous,
        positions: positions,
      );

      expect(newState, equals(WheelCycleState.idle));
    });
  });
}
