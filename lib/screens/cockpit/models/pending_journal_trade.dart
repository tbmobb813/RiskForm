/// Represents a closed trade that needs to be journaled
/// Used to implement behavioral friction (can't trade without journaling)
class PendingJournalTrade {
  final String positionId;
  final String ticker;
  final String strategy; // e.g., "CSP AAPL $170"
  final double pnl;
  final DateTime closedAt;
  final bool isPaper;

  const PendingJournalTrade({
    required this.positionId,
    required this.ticker,
    required this.strategy,
    required this.pnl,
    required this.closedAt,
    this.isPaper = true,
  });

  String get displayName => '$strategy → ${pnl >= 0 ? '+' : ''}\$${pnl.toStringAsFixed(2)}';

  String get timeAgo {
    final diff = DateTime.now().difference(closedAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Map<String, dynamic> toJson() => {
        'positionId': positionId,
        'ticker': ticker,
        'strategy': strategy,
        'pnl': pnl,
        'closedAt': closedAt.toIso8601String(),
        'isPaper': isPaper,
      };

  factory PendingJournalTrade.fromJson(Map<String, dynamic> json) {
    return PendingJournalTrade(
      positionId: json['positionId'] as String,
      ticker: json['ticker'] as String,
      strategy: json['strategy'] as String,
      pnl: (json['pnl'] as num).toDouble(),
      closedAt: DateTime.parse(json['closedAt'] as String),
      isPaper: json['isPaper'] as bool? ?? true,
    );
  }
}
