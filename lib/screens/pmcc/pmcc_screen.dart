import 'package:flutter/material.dart';

import '../../services/engines/pmcc_engine.dart';

class PmccScreen extends StatefulWidget {
  const PmccScreen({super.key});

  @override
  State<PmccScreen> createState() => _PmccScreenState();
}

class _PmccScreenState extends State<PmccScreen> {
  static const _engine = PmccEngine();

  final _spot = TextEditingController();
  final _leapsStrike = TextEditingController();
  final _leapsCost = TextEditingController();
  final _leapsDte = TextEditingController();
  final _leapsDelta = TextEditingController();
  final _shortStrike = TextEditingController();
  final _shortCredit = TextEditingController();
  final _shortDte = TextEditingController();
  final _premiums = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _spot,
      _leapsStrike,
      _leapsCost,
      _leapsDte,
      _leapsDelta,
      _shortStrike,
      _shortCredit,
      _shortDte,
      _premiums,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final deltaText = _leapsDelta.text.trim();
    final result = _engine.analyze(
      PmccInput(
        spot: _num(_spot),
        leapsStrike: _num(_leapsStrike),
        leapsCost: _num(_leapsCost),
        leapsDte: _int(_leapsDte),
        leapsDelta: deltaText.isEmpty ? null : _num(_leapsDelta),
        shortStrike: _num(_shortStrike),
        shortCredit: _num(_shortCredit),
        shortDte: _int(_shortDte),
        premiumsCollected: _num(_premiums),
      ),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Poor Man's Covered Call")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(_spot, 'Stock price now'),
          Text('LEAPS (long call)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _plain(_leapsStrike, 'Strike')),
              const SizedBox(width: 8),
              Expanded(child: _plain(_leapsCost, 'Cost / share')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _plain(_leapsDte, 'DTE', decimal: false)),
              const SizedBox(width: 8),
              Expanded(child: _plain(_leapsDelta, 'Delta (optional)')),
            ],
          ),
          const SizedBox(height: 16),
          Text('Short call', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _plain(_shortStrike, 'Strike')),
              const SizedBox(width: 8),
              Expanded(child: _plain(_shortCredit, 'Credit / share')),
              const SizedBox(width: 8),
              Expanded(child: _plain(_shortDte, 'DTE', decimal: false)),
            ],
          ),
          const SizedBox(height: 12),
          _field(_premiums, 'Premium collected so far / share (optional)'),
          if (result == null)
            const Text(
              'Enter valid details. The short call must be above the LEAPS '
              'strike and expire before the LEAPS.',
            )
          else
            _ResultView(result: result),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _plain(c, label),
  );

  Widget _plain(TextEditingController c, String label, {bool decimal = true}) =>
      TextField(
        controller: c,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      );
}

class _ResultView extends StatelessWidget {
  final PmccResult result;
  const _ResultView({required this.result});

  String _money(double v) =>
      '${v < 0 ? '-' : ''}\$${v.abs().toStringAsFixed(2)}';
  String _pct(double v) => '${v.toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    final r = result;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.warnings.isNotEmpty)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final w in r.warnings)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(w),
                    ),
                ],
              ),
            ),
          ),
        _section(theme, 'Your cost', [
          _row('Synthetic stock cost', _money(r.syntheticStockCost)),
          _row('Net cost after premiums', _money(r.netDebit)),
          _row('Effective cost basis', _money(r.effectiveBasis)),
        ]),
        _section(theme, 'LEAPS value', [
          _row('Intrinsic value', _money(r.intrinsicValue)),
          _row('Time value', _money(r.extrinsicValue)),
          _row('Time value share of cost', _pct(r.extrinsicPercentOfCost)),
        ]),
        _section(theme, 'If assigned at the short strike', [
          _row('Strike gap', _money(r.width)),
          _row('Best-case profit / share', _money(r.maxProfitPerShare)),
          _row('Best-case profit / contract', _money(r.maxProfitPerContract)),
          _row('Max loss / contract', _money(r.maxLossPerContract)),
        ]),
        _section(theme, 'Versus owning 100 shares', [
          _row('Shares cost', _money(r.sharesCapitalPerContract)),
          _row('LEAPS cost', _money(r.leapsCapitalPerContract)),
          _row('Capital saved', _pct(r.capitalSavingsPercent)),
          _row('This cycle: LEAPS', _pct(r.cycleReturnPercent)),
          _row('This cycle: shares', _pct(r.sharesCycleReturnPercent)),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Profit figures are conservative: the LEAPS is valued at '
            'intrinsic value only when the short call expires.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _section(ThemeData theme, String title, List<Widget> rows) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label)),
        const SizedBox(width: 8),
        Text(value),
      ],
    ),
  );
}
