class RiskProfile {
  final String id;
  final double maxRiskPercent;

  RiskProfile({required this.id, required this.maxRiskPercent});

  /// Backwards-compatible getter used by older controller code.
  double get maxRiskPerTradePercent => maxRiskPercent;

  factory RiskProfile.fromJson(Map<String, dynamic> json) {
    return RiskProfile(
      id: json['id'] as String? ?? 'default',
      maxRiskPercent: (json['maxRiskPercent'] as num?)?.toDouble() ?? 2.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maxRiskPercent': maxRiskPercent,
    };
  }

  /// Default risk profile for new users.
  static RiskProfile get defaultProfile =>
      RiskProfile(id: 'default', maxRiskPercent: 2.0);
}
