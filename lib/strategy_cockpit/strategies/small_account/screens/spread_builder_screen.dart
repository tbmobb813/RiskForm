import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/spread_selection.dart';
import '../controllers/spread_builder_controller.dart';
import '../services/spread_builder_service.dart';
import '../services/cheap_options_scanner.dart';

class SpreadBuilderScreen extends ConsumerStatefulWidget {
  final OptionsChainService chainService;
  final String ticker;

  const SpreadBuilderScreen({required this.chainService, required this.ticker, Key? key}) : super(key: key);

  @override
  ConsumerState<SpreadBuilderScreen> createState() => _SpreadBuilderScreenState();
}

class _SpreadBuilderScreenState extends ConsumerState<SpreadBuilderScreen> {
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
    final selection = ref.watch(spreadBuilderControllerProvider);
    final notifier = ref.read(spreadBuilderControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('Build Debit Spread: ${widget.ticker}')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_chain == null && !_loading) Text('No chain loaded'),
            if (_chain != null) Expanded(
              child: ListView(
                children: [
                  const Text('Select Expiry', style: TextStyle(fontWeight: FontWeight.bold)),
                  ..._chain!.expirations.map((e) => ListTile(
                    title: Text('${e.expiry.toIso8601String().split('T').first} (DTE ${e.dte})'),
                    selected: selection.expiry == e.expiry,
                    onTap: () => notifier.setExpiry(e.expiry),
                  )),
                  const Divider(),
                  const Text('Select Long Strike', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (selection.expiry == null) const Text('Pick expiry first'),
                  if (selection.expiry != null) ..._chain!.expirations.firstWhere((ex) => ex.expiry == selection.expiry).calls.map((c) => ListTile(
                    title: Text('Strike ${c.contract.strike} Premium ${c.premium.toStringAsFixed(2)}'),
                    selected: selection.longLeg == c.contract,
                    onTap: () => notifier.setLongLeg(c.contract),
                  )),
                  const Divider(),
                  const Text('Select Short Strike', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (selection.longLeg == null) const Text('Pick long leg first'),
                  if (selection.longLeg != null && selection.expiry != null) ..._chain!.expirations.firstWhere((ex) => ex.expiry == selection.expiry).calls.where((c) => c.contract.strike > selection.longLeg!.strike).map((c) => ListTile(
                    title: Text('Strike ${c.contract.strike} Premium ${c.premium.toStringAsFixed(2)}'),
                    selected: selection.shortLeg == c.contract,
                    onTap: () => notifier.setShortLeg(c.contract),
                  )),
                  const Divider(),
                  ElevatedButton(
                    onPressed: () {
                      try {
                        final spread = ref.read(spreadBuilderControllerProvider.notifier).buildStrategy();
                        if (spread != null) {
                          // In a full app: set into StrategyController and navigate to dashboard
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Built spread: ${spread.label}')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selection incomplete')));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: const Text('Build Spread'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
