/// Weekly trading summary for the cockpit
class WeeklySummary {
  final double pnl;
  final double pnlPercent;
  final int trades;
  final double winRate; // 0-1
  final double avgDiscipline; // 0-100
  final List<DayTrade> dailyTrades; // 7 days, Monday-Sunday

  const WeeklySummary({
    required this.pnl,
    required this.pnlPercent,
    required this.trades,
    required this.winRate,
    required this.avgDiscipline,
    required this.dailyTrades,
  });

  factory WeeklySummary.empty() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    return WeeklySummary(
      pnl: 0,
      pnlPercent: 0,
      trades: 0,
      winRate: 0,
      avgDiscipline: 0,
      dailyTrades: List.generate(
        7,
        (i) => DayTrade(
          date: weekStart.add(Duration(days: i)),
          hadTrade: false,
          wasClean: false,
        ),
      ),
    );
  }

  String get pnlDisplay {
    final sign = pnl >= 0 ? '+' : '';
    return '$sign\$${pnl.toStringAsFixed(2)}';
  }

  String get pnlPercentDisplay {
    final sign = pnlPercent >= 0 ? '+' : '';
    return '$sign${pnlPercent.toStringAsFixed(1)}%';
  }

  String get winRateDisplay => '${(winRate * 100).toStringAsFixed(0)}%';

  bool get isPositive => pnl >= 0;
  bool get isNegative => pnl < 0;
}

/// Represents a single day's trading activity
class DayTrade {
  final DateTime date;
  final bool hadTrade;
  final bool wasClean; // Discipline score >= 80

  const DayTrade({
    required this.date,
    required this.hadTrade,
    required this.wasClean,
  });

  String get dayName {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  /// Visual indicator: ✓ (clean), ✗ (violation), - (no trade)
  String get indicator {
    if (!hadTrade) return '-';
    return wasClean ? '✓' : '✗';
  }
}
