import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/controllers/spread_builder_controller.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/services/cheap_options_scanner.dart';
import 'package:riskform/state/strategy_controller.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/screens/strategy_dashboard_screen.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/models/spread_selection.dart';

class SpreadBuilderScreen extends ConsumerStatefulWidget {
  final OptionsChainService chainService;
  final String ticker;

  const SpreadBuilderScreen({required this.chainService, required this.ticker, super.key});

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

    return Scaffold(
      appBar: AppBar(title: Text('Debit Spread Builder: ${widget.ticker}')),
      body: _loading
          ? const LinearProgressIndicator()
          : _chain == null
              ? Center(child: Text('No chain for ${widget.ticker}'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TickerHeader(ticker: widget.ticker),
                      const SizedBox(height: 24),

                      ExpirationSelector(chain: _chain!),
                      const SizedBox(height: 24),

                      LongStrikeSelector(chain: _chain!),
                      const SizedBox(height: 24),

                      ShortStrikeSelector(chain: _chain!),
                      const SizedBox(height: 24),

                      SpreadPreview(selection: selection),
                      const SizedBox(height: 32),

                      BuildSpreadButton(selection: selection),
                    ],
                  ),
                ),
    );
  }
}


class TickerHeader extends StatelessWidget {
  final String ticker;
  const TickerHeader({super.key, required this.ticker});

  @override
  Widget build(BuildContext context) {
    return Text(
      ticker.toUpperCase(),
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    );
  }
}


class ExpirationSelector extends ConsumerWidget {
  final OptionChain chain;
  const ExpirationSelector({super.key, required this.chain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(spreadBuilderControllerProvider);
    final controller = ref.read(spreadBuilderControllerProvider.notifier);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Select Expiration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: chain.expirations.map((exp) {
          final isSelected = selection.expiry == exp.expiry;
          return ChoiceChip(
            label: Text('${exp.dte} DTE'),
            selected: isSelected,
            onSelected: (_) => controller.setExpiry(exp.expiry),
          );
        }).toList(),
      ),
    ]);
  }
}


class LongStrikeSelector extends ConsumerWidget {
  final OptionChain chain;
  const LongStrikeSelector({super.key, required this.chain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(spreadBuilderControllerProvider);
    final controller = ref.read(spreadBuilderControllerProvider.notifier);

    if (selection.expiry == null) {
      return const Text('Select an expiration first');
    }

    final expiry = chain.expirations.firstWhere((e) => e.expiry == selection.expiry);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Select Long Call', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),

      ...expiry.calls.map((c) {
        final isSelected = selection.longLeg?.id == c.contract.id;
        return Card(
          child: ListTile(
            title: Text('Strike ${c.contract.strike}'),
            subtitle: Text('Premium \$${c.premium.toStringAsFixed(2)} • Δ ${c.delta.toStringAsFixed(2)}'),
            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
            onTap: () => controller.setLongLeg(c.contract),
          ),
        );
      }),
    ]);
  }
}


class ShortStrikeSelector extends ConsumerWidget {
  final OptionChain chain;
  const ShortStrikeSelector({super.key, required this.chain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(spreadBuilderControllerProvider);
    final controller = ref.read(spreadBuilderControllerProvider.notifier);

    if (selection.longLeg == null) {
      return const Text('Select a long call first');
    }

    final expiry = chain.expirations.firstWhere((e) => e.expiry == selection.expiry);
    final calls = expiry.calls.where((c) => c.contract.strike > selection.longLeg!.strike).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Select Short Call', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),

      ...calls.map((c) {
        final isSelected = selection.shortLeg?.id == c.contract.id;
        return Card(
          child: ListTile(
            title: Text('Strike ${c.contract.strike}'),
            subtitle: Text('Premium \$${c.premium.toStringAsFixed(2)}'),
            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
            onTap: () => controller.setShortLeg(c.contract),
          ),
        );
      }),
    ]);
  }
}


class SpreadPreview extends StatelessWidget {
  final SpreadSelection selection;

  const SpreadPreview({super.key, required this.selection});

  @override
  Widget build(BuildContext context) {
    if (!selection.isComplete) {
      return const Text('Select both legs to preview the spread');
    }

    final longLeg = selection.longLeg!;
    final shortLeg = selection.shortLeg!;
    final netDebit = longLeg.premium - shortLeg.premium;
    final maxProfit = (shortLeg.strike - longLeg.strike) - netDebit;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Spread Preview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Text('Net Debit: \$${netDebit.toStringAsFixed(2)}'),
          Text('Max Profit: \$${maxProfit.toStringAsFixed(2)}'),
          Text('Breakeven: ${(longLeg.strike + netDebit).toStringAsFixed(2)}'),
        ]),
      ),
    );
  }
}


class BuildSpreadButton extends ConsumerWidget {
  final SpreadSelection selection;

  const BuildSpreadButton({super.key, required this.selection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(spreadBuilderControllerProvider.notifier);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: selection.isComplete
            ? () {
                final strategy = controller.buildStrategy();
                if (strategy != null) {
                  ref.read(strategyControllerProvider.notifier).setStrategy(strategy);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StrategyDashboardScreen()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selection incomplete')));
                }
              }
            : null,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14.0),
          child: Text('Build Spread'),
        ),
      ),
    );
  }
}
