enum SignalType { strongBuy, buy, neutral, sell, strongSell }

enum RegimeType { riskOn, riskOff, transitional }

class SignalModel {
  final String ticker;
  final SignalType signal;
  final int confidence;
  final String timeframe;
  final String entryZone;
  final String target;
  final String stop;
  final String thesis;
  final String macroContext;
  final String? optionsEdge;
  final List<String> keyRisks;
  final List<String> dataSourcesUsed;
  final RegimeType regime;
  final String? catalyst;
  final int macroScore;
  final int technicalScore;
  final int sentimentScore;
  final int compositeScore;
  final List<String> searchQueries;

  const SignalModel({
    required this.ticker,
    required this.signal,
    required this.confidence,
    required this.timeframe,
    required this.entryZone,
    required this.target,
    required this.stop,
    required this.thesis,
    required this.macroContext,
    this.optionsEdge,
    required this.keyRisks,
    required this.dataSourcesUsed,
    required this.regime,
    this.catalyst,
    required this.macroScore,
    required this.technicalScore,
    required this.sentimentScore,
    required this.compositeScore,
    this.searchQueries = const [],
  });

  factory SignalModel.fromJson(
    Map<String, dynamic> json, {
    List<String> searchQueries = const [],
  }) {
    return SignalModel(
      ticker: (json['ticker'] as String? ?? '').toUpperCase(),
      signal: _parseSignal(json['signal'] as String?),
      confidence: (json['confidence'] as num? ?? 0).toInt().clamp(0, 100),
      timeframe: json['timeframe'] as String? ?? '',
      entryZone: json['entry_zone'] as String? ?? '',
      target: json['target'] as String? ?? '',
      stop: json['stop'] as String? ?? '',
      thesis: json['thesis'] as String? ?? '',
      macroContext: json['macro_context'] as String? ?? '',
      optionsEdge: json['options_edge'] as String?,
      keyRisks: _toStringList(json['key_risks']),
      dataSourcesUsed: _toStringList(json['data_sources_used']),
      regime: _parseRegime(json['regime'] as String?),
      catalyst: json['catalyst'] as String?,
      macroScore: (json['macro_score'] as num? ?? 0).toInt().clamp(-100, 100),
      technicalScore: (json['technical_score'] as num? ?? 0).toInt().clamp(
        -100,
        100,
      ),
      sentimentScore: (json['sentiment_score'] as num? ?? 0).toInt().clamp(
        -100,
        100,
      ),
      compositeScore: (json['composite_score'] as num? ?? 0).toInt().clamp(
        -100,
        100,
      ),
      searchQueries: searchQueries,
    );
  }

  static SignalType _parseSignal(String? s) => switch (s) {
    'STRONG_BUY' => SignalType.strongBuy,
    'BUY' => SignalType.buy,
    'SELL' => SignalType.sell,
    'STRONG_SELL' => SignalType.strongSell,
    _ => SignalType.neutral,
  };

  static RegimeType _parseRegime(String? s) => switch (s) {
    'RISK_ON' => RegimeType.riskOn,
    'RISK_OFF' => RegimeType.riskOff,
    _ => RegimeType.transitional,
  };

  static List<String> _toStringList(dynamic v) {
    if (v is List) return v.whereType<String>().toList();
    return [];
  }
}
