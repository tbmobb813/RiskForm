import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/engines/capital_allocation_engine.dart';
import '../../services/engines/position_allocation_mapper.dart';
import '../../state/account_context_provider.dart';
import '../position_sizing/position_sizing_args.dart';
import '../../widgets/tools/tool_widgets.dart';
import '../dashboard/active_positions_section.dart';

class _HoldingFields {
  _HoldingFields();

  factory _HoldingFields.from(AllocationHolding h) {
    final f = _HoldingFields();
    f.symbol.text = h.symbol;
    f.strategy = h.strategy;
    f.capital.text = h.capital.toStringAsFixed(0);
    f.premium.text = h.premium.toStringAsFixed(2);
    f.originalDays.text = '${h.originalDays}';
    f.dte.text = '${h.dte}';
    return f;
  }

  final symbol = TextEditingController();
  final capital = TextEditingController();
  final premium = TextEditingController();
  final originalDays = TextEditingController(text: '30');
  final dte = TextEditingController();
  HoldingStrategy strategy = HoldingStrategy.csp;

  void dispose() {
    symbol.dispose();
    capital.dispose();
    premium.dispose();
    originalDays.dispose();
    dte.dispose();
  }
}

class CapitalAllocationScreen extends ConsumerStatefulWidget {
  const CapitalAllocationScreen({super.key});

  @override
  ConsumerState<CapitalAllocationScreen> createState() =>
      _CapitalAllocationScreenState();
}

class _CapitalAllocationScreenState
    extends ConsumerState<CapitalAllocationScreen> {
  static const _engine = CapitalAllocationEngine();

  final _account = TextEditingController();
  final _freeCash = TextEditingController();
  final _benchmark = TextEditingController(text: '4');
  final _maxSymbol = TextEditingController(text: '30');
  final _holdings = <_HoldingFields>[_HoldingFields()];
  bool _prefilled = false;

  @override
  void dispose() {
    for (final c in [_account, _freeCash, _benchmark, _maxSymbol]) {
      c.dispose();
    }
    for (final h in _holdings) {
      h.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  AllocationResult? _analyze() => _engine.analyze(
    AllocationInput(
      accountSize: _num(_account),
      freeCash: _num(_freeCash),
      benchmarkAnnualPercent: _num(_benchmark),
      maxSymbolPercent: _num(_maxSymbol),
      holdings: [
        for (final h in _holdings)
          AllocationHolding(
            symbol: h.symbol.text,
            strategy: h.strategy,
            capital: _num(h.capital),
            premium: _num(h.premium),
            originalDays: _int(h.originalDays),
            dte: _int(h.dte),
          ),
      ],
    ),
  );

  void _importPositions() {
    final imported = holdingsFromPositions(ref.read(activePositionsProvider));
    final messenger = ScaffoldMessenger.of(context);

    if (imported.holdings.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            imported.skipped > 0
                ? '${imported.skipped} open position(s) are missing a strike, '
                      'contracts or premium.'
                : 'No open positions to import.',
          ),
        ),
      );
      return;
    }

    setState(() {
      for (final h in _holdings) {
        h.dispose();
      }
      _holdings
        ..clear()
        ..addAll(imported.holdings.map(_HoldingFields.from));
    });
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Imported ${imported.holdings.length} position(s)'
          '${imported.skipped > 0 ? ', skipped ${imported.skipped} without enough data' : ''}.',
        ),
      ),
    );
  }

  void _prefill(double size, double buyingPower) {
    if (_prefilled || size <= 0) return;
    _prefilled = true;
    _account.text = size.toStringAsFixed(0);
    _freeCash.text = buyingPower.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(accountContextProvider, (_, next) {
      final a = next.asData?.value;
      if (a != null && !_prefilled && a.accountSize > 0) {
        setState(() => _prefill(a.accountSize, a.buyingPower));
      }
    });
    final existing = ref.read(accountContextProvider).asData?.value;
    if (existing != null) _prefill(existing.accountSize, existing.buyingPower);

    // Keep the positions stream subscribed so an import has data ready.
    ref.watch(activePositionsProvider);

    final result = _analyze();

    return Scaffold(
      appBar: AppBar(title: const Text('Capital Allocation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Account', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _field(_account, 'Account size (\$)'),
          _field(_freeCash, 'Free cash available (\$)'),
          Row(
            children: [
              Expanded(child: _plain(_benchmark, 'Idle cash yield %')),
              const SizedBox(width: 8),
              Expanded(child: _plain(_maxSymbol, 'Max % per symbol')),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Open positions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (var n = 0; n < _holdings.length; n++) _holdingCard(n),
          Wrap(
            children: [
              TextButton.icon(
                onPressed: () =>
                    setState(() => _holdings.add(_HoldingFields())),
                icon: const Icon(Icons.add),
                label: const Text('Add position'),
              ),
              TextButton.icon(
                onPressed: _importPositions,
                icon: const Icon(Icons.download),
                label: const Text('Import open positions'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (result == null)
            const Text('Enter a valid account size and cash amount.')
          else
            _ResultView(result: result),
        ],
      ),
    );
  }

  Widget _holdingCard(int n) {
    final h = _holdings[n];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _plain(h.symbol, 'Symbol', text: true)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<HoldingStrategy>(
                    initialValue: h.strategy,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Strategy',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final s in HoldingStrategy.values)
                        DropdownMenuItem(value: s, child: Text(s.label)),
                    ],
                    onChanged: (s) => setState(() => h.strategy = s!),
                  ),
                ),
                if (_holdings.length > 1)
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close),
                    onPressed: () =>
                        setState(() => _holdings.removeAt(n).dispose()),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _plain(h.capital, 'Capital (\$)')),
                const SizedBox(width: 8),
                Expanded(child: _plain(h.premium, 'Premium (\$)')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _plain(
                    h.originalDays,
                    'Days in trade',
                    decimal: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _plain(h.dte, 'DTE left', decimal: false)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _plain(c, label),
  );

  Widget _plain(
    TextEditingController c,
    String label, {
    bool decimal = true,
    bool text = false,
  }) => ToolField(
    controller: c,
    label: label,
    kind: text
        ? ToolFieldKind.text
        : (decimal ? ToolFieldKind.decimal : ToolFieldKind.integer),
    onChanged: (_) => setState(() {}),
  );
}

class _ResultView extends StatelessWidget {
  final AllocationResult result;
  const _ResultView({required this.result});

  String _money(double v) => '\$${v.toStringAsFixed(0)}';
  String _pct(double v) => '${v.toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = result;
    final palette = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      theme.colorScheme.primaryContainer,
      theme.colorScheme.secondaryContainer,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_pct(r.deployedPercent)} deployed',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                _bar(theme, palette),
                const SizedBox(height: 12),
                ResultRow('Capital deployed', _money(r.totalDeployed)),
                ResultRow(
                  'Free cash',
                  '${_money(r.freeCash)} (${_pct(r.freeCashPercent)})',
                ),
                ResultRow('Budget for next trade', _money(r.newPositionBudget)),
                if (r.newPositionBudget > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => GoRouter.of(context).pushNamed(
                        'position_sizing',
                        extra: PositionSizingArgs(
                          buyingPower: r.newPositionBudget,
                        ),
                      ),
                      icon: const Icon(Icons.straighten),
                      label: const Text('Size a trade with this budget'),
                    ),
                  ),
                ResultRow(
                  'Weighted annualized return',
                  r.weightedAnnualizedReturnPercent == null
                      ? 'n/a'
                      : _pct(r.weightedAnnualizedReturnPercent!),
                ),
                ResultRow('Premium collected', _money(r.totalPremium)),
                ResultRow(
                  'Idle-cash alternative',
                  _money(r.totalOpportunityCost),
                ),
                for (final w in r.warnings)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      w,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (r.symbols.isNotEmpty)
          ResultSection('By symbol', [
            for (final s in r.symbols)
              ResultRow(
                s.symbol,
                '${_money(s.capital)} · ${_pct(s.percentOfAccount)}'
                '${s.overLimit ? '  over limit' : ''}',
              ),
          ]),
        if (r.holdings.isNotEmpty)
          ResultSection('By position', [
            for (final m in r.holdings)
              ResultRow(
                '${m.holding.symbol.trim().isEmpty ? '(unnamed)' : m.holding.symbol.trim().toUpperCase()} '
                    '${m.holding.strategy.label}',
                '${m.annualizedReturnPercent == null ? 'n/a' : _pct(m.annualizedReturnPercent!)}'
                    '${m.underearning ? '  below cash' : ''}',
              ),
          ]),
        if (r.holdings.isNotEmpty)
          ResultSection('Capital freed', [
            for (final e in r.capitalFreedWithin.entries)
              ResultRow('Within ${e.key} days', _money(e.value)),
          ]),
      ],
    );
  }

  Widget _bar(ThemeData theme, List<Color> palette) {
    final segments = <Widget>[];
    for (var n = 0; n < result.symbols.length; n++) {
      final s = result.symbols[n];
      segments.add(
        Expanded(
          flex: s.capital.round().clamp(1, 1 << 30),
          child: Tooltip(
            message: '${s.symbol} ${_pct(s.percentOfAccount)}',
            child: Container(color: palette[n % palette.length]),
          ),
        ),
      );
    }
    final idle = result.freeCash.round();
    if (idle > 0) {
      segments.add(
        Expanded(
          flex: idle,
          child: Container(color: theme.colorScheme.surfaceContainerHighest),
        ),
      );
    }
    if (segments.isEmpty) return const SizedBox(height: 16);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(height: 16, child: Row(children: segments)),
    );
  }
}
