import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riskform/strategy_cockpit/strategies/trading_strategy.dart';
import 'package:riskform/state/strategy_controller.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/screens/strategy_dashboard_screen.dart';
import '../services/cheap_options_scanner.dart';
import '../state/scanner_state.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final OptionsChainService chainService;
  final String ticker;

  const ScannerScreen({required this.chainService, required this.ticker, super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _loading = false;

  Future<void> _runScan() async {
    setState(() => _loading = true);

    final filters = ref.read(scannerFiltersProvider);
    final scanner = CheapOptionsScanner(widget.chainService);

    final res = await scanner.scan(ticker: widget.ticker, filters: filters);

    ref.read(scannerResultsProvider.notifier).setResults(res);

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cheap Options Scanner: ${widget.ticker}')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ScannerFiltersCard(),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loading ? null : _runScan, child: const Text('Scan')),
            const SizedBox(height: 12),
            if (_loading) const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(child: ScannerResultsList()),
          ],
        ),
      ),
    );
  }
}


class ScannerFiltersCard extends ConsumerWidget {
  const ScannerFiltersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(scannerFiltersProvider);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Text('Max Premium: \$${filters.maxPremium.toStringAsFixed(0)}'),
          Slider(
            value: filters.maxPremium,
            min: 10,
            max: 200,
            divisions: 19,
            onChanged: (v) => ref.read(scannerFiltersProvider.notifier).setMaxPremium(v),
          ),

          Text('DTE Range: ${filters.minDte}–${filters.maxDte}'),
          RangeSlider(
            values: RangeValues(filters.minDte.toDouble(), filters.maxDte.toDouble()),
            min: 7,
            max: 90,
            divisions: 83,
            onChanged: (r) => ref.read(scannerFiltersProvider.notifier).setDteRange(r.start.toInt(), r.end.toInt()),
          ),

          Text('Delta Range: ${(filters.minDelta ?? 0.05).toStringAsFixed(2)}–${(filters.maxDelta ?? 0.80).toStringAsFixed(2)}'),
          RangeSlider(
            values: RangeValues(filters.minDelta ?? 0.05, filters.maxDelta ?? 0.80),
            min: 0.05,
            max: 0.80,
            divisions: 75,
            onChanged: (r) => ref.read(scannerFiltersProvider.notifier).setDeltaRange(r.start, r.end),
          ),

          Text('Min Open Interest: ${filters.minOpenInterest}'),
          Slider(
            value: filters.minOpenInterest.toDouble(),
            min: 0,
            max: 500,
            divisions: 50,
            onChanged: (v) => ref.read(scannerFiltersProvider.notifier).setMinOpenInterest(v.toInt()),
          ),

          Text('Max Bid-Ask Spread: \$${filters.maxBidAskSpread.toStringAsFixed(2)}'),
          Slider(
            value: filters.maxBidAskSpread,
            min: 0.01,
            max: 0.50,
            divisions: 49,
            onChanged: (v) => ref.read(scannerFiltersProvider.notifier).setMaxBidAskSpread(v),
          ),
        ]),
      ),
    );
  }
}


class ScannerResultsList extends ConsumerWidget {
  const ScannerResultsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(scannerResultsProvider);

    if (results.isEmpty) return const Center(child: Text('No results yet'));

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        final strategy = results[i];
        return StrategyResultCard(
          strategy: strategy,
          onTap: () {
            ref.read(strategyControllerProvider.notifier).setStrategy(strategy);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StrategyDashboardScreen()));
          },
        );
      },
    );
  }
}


class StrategyResultCard extends StatelessWidget {
  final TradingStrategy strategy;
  final VoidCallback onTap;

  const StrategyResultCard({super.key, required this.strategy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        title: Text(strategy.label),
        subtitle: Text('Breakeven: ${strategy.breakeven.toStringAsFixed(2)}'),
        trailing: Text('\$${strategy.maxRisk.toStringAsFixed(0)} risk'),
        onTap: onTap,
      ),
    );
  }
}
