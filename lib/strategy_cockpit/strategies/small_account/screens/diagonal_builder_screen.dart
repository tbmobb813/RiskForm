import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/services/cheap_options_scanner.dart';
import 'package:riskform/state/strategy_controller.dart';
import 'package:riskform/strategy_cockpit/strategies/diagonal_strategy.dart';
import '../../models/spread_selection.dart';

class DiagonalBuilderScreen extends ConsumerStatefulWidget {
  final OptionsChainService chainService;
  final String ticker;

  const DiagonalBuilderScreen({required this.chainService, required this.ticker, super.key});

  @override
  ConsumerState<DiagonalBuilderScreen> createState() => _DiagonalBuilderScreenState();
}

class _DiagonalBuilderScreenState extends ConsumerState<DiagonalBuilderScreen> {
  bool _loading = false;
  OptionChain? _chain;

  Future<void> _loadChain() async {
    setState(() => _loading = true);
    final svc = widget.chainService;
    final chain = await svc.fetchChain(widget.ticker);
    setState(() {
      _chain = chain;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadChain();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Diagonal Builder: ${widget.ticker}')),
      body: _loading
          ? const LinearProgressIndicator()
          : _chain == null
              ? Center(child: Text('No chain for ${widget.ticker}'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.ticker.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    const Text('Select near-dated short and longer-dated long leg at possibly different strikes.'),
                    const SizedBox(height: 12),
                    // For brevity reuse spread selection widgets if available; fall back to simple controls
                    ElevatedButton(
                      onPressed: () async {
                        // For now build a placeholder diagonal with sample strikes from first expirations
                        final expNear = _chain!.expirations.first;
                        final expFar = _chain!.expirations.length > 1 ? _chain!.expirations[1] : expNear;
                        final shortCall = expNear.calls.first.contract;
                        final longCall = expFar.calls.first.contract;
                        final strategy = DiagonalStrategy(longLeg: longCall, shortLeg: shortCall);
                        ref.read(strategyControllerProvider.notifier).setStrategy(strategy);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Build sample diagonal'),
                    ),
                  ]),
                ),
    );
  }
}
