import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cockpit_state.dart';
import '../models/discipline_snapshot.dart';
import '../models/pending_journal_trade.dart';
import '../models/watchlist_item.dart';
import '../models/weekly_summary.dart';
import '../../../behavior/behavior_analytics.dart';
import '../../../journal/journal_entry_model.dart';
import '../../../state/account_providers.dart';

/// Controller for the Small Account Cockpit
/// Aggregates data from multiple sources and manages cockpit state
class CockpitController extends StateNotifier<CockpitState> {
  final Ref ref;

  CockpitController(this.ref) : super(CockpitState.initial()) {
    _loadCockpitData();
  }

  /// Load all cockpit data from Firebase and providers
  Future<void> _loadCockpitData() async {
    state = state.copyWith(isLoading: true);

    try {
      // Load discipline snapshot from journal entries
      final discipline = await _loadDisciplineSnapshot();

      // Load account snapshot from providers
      final account = _loadAccountSnapshot();

      // Load pending journals from Firestore
      final pendingJournals = await _loadPendingJournals();

      // Load watchlist from Firestore
      final watchlist = await _loadWatchlist();

      // Load open positions from Firestore (placeholder for now)
      final positions = await _loadOpenPositions();

      // Load weekly summary from journal entries
      final weekSummary = await _loadWeeklySummary();

      // Placeholder regime (until Phase 6 market data)
      const regime = MarketRegime.sideways;

      state = CockpitState(
        discipline: discipline,
        account: account,
        pendingJournals: pendingJournals,
        watchlist: watchlist,
        positions: positions,
        weekSummary: weekSummary,
        regime: regime,
        isLoading: false,
      );
    } catch (e) {
      // On error, show empty state
      state = CockpitState.initial().copyWith(isLoading: false);
    }
  }

  /// Reload cockpit data (e.g., after journaling a trade)
  Future<void> refresh() => _loadCockpitData();

  /// Load discipline snapshot from recent journal entries
  Future<DisciplineSnapshot> _loadDisciplineSnapshot() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return DisciplineSnapshot.empty();

      final snapshot = await FirebaseFirestore.instance
          .collection('journalEntries')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      if (snapshot.docs.isEmpty) {
        return DisciplineSnapshot.empty();
      }

      final entries = snapshot.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList();

      // Calculate current score (average of last 5 trades)
      final lastFive = entries.take(5).toList();
      final avgScore = lastFive.isEmpty ? 0 : (lastFive.map((e) => e.disciplineScore ?? 0).reduce((a, b) => a + b) / lastFive.length).round();

      // Calculate streaks
      final cleanStreak = BehaviorAnalytics.computeCleanCycleStreak(entries);
      final adherenceStreak = BehaviorAnalytics.computeAdherenceStreak(entries);

      // Get pending journal count
      final pendingCount = state.pendingJournals.length;

      return DisciplineSnapshot.fromScore(
        score: avgScore,
        cleanStreak: cleanStreak,
        adherenceStreak: adherenceStreak,
        pendingJournals: pendingCount,
      );
    } catch (e) {
      return DisciplineSnapshot.empty();
    }
  }

  /// Load account snapshot from account providers
  AccountSnapshot _loadAccountSnapshot() {
    final balance = ref.read(accountBalanceProvider);
    final riskDeployed = ref.read(riskDeployedProvider);
    final openPositions = state.positions.length;

    return AccountSnapshot.fromBalance(
      balance: balance,
      riskDeployed: riskDeployed,
      openPositions: openPositions,
    );
  }

  /// Load pending journals from Firestore
  Future<List<PendingJournalTrade>> _loadPendingJournals() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return [];

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('cockpit').doc('pendingJournals').get();

      if (!doc.exists) return [];

      final data = doc.data();
      final journals = data?['journals'] as List<dynamic>? ?? [];

      return journals.map((j) => PendingJournalTrade.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Load watchlist from Firestore
  Future<List<WatchlistItem>> _loadWatchlist() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return _getDefaultWatchlist();

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('cockpit').doc('watchlist').get();

      if (!doc.exists) return _getDefaultWatchlist();

      final tickers = List<String>.from(doc.data()?['tickers'] ?? []);

      // For Phase 1, return placeholder items (no live data)
      return tickers.map((ticker) => WatchlistItem.placeholder(ticker)).toList();
    } catch (e) {
      return _getDefaultWatchlist();
    }
  }

  /// Default watchlist for new users
  List<WatchlistItem> _getDefaultWatchlist() {
    return [
      WatchlistItem.placeholder('SPY'),
      WatchlistItem.placeholder('QQQ'),
      WatchlistItem.placeholder('IWM'),
    ];
  }

  /// Load open positions (placeholder for now)
  Future<List<OpenPosition>> _loadOpenPositions() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return [];

      final snapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('positions').where('status', isEqualTo: 'open').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return OpenPosition.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Load weekly summary from journal entries
  Future<WeeklySummary> _loadWeeklySummary() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return WeeklySummary.empty();

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1, hours: now.hour, minutes: now.minute, seconds: now.second));

      final snapshot = await FirebaseFirestore.instance
          .collection('journalEntries')
          .where('uid', isEqualTo: uid)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .orderBy('createdAt', descending: false)
          .get();

      if (snapshot.docs.isEmpty) {
        return WeeklySummary.empty();
      }

      final entries = snapshot.docs.map((doc) => JournalEntry.fromFirestore(doc)).toList();

      // Calculate weekly stats (placeholder calculations)
      final pnl = 0.0; // TODO: Calculate from actual P/L data
      final pnlPercent = 0.0;
      final trades = entries.length;
      final winRate = 0.0; // TODO: Calculate from actual P/L data
      final avgDiscipline = entries.isEmpty ? 0.0 : entries.map((e) => (e.disciplineScore ?? 0).toDouble()).reduce((a, b) => a + b) / entries.length;

      // Build daily trades
      final dailyTrades = List.generate(7, (i) {
        final day = weekStart.add(Duration(days: i));
        final dayEntries = entries.where((e) => e.createdAt.day == day.day && e.createdAt.month == day.month).toList();

        return DayTrade(
          date: day,
          hadTrade: dayEntries.isNotEmpty,
          wasClean: dayEntries.isNotEmpty && (dayEntries.first.disciplineScore ?? 0) >= 80,
        );
      });

      return WeeklySummary(
        pnl: pnl,
        pnlPercent: pnlPercent,
        trades: trades,
        winRate: winRate,
        avgDiscipline: avgDiscipline,
        dailyTrades: dailyTrades,
      );
    } catch (e) {
      return WeeklySummary.empty();
    }
  }

  /// Add a ticker to watchlist (max 5)
  Future<void> addToWatchlist(String ticker) async {
    if (state.watchlist.length >= 5) {
      throw Exception('Watchlist is limited to 5 tickers for small accounts');
    }

    final newWatchlist = [...state.watchlist, WatchlistItem.placeholder(ticker.toUpperCase())];
    state = state.copyWith(watchlist: newWatchlist);

    // Persist to Firestore
    await _saveWatchlist(newWatchlist.map((w) => w.ticker).toList());
  }

  /// Remove a ticker from watchlist
  Future<void> removeFromWatchlist(String ticker) async {
    final newWatchlist = state.watchlist.where((w) => w.ticker != ticker).toList();
    state = state.copyWith(watchlist: newWatchlist);

    // Persist to Firestore
    await _saveWatchlist(newWatchlist.map((w) => w.ticker).toList());
  }

  /// Save watchlist to Firestore
  Future<void> _saveWatchlist(List<String> tickers) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).collection('cockpit').doc('watchlist').set({
        'tickers': tickers,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Fail silently for now
    }
  }

  /// Mark a trade as requiring journal (called when position closes)
  Future<void> addPendingJournal(PendingJournalTrade trade) async {
    final newPending = [...state.pendingJournals, trade];
    state = state.copyWith(pendingJournals: newPending);

    // Persist to Firestore
    await _savePendingJournals(newPending);

    // Refresh discipline snapshot to update message
    final discipline = await _loadDisciplineSnapshot();
    state = state.copyWith(discipline: discipline);
  }

  /// Remove a pending journal (called after journaling)
  Future<void> removePendingJournal(String positionId) async {
    final newPending = state.pendingJournals.where((p) => p.positionId != positionId).toList();
    state = state.copyWith(pendingJournals: newPending);

    // Persist to Firestore
    await _savePendingJournals(newPending);

    // Refresh discipline snapshot
    await refresh();
  }

  /// Save pending journals to Firestore
  Future<void> _savePendingJournals(List<PendingJournalTrade> pending) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).collection('cockpit').doc('pendingJournals').set({
        'journals': pending.map((p) => p.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Fail silently for now
    }
  }
}

/// Provider for the cockpit controller
final cockpitControllerProvider = StateNotifierProvider<CockpitController, CockpitState>((ref) {
  return CockpitController(ref);
});
