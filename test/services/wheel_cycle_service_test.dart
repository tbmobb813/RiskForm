import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/services/firebase/wheel_cycle_service.dart';
import 'package:flutter_application_2/models/wheel_cycle.dart';
import 'package:flutter_application_2/models/position.dart';

void main() {
  group('WheelCycleService - Cycle Count Logic', () {
    late WheelCycleService service;

    setUp(() {
      service = WheelCycleService();
    });

    test('_incrementCycleCount increments on calledAway -> idle transition', () async {
      final previous = WheelCycle(
        state: WheelCycleState.calledAway,
        cycleCount: 1,
      );

      // Test through updateCycle with persist: false to avoid Firebase calls
      final positions = <Position>[]; // Empty positions leads to idle state
      
      final result = await service.updateCycle(
        uid: 'test-uid',
        previous: previous,
        positions: positions,
        persist: false,
      );

      // Should transition from calledAway to idle and increment count
      expect(result.state, equals(WheelCycleState.idle));
      expect(result.cycleCount, equals(2));
    });

    test('_incrementCycleCount does not increment on other transitions', () async {
      final previous = WheelCycle(
        state: WheelCycleState.cspOpen,
        cycleCount: 1,
      );

      // Create positions that will trigger cspOpen -> assigned transition
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
      
      final result = await service.updateCycle(
        uid: 'test-uid',
        previous: previous,
        positions: positions,
        persist: false,
      );

      // Should transition to assigned but NOT increment count
      expect(result.state, equals(WheelCycleState.assigned));
      expect(result.cycleCount, equals(1));
    });
  });

  group('WheelCycleService - State Deserialization', () {
    late WheelCycleService service;

    setUp(() {
      service = WheelCycleService();
    });

    test('_deserializeState handles string enum names', () {
      final testCases = {
        'idle': WheelCycleState.idle,
        'cspOpen': WheelCycleState.cspOpen,
        'assigned': WheelCycleState.assigned,
        'sharesOwned': WheelCycleState.sharesOwned,
        'ccOpen': WheelCycleState.ccOpen,
        'calledAway': WheelCycleState.calledAway,
      };

      for (final entry in testCases.entries) {
        final result = WheelCycleService.deserializeStateForTesting(entry.key);
        expect(result, equals(entry.value),
        reason: 'String "${entry.key}" should deserialize to ${entry.value}');
      }
    });

    test('_deserializeState falls back to index for legacy data', () {
      final testCases = {
        0: WheelCycleState.idle,
        1: WheelCycleState.cspOpen,
        2: WheelCycleState.assigned,
        3: WheelCycleState.sharesOwned,
        4: WheelCycleState.ccOpen,
        5: WheelCycleState.calledAway,
      };

      for (final entry in testCases.entries) {
        final result = WheelCycleService.deserializeStateForTesting(entry.key);
        expect(result, equals(entry.value),
        reason: 'Integer ${entry.key} should deserialize to ${entry.value}');
      }
    });

    test('_deserializeState defaults to idle for invalid input', () {
      const invalidInputs = [
        'invalid',
        '',
        'unknown',
        -1,
        999,
        null,
        true,
        42.5,
      ];

      for (final invalid in invalidInputs) {
        final result = WheelCycleService.deserializeStateForTesting(invalid);
        expect(result, equals(WheelCycleState.idle),
        reason: 'Invalid input "$invalid" should default to idle');
      }
    });

    test('_deserializeState handles out of bounds integer', () {
      // Test negative index
      expect(WheelCycleService.deserializeStateForTesting(-1), equals(WheelCycleState.idle));
      
      // Test index beyond enum length
      final tooLarge = WheelCycleState.values.length;
      expect(WheelCycleService.deserializeStateForTesting(tooLarge), equals(WheelCycleState.idle));
    });
  });
}

