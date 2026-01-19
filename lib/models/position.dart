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

  /// Converts Position to JSON for Firestore storage.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'symbol': symbol,
      'strategy': strategy,
      'quantity': quantity,
      'isOpen': isOpen,
      'expiration': expiration.toIso8601String(),
      'riskFlags': riskFlags,
    };
  }

  /// Creates a Position from JSON data.
  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      type: PositionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PositionType.shares,
      ),
      symbol: json['symbol'] as String? ?? '',
      strategy: json['strategy'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      isOpen: json['isOpen'] as bool? ?? true,
      expiration: json['expiration'] != null
          ? DateTime.parse(json['expiration'] as String)
          : DateTime.now(),
      riskFlags: (json['riskFlags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Creates a copy with optional field overrides.
  Position copyWith({
    PositionType? type,
    String? symbol,
    String? strategy,
    int? quantity,
    bool? isOpen,
    DateTime? expiration,
    List<String>? riskFlags,
  }) {
    return Position(
      type: type ?? this.type,
      symbol: symbol ?? this.symbol,
      strategy: strategy ?? this.strategy,
      quantity: quantity ?? this.quantity,
      isOpen: isOpen ?? this.isOpen,
      expiration: expiration ?? this.expiration,
      riskFlags: riskFlags ?? this.riskFlags,
    );
  }
}