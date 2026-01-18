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

  /// Backwards-compatible alias requested by Phase‑2 APIs.
  int get daysUntilExpiration => dte;

  /// Lightweight lifecycle stage derived from DTE as a typed enum.
  PositionStage get stage {
    final days = dte;
    if (days <= 15) return PositionStage.late;
    if (days <= 45) return PositionStage.mid;
    return PositionStage.early;
  }

  /// Simple lifecycleStage string for UI use: "Early", "Mid", "Late".
  String get lifecycleStage {
    final days = daysUntilExpiration;
    if (days > 30) return 'Early';
    if (days > 10) return 'Mid';
    return 'Late';
  }

  /// Heuristic probability (0.0 - 1.0) that an option position will be assigned
  /// before expiration. This is intentionally simple and conservative for Phase‑2.
  double get assignmentProbability {
    // For shares (no option), assignment probability is 0.
    if (type == PositionType.shares) return 0.0;

    final d = daysUntilExpiration;
    if (d > 20) return 0.10;
    if (d > 10) return 0.25;
    return 0.50;
  }

  /// Optional simple time-decay impact cue: "Low", "Moderate", "High".
  String get timeDecayImpact {
    final d = daysUntilExpiration;
    if (d > 20) return 'Low';
    if (d > 10) return 'Moderate';
    return 'High';
  }
}