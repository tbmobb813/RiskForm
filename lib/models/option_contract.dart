class OptionContract {
  final String id;
  final double strike;
  final double premium;
  final DateTime expiry;
  final String type; // 'call' | 'put'

  OptionContract({
    required this.id,
    required this.strike,
    required this.premium,
    required this.expiry,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'strike': strike,
        'premium': premium,
        'expiry': expiry.toIso8601String(),
        'type': type,
      };

  static OptionContract fromJson(Map<String, dynamic> j) {
    return OptionContract(
      id: j['id'] as String,
      strike: (j['strike'] as num).toDouble(),
      premium: (j['premium'] as num).toDouble(),
      expiry: DateTime.parse(j['expiry'] as String),
      type: j['type'] as String,
    );
  }
}
