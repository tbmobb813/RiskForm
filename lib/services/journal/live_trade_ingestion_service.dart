import 'dart:math';

import '../../models/trade/live_trade_event.dart';
import '../../models/journal/journal_entry.dart';
import 'journal_repository.dart';

class LiveTradeIngestionService {
  final JournalRepository repo;

  LiveTradeIngestionService({required this.repo});

  String _id() => '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(100000)}';

  Future<void> ingest(LiveTradeEvent event) async {
    final entry = JournalEntry(
      id: _id(),
      timestamp: event.timestamp,
      type: _mapType(event.type),
      data: {
        'symbol': event.symbol,
        'price': event.price,
        'quantity': event.quantity,
        'strike': event.strike,
        'expiry': event.expiry?.toIso8601String(),
        'live': true,
        'rawType': event.type.toString(),
      },
    );

    await repo.addEntry(entry);
  }

  String _mapType(LiveTradeType t) {
    switch (t) {
      case LiveTradeType.assignment:
        return 'assignment';
      case LiveTradeType.calledAway:
        return 'calledAway';
      default:
        return 'liveTrade';
    }
  }
}
