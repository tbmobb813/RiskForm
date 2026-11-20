enum PositionType { csp, coveredCall, shares }

enum PositionStage { early, mid, late }

class Position {
  /// Firestore document id. Not part of the stored fields.
  final String? id;
  final PositionType type;
  final String symbol;
  final String strategy;
  final int quantity;
  final bool isOpen;
  final DateTime expiration;
  final List<String> riskFlags;

  /// Option strike. Null for positions saved before strikes were recorded.
  final double? strike;

  /// Premium received per share when the position was opened.
  final double? premium;

  /// Number of option contracts (100 shares each).
  final int? contracts;

  final DateTime? openedAt;

  Position({
    this.id,
    required this.type,
    required this.symbol,
    required this.strategy,
    required this.quantity,
    required this.expiration,
    required this.isOpen,
    this.riskFlags = const [],
    this.strike,
    this.premium,
    this.contracts,
    this.openedAt,
  });

  /// Capital tied up by this position, or null when the strike or contract
  /// count is unknown. For covered calls the strike stands in for the value of
  /// the shares, so treat it as an approximation. Plain shares return null.
  double? get capitalLocked {
    final s = strike;
    final c = contracts;
    if (s == null || c == null || c <= 0) return null;
    return switch (type) {
      PositionType.csp || PositionType.coveredCall => s * 100 * c,
      PositionType.shares => null,
    };
  }

  /// Total premium collected across all contracts, or null when unknown.
  double? get totalPremium {
    final p = premium;
    final c = contracts;
    if (p == null || c == null || c <= 0) return null;
    return p * 100 * c;
  }

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
      if (strike != null) 'strike': strike,
      if (premium != null) 'premium': premium,
      if (contracts != null) 'contracts': contracts,
      if (openedAt != null) 'openedAt': openedAt!.toIso8601String(),
    };
  }

  /// Creates a Position from JSON data.
  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as String?,
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
      strike: (json['strike'] as num?)?.toDouble(),
      premium: (json['premium'] as num?)?.toDouble(),
      contracts: (json['contracts'] as num?)?.toInt(),
      openedAt: json['openedAt'] is String
          ? DateTime.tryParse(json['openedAt'] as String)
          : null,
    );
  }

  /// Creates a copy with optional field overrides.
  Position copyWith({
    String? id,
    PositionType? type,
    String? symbol,
    String? strategy,
    int? quantity,
    bool? isOpen,
    DateTime? expiration,
    List<String>? riskFlags,
    double? strike,
    double? premium,
    int? contracts,
    DateTime? openedAt,
  }) {
    return Position(
      id: id ?? this.id,
      type: type ?? this.type,
      symbol: symbol ?? this.symbol,
      strategy: strategy ?? this.strategy,
      quantity: quantity ?? this.quantity,
      isOpen: isOpen ?? this.isOpen,
      expiration: expiration ?? this.expiration,
      riskFlags: riskFlags ?? this.riskFlags,
      strike: strike ?? this.strike,
      premium: premium ?? this.premium,
      contracts: contracts ?? this.contracts,
      openedAt: openedAt ?? this.openedAt,
    );
  }
}
