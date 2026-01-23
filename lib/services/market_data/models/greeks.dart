/// Option Greeks and implied volatility
class Greeks {
  final double delta;
  final double gamma;
  final double theta;
  final double vega;
  final double rho;
  final double iv; // Implied volatility (as decimal, e.g., 0.25 = 25%)

  const Greeks({
    required this.delta,
    required this.gamma,
    required this.theta,
    required this.vega,
    required this.rho,
    required this.iv,
  });

  factory Greeks.fromTradierJson(Map<String, dynamic> json) {
    return Greeks(
      delta: (json['delta'] as num?)?.toDouble() ?? 0.0,
      gamma: (json['gamma'] as num?)?.toDouble() ?? 0.0,
      theta: (json['theta'] as num?)?.toDouble() ?? 0.0,
      vega: (json['vega'] as num?)?.toDouble() ?? 0.0,
      rho: (json['rho'] as num?)?.toDouble() ?? 0.0,
      iv: (json['smv_vol'] as num?)?.toDouble() ?? 0.0, // Tradier uses 'smv_vol' for IV
    );
  }

  factory Greeks.fromPolygonJson(Map<String, dynamic> json) {
    return Greeks(
      delta: (json['delta'] as num?)?.toDouble() ?? 0.0,
      gamma: (json['gamma'] as num?)?.toDouble() ?? 0.0,
      theta: (json['theta'] as num?)?.toDouble() ?? 0.0,
      vega: (json['vega'] as num?)?.toDouble() ?? 0.0,
      rho: (json['rho'] as num?)?.toDouble() ?? 0.0,
      iv: (json['implied_volatility'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// IV as percentage (e.g., 25.0 for 25%)
  double get ivPercent => iv * 100;

  @override
  String toString() {
    return 'Greeks(δ:${delta.toStringAsFixed(2)}, γ:${gamma.toStringAsFixed(4)}, '
        'θ:${theta.toStringAsFixed(2)}, ν:${vega.toStringAsFixed(2)}, '
        'ρ:${rho.toStringAsFixed(2)}, IV:${ivPercent.toStringAsFixed(1)}%)';
  }
}
