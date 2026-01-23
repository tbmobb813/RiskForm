import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pending_journal_trade.dart';
import '../controllers/cockpit_controller.dart';

/// Service for managing pending journal trades
///
/// Use this to add/remove pending journals when positions close.
/// This enforces the behavioral friction (can't trade without journaling).
class PendingJournalService {
  final Ref ref;

  PendingJournalService(this.ref);

  /// Add a pending journal when a position is closed
  ///
  /// Call this immediately after closing a position:
  /// ```dart
  /// final service = ref.read(pendingJournalServiceProvider);
  /// await service.addPendingJournal(
  ///   positionId: position.id,
  ///   ticker: position.ticker,
  ///   strategy: 'CSP ${position.ticker} \$${position.strike}',
  ///   pnl: position.realizedPnl,
  ///   isPaper: position.isPaper,
  /// );
  /// ```
  Future<void> addPendingJournal({
    required String positionId,
    required String ticker,
    required String strategy,
    required double pnl,
    required bool isPaper,
  }) async {
    final trade = PendingJournalTrade(
      positionId: positionId,
      ticker: ticker,
      strategy: strategy,
      pnl: pnl,
      closedAt: DateTime.now(),
      isPaper: isPaper,
    );

    await ref.read(cockpitControllerProvider.notifier).addPendingJournal(trade);
  }

  /// Remove a pending journal after journaling is complete
  ///
  /// Call this after successfully saving a journal entry:
  /// ```dart
  /// final service = ref.read(pendingJournalServiceProvider);
  /// await service.removePendingJournal(positionId);
  /// ```
  Future<void> removePendingJournal(String positionId) async {
    await ref.read(cockpitControllerProvider.notifier).removePendingJournal(positionId);
  }

  /// Get current pending journals (for debugging)
  List<PendingJournalTrade> get pendingJournals {
    return ref.read(cockpitControllerProvider).pendingJournals;
  }

  /// Check if user is blocked from trading
  bool get isBlocked {
    return ref.read(cockpitControllerProvider).isBlocked;
  }
}

/// Provider for pending journal service
final pendingJournalServiceProvider = Provider((ref) => PendingJournalService(ref));
