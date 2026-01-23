import 'discipline_snapshot.dart';
import 'pending_journal_trade.dart';
import 'watchlist_item.dart';
import 'weekly_summary.dart';

/// Central state for the Small Account Cockpit
/// Aggregates all data needed to render the unified dashboard
class CockpitState {
  final DisciplineSnapshot discipline;
  final AccountSnapshot account;
  final List<PendingJournalTrade> pendingJournals;
  final List<WatchlistItem> watchlist;
  final List<OpenPosition> positions;
  final WeeklySummary weekSummary;
  final MarketRegime regime;
  final bool isLoading;

  const CockpitState({
    required this.discipline,
    required this.account,
    required this.pendingJournals,
    required this.watchlist,
    required this.positions,
    required this.weekSummary,
    required this.regime,
    this.isLoading = false,
  });

  factory CockpitState.initial() {
    return CockpitState(
      discipline: DisciplineSnapshot.empty(),
      account: AccountSnapshot.empty(),
      pendingJournals: const [],
      watchlist: const [],
      positions: const [],
      weekSummary: WeeklySummary.empty(),
      regime: MarketRegime.unknown,
      isLoading: true,
    );
  }

  /// Whether the user is blocked from trading due to pending journals
  bool get isBlocked => pendingJournals.isNotEmpty;

  /// Message to display when blocked
  String? get blockingMessage {
    if (!isBlocked) return null;
    final count = pendingJournals.length;
    return count == 1
        ? 'Journal your last trade before opening new positions'
        : 'Journal your last $count trades before opening new positions';
  }

  /// Whether to show a discipline warning
  bool get shouldShowDisciplineWarning => discipline.currentScore < 70 && discipline.currentScore > 0;

  CockpitState copyWith({
    DisciplineSnapshot? discipline,
    AccountSnapshot? account,
    List<PendingJournalTrade>? pendingJournals,
    List<WatchlistItem>? watchlist,
    List<OpenPosition>? positions,
    WeeklySummary? weekSummary,
    MarketRegime? regime,
    bool? isLoading,
  }) {
    return CockpitState(
      discipline: discipline ?? this.discipline,
      account: account ?? this.account,
      pendingJournals: pendingJournals ?? this.pendingJournals,
      watchlist: watchlist ?? this.watchlist,
      positions: positions ?? this.positions,
      weekSummary: weekSummary ?? this.weekSummary,
      regime: regime ?? this.regime,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Account snapshot for cockpit display
class AccountSnapshot {
  final double balance;
  final double riskDeployed;
  final double availableRisk;
  final int openPositions;
  final double buyingPowerPercent; // 0-1

  const AccountSnapshot({
    required this.balance,
    required this.riskDeployed,
    required this.availableRisk,
    required this.openPositions,
    required this.buyingPowerPercent,
  });

  factory AccountSnapshot.empty() {
    return const AccountSnapshot(
      balance: 0,
      riskDeployed: 0,
      availableRisk: 0,
      openPositions: 0,
      buyingPowerPercent: 1.0,
    );
  }

  factory AccountSnapshot.fromBalance({
    required double balance,
    required double riskDeployed,
    required int openPositions,
  }) {
    final availableRisk = balance - riskDeployed;
    final buyingPowerPercent = balance > 0 ? (availableRisk / balance) : 1.0;

    return AccountSnapshot(
      balance: balance,
      riskDeployed: riskDeployed,
      availableRisk: availableRisk,
      openPositions: openPositions,
      buyingPowerPercent: buyingPowerPercent,
    );
  }

  String get balanceDisplay => '\$${balance.toStringAsFixed(2)}';
  String get riskDeployedDisplay => '\$${riskDeployed.toStringAsFixed(2)}';
  String get availableRiskDisplay => '\$${availableRisk.toStringAsFixed(2)}';
  String get buyingPowerDisplay => '${(buyingPowerPercent * 100).toStringAsFixed(1)}%';
}

/// Represents an open position in the cockpit
class OpenPosition {
  final String id;
  final String ticker;
  final String strategy; // "CSP", "CC", "Debit Spread", etc.
  final double strike;
  final int dte; // Days to expiration
  final double thetaPerDay;
  final double unrealizedPnL;
  final bool isPaper;

  const OpenPosition({
    required this.id,
    required this.ticker,
    required this.strategy,
    required this.strike,
    required this.dte,
    required this.thetaPerDay,
    required this.unrealizedPnL,
    this.isPaper = true,
  });

  String get displayName => '$strategy $ticker \$${strike.toStringAsFixed(0)}';

  String get pnlDisplay {
    final sign = unrealizedPnL >= 0 ? '+' : '';
    return '$sign\$${unrealizedPnL.toStringAsFixed(2)}';
  }

  String get thetaDisplay => '\$${thetaPerDay.toStringAsFixed(2)}/day';

  bool get isProfit => unrealizedPnL > 0;
  bool get isLoss => unrealizedPnL < 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticker': ticker,
        'strategy': strategy,
        'strike': strike,
        'dte': dte,
        'thetaPerDay': thetaPerDay,
        'unrealizedPnL': unrealizedPnL,
        'isPaper': isPaper,
      };

  factory OpenPosition.fromJson(Map<String, dynamic> json) {
    return OpenPosition(
      id: json['id'] as String,
      ticker: json['ticker'] as String,
      strategy: json['strategy'] as String,
      strike: (json['strike'] as num).toDouble(),
      dte: json['dte'] as int,
      thetaPerDay: (json['thetaPerDay'] as num).toDouble(),
      unrealizedPnL: (json['unrealizedPnL'] as num).toDouble(),
      isPaper: json['isPaper'] as bool? ?? true,
    );
  }
}

/// Market regime classification (placeholder until Phase 6)
enum MarketRegime {
  uptrend,
  downtrend,
  sideways,
  volatile,
  unknown;

  String get displayName {
    switch (this) {
      case MarketRegime.uptrend:
        return '📈 Uptrend';
      case MarketRegime.downtrend:
        return '📉 Downtrend';
      case MarketRegime.sideways:
        return '➡️ Sideways';
      case MarketRegime.volatile:
        return '⚡ Volatile';
      case MarketRegime.unknown:
        return '❓ Unknown';
    }
  }

  String get hint {
    switch (this) {
      case MarketRegime.uptrend:
        return 'Favor bullish strategies (CSPs, debit call spreads)';
      case MarketRegime.downtrend:
        return 'Favor bearish strategies or stay cash';
      case MarketRegime.sideways:
        return 'Favor theta strategies (sell premium)';
      case MarketRegime.volatile:
        return 'Reduce position sizes, widen strikes';
      case MarketRegime.unknown:
        return 'Analyze market conditions before trading';
    }
  }
}
