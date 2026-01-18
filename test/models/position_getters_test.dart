import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/position.dart';

void main() {
  group('Position getters', () {
    test('lifecycleStage maps DTE to Early/Mid/Late', () {
      final now = DateTime.now();

      final early = Position(
        type: PositionType.coveredCall,
        symbol: 'EARLY',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 60)),
        isOpen: true,
      );
      expect(early.lifecycleStage, 'Early');

      final mid = Position(
        type: PositionType.coveredCall,
        symbol: 'MID',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 20)),
        isOpen: true,
      );
      expect(mid.lifecycleStage, 'Mid');

      final late = Position(
        type: PositionType.coveredCall,
        symbol: 'LATE',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 5)),
        isOpen: true,
      );
      expect(late.lifecycleStage, 'Late');
    });

    test('assignmentProbability heuristic behaves as expected', () {
      final now = DateTime.now();

      final long = Position(
        type: PositionType.coveredCall,
        symbol: 'LONG',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 100)),
        isOpen: true,
      );
      expect(long.assignmentProbability, 0.10);

      final mid = Position(
        type: PositionType.coveredCall,
        symbol: 'MID',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 15)),
        isOpen: true,
      );
      expect(mid.assignmentProbability, 0.25);

      final near = Position(
        type: PositionType.coveredCall,
        symbol: 'NEAR',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 7)),
        isOpen: true,
      );
      expect(near.assignmentProbability, 0.50);

      final shares = Position(
        type: PositionType.shares,
        symbol: 'SHR',
        strategy: 'Shares',
        quantity: 10,
        expiration: now.add(const Duration(days: 30)),
        isOpen: true,
      );
      expect(shares.assignmentProbability, 0.0);
    });

    test('daysUntilExpiration is positive for future expiration', () {
      final now = DateTime.now();
      final pos = Position(
        type: PositionType.coveredCall,
        symbol: 'POS',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 10)),
        isOpen: true,
      );

      expect(pos.daysUntilExpiration > 0, isTrue);
    });

    test('timeDecayImpact matches lifecycle', () {
      final now = DateTime.now();
      final low = Position(
        type: PositionType.coveredCall,
        symbol: 'LOW',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 40)),
        isOpen: true,
      );
      expect(low.timeDecayImpact, 'Low');

      final mod = Position(
        type: PositionType.coveredCall,
        symbol: 'MOD',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 15)),
        isOpen: true,
      );
      expect(mod.timeDecayImpact, 'Moderate');

      final high = Position(
        type: PositionType.coveredCall,
        symbol: 'HIGH',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 5)),
        isOpen: true,
      );
      expect(high.timeDecayImpact, 'High');
    });
  });
}
