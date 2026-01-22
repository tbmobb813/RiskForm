import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/cheap_options_scanner.dart';
import '../models/scanner_filters.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  final OptionsChainService chainService;
  final String ticker;

  const ScannerScreen({required this.chainService, required this.ticker, Key? key}) : super(key: key);

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _loading = false;
  List<TradingStrategy> _results = [];

  Future<void> _runScan() async {
    setState(() => _loading = true);

    final scanner = CheapOptionsScanner(widget.chainService);
    final filters = ScannerFilters(
      maxPremium: 150,
      minDte: 30,
      maxDte: 60,
      maxBidAskSpread: 0.15,
      minOpenInterest: 20,
      minDelta: 0.2,
      maxDelta: 0.4,
    );

    final res = await scanner.scan(ticker: widget.ticker, filters: filters);

    setState(() {
      _results = res;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cheap Options Scanner: ${widget.ticker}')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ElevatedButton(onPressed: _loading ? null : _runScan, child: Text('Scan')),
            const SizedBox(height: 12),
            if (_loading) const CircularProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final s = _results[i];
                  return ListTile(
                    title: Text(s.label),
                    subtitle: Text('Breakeven: ${s.breakeven.toStringAsFixed(2)} | Risk: ${s.maxRisk.toStringAsFixed(2)}'),
                    onTap: () {
                      // Caller should handle selection via StrategyController in real app
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
