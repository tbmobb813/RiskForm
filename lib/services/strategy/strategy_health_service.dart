import '../../models/trade_inputs.dart';
import '../../models/payoff_result.dart';

class StrategyHealth {
  final double deltaScore; // 0..1
  final double thetaScore; // 0..1
  final double ivScore; // 0..1
  final double liquidityScore; // 0..1

  StrategyHealth({required this.deltaScore, required this.thetaScore, required this.ivScore, required this.liquidityScore});

  double get overall => (deltaScore + thetaScore + ivScore + liquidityScore) / 4.0;
}

class StrategyHealthService {
  /// Compute a simple heuristic health score for a strategy given planner inputs and payoff.
  StrategyHealth compute({TradeInputs? inputs, PayoffResult? payoff}) {
    // Delta score: prefer delta near 0.2 for short-biased risk-managed strategies
    final delta = inputs?.delta ?? 0.2;
    final deltaScore = (1.0 - (delta - 0.2).abs() / 0.5).clamp(0.0, 1.0);

    // Theta score: prefer moderate time to expiry (e.g., 7-45 days)
    final dte = inputs?.expiration != null ? inputs!.expiration!.difference(DateTime.now()).inDays.toDouble() : 30.0;
    final thetaScore = (1.0 - ((dte - 21.0).abs() / 60.0)).clamp(0.0, 1.0);

    // IV score: if impliedVol present, prefer moderate IV (0.15 - 0.6)
    final iv = inputs?.impliedVolatility ?? 0.3;
    final ivScore = (1.0 - ((iv - 0.3).abs() / 0.5)).clamp(0.0, 1.0);

    // Liquidity score: approximate with sharesOwned or size; more shares -> better
    final size = (inputs?.sharesOwned ?? 1).toDouble();
    final liquidityScore = (size / (size + 100)).clamp(0.0, 1.0);

    return StrategyHealth(deltaScore: deltaScore, thetaScore: thetaScore, ivScore: ivScore, liquidityScore: liquidityScore);
  }
}
