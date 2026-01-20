class BacktestConfig {
  final double startingCapital;
  final int maxCycles;
  final List<double> pricePath;
  final String strategyId;
  final String? label;

  // Historical parameters
  final String symbol;
  final DateTime startDate;
  final DateTime endDate;

  BacktestConfig({
    required this.startingCapital,
    required this.maxCycles,
    required this.pricePath,
    required this.strategyId,
    this.label,
    required this.symbol,
    required this.startDate,
    required this.endDate,
  });

  BacktestConfig copyWith({
    double? startingCapital,
    int? maxCycles,
    List<double>? pricePath,
    String? strategyId,
    String? label,
    String? symbol,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return BacktestConfig(
      startingCapital: startingCapital ?? this.startingCapital,
      maxCycles: maxCycles ?? this.maxCycles,
      pricePath: pricePath ?? this.pricePath,
      strategyId: strategyId ?? this.strategyId,
      label: label ?? this.label,
      symbol: symbol ?? this.symbol,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startingCapital': startingCapital,
      'maxCycles': maxCycles,
      'pricePath': pricePath,
      'strategyId': strategyId,
      'label': label,
      'symbol': symbol,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  static DateTime _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.parse(v);
    throw ArgumentError('Invalid date: $v');
  }

  factory BacktestConfig.fromMap(Map<String, dynamic> m) {
    return BacktestConfig(
      startingCapital: (m['startingCapital'] as num).toDouble(),
      maxCycles: (m['maxCycles'] as num).toInt(),
      pricePath: List<double>.from((m['pricePath'] as List).map((e) => (e as num).toDouble())),
      strategyId: m['strategyId'] as String,
      label: m['label'] as String?,
      symbol: m['symbol'] as String,
      startDate: _parseDate(m['startDate']),
      endDate: _parseDate(m['endDate']),
    );
  }
}
