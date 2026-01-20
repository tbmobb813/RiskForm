import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/journal/live_trade_ingestion_service.dart';
import 'package:riskform/models/trade/live_trade_event.dart';
import 'package:riskform/services/journal/journal_repository.dart';

void main() {
  group('LiveTradeIngestionService', () {
    test('ingest creates a live journal entry with correct fields', () async {
      final repo = JournalRepository();
      final svc = LiveTradeIngestionService(repo: repo);

      final event = LiveTradeEvent(
        id: 't1',
        timestamp: DateTime(2025, 1, 1, 12),
        symbol: 'SPY',
        type: LiveTradeType.openCsp,
        price: 100.0,
        quantity: 1,
        strike: 100.0,
        expiry: DateTime(2025, 2, 1),
      );

      await svc.ingest(event);

      final all = repo.getAll();
      expect(all.length, 1);
      final entry = all.first;
      expect(entry.data['symbol'], 'SPY');
      expect(entry.data['price'], 100.0);
      expect(entry.data['quantity'], 1);
      expect(entry.data['live'], true);
      expect(entry.data['rawType'], contains('LiveTradeType'));
    });

    test('ingest maps assignment and calledAway types correctly', () async {
      final repo = JournalRepository();
      final svc = LiveTradeIngestionService(repo: repo);

      final ev1 = LiveTradeEvent(
        id: 'a1',
        timestamp: DateTime(2025, 1, 2),
        symbol: 'SPY',
        type: LiveTradeType.assignment,
        price: 99.0,
        quantity: 100,
      );

      final ev2 = LiveTradeEvent(
        id: 'c1',
        timestamp: DateTime(2025, 1, 2),
        symbol: 'SPY',
        type: LiveTradeType.calledAway,
        price: 101.0,
        quantity: 100,
      );

      await svc.ingest(ev1);
      await svc.ingest(ev2);

      final all = repo.getAll();
      final assignments = all.where((e) => e.type == 'assignment').toList();
      final calledAways = all.where((e) => e.type == 'calledAway').toList();

      expect(assignments.length, 1);
      expect(calledAways.length, 1);
    });
  });
}
