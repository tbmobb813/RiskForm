import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riskform/state/strategy_controller.dart';
import 'package:riskform/state/option_pricing_provider.dart';
import 'package:riskform/strategy_cockpit/strategies/payoff_point.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/services/small_account_sizer.dart';
import 'package:riskform/state/journal_providers.dart';
import 'package:riskform/services/engines/backtest_engine.dart';
import 'package:riskform_core/models/backtest/backtest_config.dart';
import 'package:riskform/services/engines/option_pricing_engine.dart';
// removed unused imports: payoff_engine, risk_engine, trade_inputs
import 'package:riskform/models/journal/journal_entry.dart';

class StrategyDashboardScreen extends ConsumerWidget {
  final double currentPrice;
  final double accountBalance;

  const StrategyDashboardScreen({super.key, this.currentPrice = 100.0, this.accountBalance = 500.0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(strategyControllerProvider);
    final controller = ref.read(strategyControllerProvider.notifier);
    final strategy = state.strategy;

    if (strategy == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Strategy Dashboard')),
        body: const Center(child: Text('No strategy selected')),
      );
    }

    final maxRisk = controller.maxRisk ?? 0.0;
    final maxProfit = controller.maxProfit ?? double.nan;
    final breakeven = controller.breakeven ?? double.nan;

    final curve = controller.payoffCurve(underlyingPrice: currentPrice, rangePercent: 0.3, steps: 60) ?? <PayoffPoint>[];

    double? profitAt(double price) {
      if (curve.isEmpty) return null;
      // find nearest point
      PayoffPoint nearest = curve.reduce((a, b) => ( (a.underlyingPrice - price).abs() < (b.underlyingPrice - price).abs()) ? a : b);
      return nearest.profitLoss;
    }

    final scenarios = <double>[-0.2, -0.1, 0.1, 0.2];

    return Scaffold(
      appBar: AppBar(title: Text('${strategy.label} Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StrategyHeaderCard(strategyLabel: strategy.label),
            const SizedBox(height: 12),

            RiskRewardCard(maxRisk: maxRisk, maxProfit: maxProfit, breakeven: breakeven),
            const SizedBox(height: 12),

            SizedBox(height: 220, child: PayoffChart(curve: curve, currentPrice: currentPrice)),
            const SizedBox(height: 12),

            GreeksCard(currentPrice: currentPrice),
            const SizedBox(height: 12),

            ScenarioAnalysisCard(currentPrice: currentPrice, scenarios: scenarios, profitAt: profitAt),
            const SizedBox(height: 12),

            PositionSizingCard(accountBalance: accountBalance, costPerContract: maxRisk),
            const SizedBox(height: 12),

            LearningModeCard(explanation: strategy.explain()),
          ],
        ),
      ),
    );
  }
}

class StrategyHeaderCard extends ConsumerWidget {
  final String strategyLabel;
  const StrategyHeaderCard({super.key, required this.strategyLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strategy = ref.watch(strategyControllerProvider).strategy;
    final journal = ref.read(journalRepositoryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(strategyLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 4), const Text('Small Account Mode')]),
            ElevatedButton(
              onPressed: () async {
                if (strategy == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active strategy')));
                  return;
                }

                final now = DateTime.now();
                final payload = {
                  'strategyId': strategy.id,
                  'strategyLabel': strategy.label,
                  'timestamp': now.toIso8601String(),
                  'type': strategy.typeId.startsWith('long') ? 'BUY' : 'SELL',
                  'qty': 1,
                };

                // Create journal entry locally (and persist if signed in)
                final entry = JournalEntry(
                  id: now.millisecondsSinceEpoch.toString(),
                  timestamp: now,
                  type: 'execution',
                  data: {'strategy': strategy.toJson(), 'execution': payload, 'smallAccount': true},
                );

                await journal.addEntry(entry);

                // Run a small local backtest (cheap simulated run) and attach summary
                try {
                  final bengine = BacktestEngine(optionPricing: OptionPricingEngine());
                  final currentPrice = 100.0; // best-effort default when none available in UI
                  final config = BacktestConfig(
                    startingCapital: 500.0,
                    maxCycles: 1,
                    pricePath: [currentPrice * 0.95, currentPrice, currentPrice * 1.05],
                    strategyId: strategy.typeId,
                    label: strategy.label,
                    symbol: strategy.label,
                    startDate: DateTime.now().subtract(const Duration(days: 30)),
                    endDate: DateTime.now(),
                  );
                  final result = bengine.run(config);
                  // Attach summary to journal entry (best-effort) using available fields
                  final enriched = JournalEntry(
                    id: entry.id,
                    timestamp: entry.timestamp,
                    type: entry.type,
                    data: Map<String, dynamic>.from(entry.data)
                      ..['backtestSummary'] = {
                        'totalReturn': result.totalReturn,
                        'cyclesCompleted': result.cyclesCompleted,
                        'cycles': result.cycles.length,
                      },
                  );
                  await journal.updateEntry(enriched);
                } catch (_) {
                  // ignore backtest errors; journal entry is already created.
                }

                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trade journaled (small-account)')));
              },
              child: const Text('Take Trade'),
            )
          ],
        ),
      ),
    );
  }
}

class RiskRewardCard extends StatelessWidget {
  final double maxRisk;
  final double maxProfit;
  final double breakeven;

  const RiskRewardCard({super.key, required this.maxRisk, required this.maxProfit, required this.breakeven});

  String _fmt(double v) => v.isNaN ? '—' : '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _metric('Max Risk', _fmt(maxRisk), Colors.redAccent),
            _metric('Max Profit', maxProfit.isFinite ? _fmt(maxProfit) : 'Unlimited', Colors.green),
            _metric('Breakeven', breakeven.isNaN ? '—' : _fmt(breakeven), Colors.blueGrey),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Column(children: [Text(label, style: const TextStyle(fontSize: 12)), const SizedBox(height: 6), Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))]);
  }
}

class PayoffChart extends StatelessWidget {
  final List<PayoffPoint> curve;
  final double currentPrice;

  const PayoffChart({super.key, required this.curve, required this.currentPrice});

  @override
  Widget build(BuildContext context) {
    if (curve.isEmpty) return const Center(child: Text('No payoff data'));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CustomPaint(
          size: const Size(double.infinity, 200),
          painter: _PayoffPainter(curve: curve, currentPrice: currentPrice),
        ),
      ),
    );
  }
}

class _PayoffPainter extends CustomPainter {
  final List<PayoffPoint> curve;
  final double currentPrice;
  _PayoffPainter({required this.curve, required this.currentPrice});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue..strokeWidth = 2..style = PaintingStyle.stroke;

    final prices = curve.map((c) => c.underlyingPrice).toList();
    final profits = curve.map((c) => c.profitLoss).toList();

    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    final minY = profits.reduce((a, b) => a < b ? a : b);
    final maxY = profits.reduce((a, b) => a > b ? a : b);

    double xFor(double p) => ((p - minP) / (maxP - minP)) * size.width;
    double yFor(double v) => size.height - ((v - minY) / (maxY - minY)) * size.height;

    final path = Path();
    for (var i = 0; i < curve.length; i++) {
      final x = xFor(prices[i]);
      final y = yFor(profits[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // draw current price line
    final cp = currentPrice.clamp(minP, maxP);
    final cpX = xFor(cp);
    final dash = Paint()..color = Colors.grey..strokeWidth = 1;
    canvas.drawLine(Offset(cpX, 0), Offset(cpX, size.height), dash);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GreeksCard extends ConsumerWidget {
  final double currentPrice;
  const GreeksCard({super.key, required this.currentPrice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(strategyControllerProvider);
    final strategy = state.strategy;
    final optionPricing = ref.read(optionPricingEngineProvider);

    if (strategy == null) {
      return Card(child: Padding(padding: const EdgeInsets.all(12.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_greek('Delta', '—'), _greek('Theta', '—'), _greek('Vega', '—')])));
    }

    // Use a conservative default IV if none available
    const defaultIv = 0.35;

    double netDelta = 0.0;
    double netTheta = 0.0;
    double netVega = 0.0;

    for (final leg in strategy.legs) {
      final c = leg.contract;
      if (c.type == 'share') {
        // Shares: delta = 1 * quantity, theta/vega = 0
        netDelta += leg.quantity.toDouble();
        continue;
      }

      final days = c.expiry.difference(DateTime.now()).inDays;
      final t = (days > 0) ? days / 365.0 : (1.0 / 365.0);
      final vol = defaultIv;

      final isCall = c.type.toLowerCase() == 'call';

      final d = optionPricing.delta(isCall: isCall, spot: currentPrice, strike: c.strike, volatility: vol, timeToExpiryYears: t);
      final v = optionPricing.vega(spot: currentPrice, strike: c.strike, volatility: vol, timeToExpiryYears: t);
      final th = optionPricing.theta(isCall: isCall, spot: currentPrice, strike: c.strike, volatility: vol, timeToExpiryYears: t);

      netDelta += d * leg.quantity;
      netVega += v * leg.quantity;
      netTheta += th * leg.quantity;
    }

    String fmtD(double v) => v.abs() < 0.01 ? v.toStringAsFixed(4) : v.toStringAsFixed(2);
    String fmtSmall(double v) => v.isNaN ? '—' : v.toStringAsFixed(2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _greek('Delta', fmtD(netDelta)),
          _greek('Theta (per day)', fmtSmall(netTheta)),
          _greek('Vega', fmtSmall(netVega)),
        ]),
      ),
    );
  }

  Widget _greek(String label, String value) => Column(children: [Text(label, style: const TextStyle(fontSize: 12)), const SizedBox(height: 6), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]);
}

class ScenarioAnalysisCard extends StatelessWidget {
  final double currentPrice;
  final List<double> scenarios;
  final double? Function(double price) profitAt;

  const ScenarioAnalysisCard({super.key, required this.currentPrice, required this.scenarios, required this.profitAt});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Scenario Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...scenarios.map((s) {
            final price = currentPrice * (1 + s);
            final profit = profitAt(price) ?? double.nan;
            final label = '${(s * 100).toStringAsFixed(0)}%';
            final profitText = profit.isNaN ? 'n/a' : '\$${profit.toStringAsFixed(2)}';
            return Padding(padding: const EdgeInsets.symmetric(vertical: 6.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text('$profitText at ${price.toStringAsFixed(2)}')]));
          })
        ]),
      ),
    );
  }
}

class PositionSizingCard extends ConsumerWidget {
  final double accountBalance;
  final double costPerContract;

  const PositionSizingCard({super.key, required this.accountBalance, required this.costPerContract});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizer = ref.read(smallAccountSizerProvider);

    final per = costPerContract > 0 ? costPerContract : 0.0;
    final recommended5 = sizer.recommendedContractsByRisk(accountBalance: accountBalance, costPerContract: per, riskPct: 0.05);
    final recommended10 = sizer.recommendedContractsByRisk(accountBalance: accountBalance, costPerContract: per, riskPct: 0.10);
    final allocs = sizer.sizeRecommendations(accountBalance: accountBalance, costPerContract: per)['allocations'] as Map<String, int>? ?? {};

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Position Sizing', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Cost per contract: \$${per.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          Text('Recommended (5% risk): $recommended5 contracts'),
          Text('Recommended (10% risk): $recommended10 contracts'),
          const SizedBox(height: 6),
          if (allocs.isNotEmpty) Text('Allocations: ${allocs.entries.map((e) => '${e.key}: ${e.value}').join(', ')}'),
        ]),
      ),
    );
  }
}

class LearningModeCard extends StatelessWidget {
  final dynamic explanation;
  const LearningModeCard({super.key, required this.explanation});

  @override
  Widget build(BuildContext context) {
    final summary = explanation?.summary ?? 'No explanation available';
    final pros = (explanation?.pros ?? []).cast<String>();
    final cons = (explanation?.cons ?? []).cast<String>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Learning Mode', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(summary),
          const SizedBox(height: 8),
          if (pros.isNotEmpty) Text('Pros: ${pros.join(', ')}'),
          if (cons.isNotEmpty) Text('Cons: ${cons.join(', ')}'),
        ]),
      ),
    );
  }
}
