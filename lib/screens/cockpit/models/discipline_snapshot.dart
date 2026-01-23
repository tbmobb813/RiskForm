/// Discipline snapshot for the Small Account Cockpit
/// Represents current discipline state, streaks, and status
class DisciplineSnapshot {
  final int currentScore; // 0-100
  final int cleanStreak; // Consecutive trades with score >= 80
  final int adherenceStreak; // Consecutive trades with adherence >= 30
  final String statusMessage; // Contextual message for the user
  final DisciplineLevel level; // Overall discipline level

  const DisciplineSnapshot({
    required this.currentScore,
    required this.cleanStreak,
    required this.adherenceStreak,
    required this.statusMessage,
    required this.level,
  });

  factory DisciplineSnapshot.empty() {
    return const DisciplineSnapshot(
      currentScore: 0,
      cleanStreak: 0,
      adherenceStreak: 0,
      statusMessage: 'Start your first trade to build your discipline score!',
      level: DisciplineLevel.none,
    );
  }

  factory DisciplineSnapshot.fromScore({
    required int score,
    required int cleanStreak,
    required int adherenceStreak,
    int pendingJournals = 0,
  }) {
    final level = DisciplineLevel.fromScore(score);
    final statusMessage = _generateStatusMessage(
      score: score,
      cleanStreak: cleanStreak,
      level: level,
      pendingJournals: pendingJournals,
    );

    return DisciplineSnapshot(
      currentScore: score,
      cleanStreak: cleanStreak,
      adherenceStreak: adherenceStreak,
      statusMessage: statusMessage,
      level: level,
    );
  }

  static String _generateStatusMessage({
    required int score,
    required int cleanStreak,
    required DisciplineLevel level,
    required int pendingJournals,
  }) {
    if (pendingJournals > 0) {
      return pendingJournals == 1
          ? 'Journal your last trade to continue trading.'
          : 'Journal your last $pendingJournals trades to continue.';
    }

    if (cleanStreak == 0) {
      return 'Get back on track! Focus on following your plan.';
    }

    if (cleanStreak >= 20) {
      return "🌟 Incredible! You're in the top 1% of disciplined traders.";
    }

    if (cleanStreak >= 10) {
      return "🔥 You're on fire! $cleanStreak-day streak — keep it going!";
    }

    if (cleanStreak >= 5) {
      return "⭐ Great work! $cleanStreak clean trades in a row.";
    }

    // cleanStreak 1-4
    switch (level) {
      case DisciplineLevel.excellent:
        return "Excellent! Keep up this consistency.";
      case DisciplineLevel.good:
        return "You're on track. ${5 - cleanStreak} more for a 5-day streak!";
      case DisciplineLevel.fair:
        return "Good progress. Focus on plan adherence to improve.";
      case DisciplineLevel.poor:
        return "Review your last trades and adjust your approach.";
      case DisciplineLevel.none:
        return "Start your first trade to build your score!";
    }
  }
}

enum DisciplineLevel {
  excellent, // 90-100
  good, // 80-89
  fair, // 70-79
  poor, // < 70
  none; // No trades yet

  static DisciplineLevel fromScore(int score) {
    if (score >= 90) return DisciplineLevel.excellent;
    if (score >= 80) return DisciplineLevel.good;
    if (score >= 70) return DisciplineLevel.fair;
    if (score > 0) return DisciplineLevel.poor;
    return DisciplineLevel.none;
  }

  String get label {
    switch (this) {
      case DisciplineLevel.excellent:
        return 'Excellent';
      case DisciplineLevel.good:
        return 'Good';
      case DisciplineLevel.fair:
        return 'Fair';
      case DisciplineLevel.poor:
        return 'Poor';
      case DisciplineLevel.none:
        return 'No trades yet';
    }
  }
}
