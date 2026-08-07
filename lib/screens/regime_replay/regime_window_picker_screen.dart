import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riskform_core/models/backtest/backtest_config.dart';

import '../../models/analytics/regime_segment.dart';
import '../../models/backtest/regime_replay_context.dart';
import '../../services/historical/regime_window_catalog.dart';
import '../../state/account_context_provider.dart';
import '../../state/regime_window_providers.dart';
import '../backtest/backtest_screen.dart';
import 'regime_display.dart';

const _suggestedSymbols = ['SPY', 'QQQ', 'AAPL', 'MSFT'];

String _formatDate(DateTime d) => '${d.month}/${d.day}/${d.year}';

class RegimeWindowPickerScreen extends ConsumerStatefulWidget {
  const RegimeWindowPickerScreen({super.key});

  @override
  ConsumerState<RegimeWindowPickerScreen> createState() =>
      _RegimeWindowPickerScreenState();
}

class _RegimeWindowPickerScreenState
    extends ConsumerState<RegimeWindowPickerScreen> {
  late final TextEditingController _symbolController;
  String _symbol = _suggestedSymbols.first;

  @override
  void initState() {
    super.initState();
    _symbolController = TextEditingController(text: _symbol);
  }

  @override
  void dispose() {
    _symbolController.dispose();
    super.dispose();
  }

  void _setSymbol(String value) {
    final trimmed = value.trim().toUpperCase();
    if (trimmed.isEmpty || trimmed == _symbol) return;
    setState(() {
      _symbol = trimmed;
      _symbolController.text = trimmed;
    });
  }

  Future<void> _selectWindow(RegimeCatalog catalog, RegimeSegment segment) async {
    final closes = catalog.prices
        .sublist(segment.startIndex, segment.endIndex + 1)
        .map((p) => p.close)
        .toList();

    final accountAsync = ref.read(accountContextProvider);
    final startingCapital = accountAsync.value?.accountSize ?? 10000.0;

    final config = BacktestConfig(
      startingCapital: startingCapital > 0 ? startingCapital : 10000.0,
      maxCycles: 10,
      pricePath: closes,
      strategyId: 'wheel',
      symbol: _symbol,
      startDate: segment.startDate,
      endDate: segment.endDate,
    );

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BacktestScreen(
          config: config,
          regimeContext: RegimeReplayContext(
            regime: segment.regime,
            symbol: _symbol,
            startDate: segment.startDate,
            endDate: segment.endDate,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(regimeCatalogProvider(_symbol));

    return Scaffold(
      appBar: AppBar(title: const Text('Regime Replay')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pick a historical regime window and replay a hypothetical '
              'Wheel campaign through it.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _symbolController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Symbol',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _setSymbol,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _suggestedSymbols
                  .map(
                    (s) => ChoiceChip(
                      label: Text(s),
                      selected: s == _symbol,
                      onSelected: (_) => _setSymbol(s),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: catalogAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Failed to load history: $err')),
                data: (catalog) {
                  if (catalog.windows.isEmpty) {
                    return const Center(
                      child: Text('No regime windows found for this symbol.'),
                    );
                  }
                  return ListView.separated(
                    itemCount: catalog.windows.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final segment = catalog.windows[index];
                      final days =
                          segment.endDate.difference(segment.startDate).inDays;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: regimeColor(segment.regime),
                            child: Text(
                              regimeLabel(segment.regime)[0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            '${regimeLabel(segment.regime)} · $_symbol',
                          ),
                          subtitle: Text(
                            '${_formatDate(segment.startDate)} – '
                            '${_formatDate(segment.endDate)} ($days days)',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _selectWindow(catalog, segment),
                        ),
                      );
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
