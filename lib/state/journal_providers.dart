import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/journal/journal_repository.dart';
import '../services/journal/journal_automation_service.dart';
import '../services/journal/live_trade_ingestion_service.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository();
});

final journalAutomationProvider = Provider<JournalAutomationService>((ref) {
  final repo = ref.read(journalRepositoryProvider);
  return JournalAutomationService(repo: repo);
});

final liveTradeIngestionProvider = Provider<LiveTradeIngestionService>((ref) {
  final repo = ref.read(journalRepositoryProvider);
  return LiveTradeIngestionService(repo: repo);
});
