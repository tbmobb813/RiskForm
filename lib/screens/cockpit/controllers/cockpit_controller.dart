import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/cockpit_state.dart';
import '../models/pending_journal_trade.dart';
import '../models/watchlist_item.dart';
import '../models/discipline_snapshot.dart';
import '../models/weekly_summary.dart';
import '../../../services/firebase/position_service.dart';
import '../../../regime/regime_service.dart';
import '../../../state/account_providers.dart';
import '../services/cockpit_data_client.dart';

/// Controller for the Small Account Cockpit.
///
/// Provides a lightweight, analyzer-friendly implementation used by the
/// UI while the full data-loading logic is restored. Methods here mutate
/// the `CockpitState` in-memory so callers (debug screens, services) compile.
class CockpitController extends StateNotifier<CockpitState> {
  final dynamic _ref;
  final CockpitDataClient _dataClient;
  final String? Function()? _getUid;
  final RegimeService? _regimeService;

  CockpitController(this._ref, {CockpitDataClient? dataClient, String? Function()? getUid, RegimeService? regimeService})
      : _dataClient = dataClient ?? DefaultCockpitDataClient(_ref.read(positionServiceProvider)),
        _getUid = getUid,
        _regimeService = regimeService,
        super(CockpitState.initial());

  /// Refresh cockpit data by loading from Firestore and local services.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);

    final uid = _getUid?.call() ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      // Watchlist, pending journals, and recent journals from data client
      final watchlist = <WatchlistItem>[];
      final wl = await _dataClient.fetchWatchlist(uid);
      for (final t in wl) {
        watchlist.add(WatchlistItem.placeholder(t));
      }

      final pending = <PendingJournalTrade>[];
      final pj = await _dataClient.fetchPendingJournals(uid);
      for (final j in pj) {
        try {
          pending.add(PendingJournalTrade.fromJson(j));
        } catch (_) {}
      }

      final positionsRaw = await _dataClient.fetchOpenPositions(uid);
      final positions = positionsRaw.map((p) {
        final id = '${p.symbol}-${p.expiration.toIso8601String()}';
        return OpenPosition(
          id: id,
          ticker: p.symbol,
          strategy: p.strategy,
          strike: 0.0,
          dte: p.dte,
          thetaPerDay: 0.0,
          unrealizedPnL: 0.0,
          isPaper: true,
        );
      }).toList();

      // Discipline: compute from recent journal entries
      final recent = await _dataClient.fetchRecentJournals(uid);
      final scores = <int>[];
      final adherence = <int>[];
      for (final d in recent) {
        final s = (d['disciplineScore'] is num) ? (d['disciplineScore'] as num).toInt() : null;
        if (s != null) {
          scores.add(s);
        }
        final a = (d['disciplineBreakdown'] is Map && (d['disciplineBreakdown']['adherence'] is num))
            ? (d['disciplineBreakdown']['adherence'] as num).toInt()
            : null;
        if (a != null) {
          adherence.add(a);
        }
      }

      final avgScore = scores.isNotEmpty ? (scores.reduce((a, b) => a + b) ~/ scores.length) : 0;

      int cleanStreak = 0;
      for (final s in scores) {
        if (s >= 80) {
          cleanStreak++;
        } else {
          break;
        }
      }

      int adherenceStreak = 0;
      for (final a in adherence) {
        if (a >= 30) {
          adherenceStreak++;
        } else {
          break;
        }
      }

      final discipline = DisciplineSnapshot.fromScore(
        score: avgScore,
        cleanStreak: cleanStreak,
        adherenceStreak: adherenceStreak,
        pendingJournals: pending.length,
      );

      // Account snapshot from app providers
      final balance = _ref.read(accountBalanceProvider);
      final riskDeployed = _ref.read(riskDeployedProvider);
      final account = AccountSnapshot.fromBalance(balance: balance, riskDeployed: riskDeployed, openPositions: positions.length);

      // Weekly summary (placeholder)
      final weekSummary = WeeklySummary.empty();

      // Regime (best-effort)
      final regimeService = _regimeService ?? RegimeService();
      final currentRegimeStr = await regimeService.watchCurrentRegime().first;
      MarketRegime regime = MarketRegime.unknown;
      if (currentRegimeStr != null) {
        switch (currentRegimeStr.toLowerCase()) {
          case 'uptrend':
            regime = MarketRegime.uptrend;
            break;
          case 'downtrend':
            regime = MarketRegime.downtrend;
            break;
          case 'sideways':
            regime = MarketRegime.sideways;
            break;
          case 'volatile':
            regime = MarketRegime.volatile;
            break;
          default:
            regime = MarketRegime.unknown;
        }
      }

      state = state.copyWith(
        isLoading: false,
        watchlist: watchlist,
        pendingJournals: pending,
        positions: positions,
        discipline: discipline,
        account: account,
        weekSummary: weekSummary,
        regime: regime,
      );
    } catch (e) {
      // On error, stop loading and keep previous state
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Add a pending journal entry
  Future<void> addPendingJournal(PendingJournalTrade trade) async {
    final list = List<PendingJournalTrade>.from(state.pendingJournals);
    list.add(trade);
    state = state.copyWith(pendingJournals: list);
  }

  /// Remove a pending journal by position id
  Future<void> removePendingJournal(String positionId) async {
    final list = state.pendingJournals.where((p) => p.positionId != positionId).toList();
    state = state.copyWith(pendingJournals: list);
  }

  /// Add ticker to watchlist (max 5 for small accounts)
  Future<void> addToWatchlist(String ticker) async {
    final items = List<WatchlistItem>.from(state.watchlist);
    if (items.any((w) => w.ticker == ticker)) return;
    if (items.length >= 5) throw Exception('Watchlist is full');
    items.add(WatchlistItem(ticker: ticker));
    state = state.copyWith(watchlist: items);
  }

  /// Remove ticker from watchlist
  Future<void> removeFromWatchlist(String ticker) async {
    final items = state.watchlist.where((w) => w.ticker != ticker).toList();
    state = state.copyWith(watchlist: items);
  }
}

final cockpitControllerProvider = StateNotifierProvider<CockpitController, CockpitState>((ref) {
  return CockpitController(ref);
});
