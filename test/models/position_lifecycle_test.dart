import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/models/position.dart';

void main() {
  group('Position lifecycle heuristics', () {
    test('stage derives early/mid/late from DTE', () {
      final now = DateTime.now();

      final early = Position(
        type: PositionType.coveredCall,
        symbol: 'EARLY',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 120)),
        isOpen: true,
      );
      expect(early.stage, PositionStage.early);

      final mid = Position(
        type: PositionType.coveredCall,
        symbol: 'MID',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 30)),
        isOpen: true,
      );
      expect(mid.stage, PositionStage.mid);

      final late = Position(
        type: PositionType.coveredCall,
        symbol: 'LATE',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 10)),
        isOpen: true,
      );
      expect(late.stage, PositionStage.late);
    });

    test('assignmentProbability ranges and strategy adjustment', () {
      final now = DateTime.now();

      // Long-dated covered call (low probability)
      final longCc = Position(
        type: PositionType.coveredCall,
        symbol: 'LONGCC',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 180)),
        isOpen: true,
      );
      expect(longCc.assignmentProbability >= 0.0, isTrue);
      expect(longCc.assignmentProbability <= 0.1, isTrue);

      // Near-term CSP should have higher probability and slightly higher than CC
      final nearCsp = Position(
        type: PositionType.csp,
        symbol: 'NEARCSP',
        strategy: 'CSP',
        quantity: 1,
        expiration: now.add(const Duration(days: 5)),
        isOpen: true,
      );

      final nearCc = Position(
        type: PositionType.coveredCall,
        symbol: 'NEARCC',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 5)),
        isOpen: true,
      );

      expect(nearCsp.assignmentProbability > nearCc.assignmentProbability, isTrue);
      expect(nearCsp.assignmentProbability >= 0.6, isTrue);
      expect(nearCsp.assignmentProbability <= 1.0, isTrue);

      // Mid-term expectation
      final mid = Position(
        type: PositionType.coveredCall,
        symbol: 'MID2',
        strategy: 'CC',
        quantity: 1,
        expiration: now.add(const Duration(days: 40)),
        isOpen: true,
      );
      expect(mid.assignmentProbability >= 0.05, isTrue);
      expect(mid.assignmentProbability <= 0.5, isTrue);

      // Shares should be zero
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
  });
}
