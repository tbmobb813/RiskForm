import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/journal/journal_repository.dart';
import '../services/firebase/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/journal/journal_automation_service.dart';
import '../services/journal/live_trade_ingestion_service.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  // Provide a Firestore-backed repository when a user is signed in.
  if (uid != null) {
    return JournalRepository(firestore: FirebaseFirestore.instance, userId: uid);
  }
  // Fallback to in-memory repository when not authenticated
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
