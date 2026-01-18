enum PositionType { csp, coveredCall, shares }

enum PositionStage { early, mid, late }

class Position {
  final PositionType type;
  final String symbol;
  final String strategy;
  final int quantity;
  final bool isOpen;
  final DateTime expiration;
  final List<String> riskFlags;

  Position({
    required this.type,
    required this.symbol,
    required this.strategy,
    required this.quantity,
    required this.expiration,
    required this.isOpen,
    this.riskFlags = const [],
  });

  String get expirationDateString =>
      "${expiration.month}/${expiration.day}/${expiration.year}";

  /// Days to expiration (DTE), clamped to a sane range.
  int get dte => expiration.difference(DateTime.now()).inDays.clamp(0, 999);

  /// Lightweight lifecycle stage derived from DTE.
  /// - early: long time to expiry
  /// - mid: intermediate
  /// - late: close to expiration
  PositionStage get stage {
    final days = dte;
    if (days <= 15) return PositionStage.late;
    if (days <= 45) return PositionStage.mid;
    return PositionStage.early;
  }

  /// Heuristic probability (0.0 - 1.0) that an option position will be assigned
  /// before expiration. Uses a simple rule-of-thumb based on DTE and position type.
  /// This is intentionally conservative and easy to tweak.
  double get assignmentProbability {
    // For shares (no option), assignment probability is 0.
    if (type == PositionType.shares) return 0.0;

    // Base probability depends on stage.
    final days = dte.clamp(0, 365);

    double prob;
    if (days <= 7) {
      prob = 0.7; // very near-term
    } else if (days <= 30) {
      // linearly scale from 0.7 at 7d to 0.25 at 30d
      prob = 0.25 + (30 - days) * ((0.7 - 0.25) / (30 - 7));
    } else if (days <= 90) {
      // lower baseline for mid-term
      prob = 0.1 + (90 - days) * ((0.25 - 0.1) / (90 - 30));
    } else {
      prob = 0.05; // long-dated
    }

    // Slightly adjust for strategy: CSP (put) has marginally higher assignment risk.
    if (type == PositionType.csp) prob *= 1.1;

    // Clamp to [0,1]
    if (prob < 0) prob = 0.0;
    if (prob > 1) prob = 1.0;
    return double.parse(prob.toStringAsFixed(2));
  }
}