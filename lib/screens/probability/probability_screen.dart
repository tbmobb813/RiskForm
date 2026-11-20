import 'package:flutter/material.dart';

import '../../services/engines/probability_engine.dart';
import '../../widgets/tools/tool_widgets.dart';

class ProbabilityScreen extends StatefulWidget {
  const ProbabilityScreen({super.key});

  @override
  State<ProbabilityScreen> createState() => _ProbabilityScreenState();
}

class _ProbabilityScreenState extends State<ProbabilityScreen> {
  static const _engine = ProbabilityEngine();

  final _spot = TextEditingController();
  final _shortStrike = TextEditingController();
  final _longStrike = TextEditingController();
  final _credit = TextEditingController();
  final _dte = TextEditingController();
  final _iv = TextEditingController();
  final _rate = TextEditingController(text: '4');

  ProbabilitySide _side = ProbabilitySide.shortPut;

  @override
  void dispose() {
    for (final c in [
      _spot,
      _shortStrike,
      _longStrike,
      _credit,
      _dte,
      _iv,
      _rate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  String _label(ProbabilitySide s) => switch (s) {
    ProbabilitySide.shortPut => 'Cash-Secured Put',
    ProbabilitySide.shortCall => 'Covered Call',
    ProbabilitySide.putCreditSpread => 'Put Credit Spread',
    ProbabilitySide.callCreditSpread => 'Call Credit Spread',
  };

  @override
  Widget build(BuildContext context) {
    final result = _engine.analyze(
      ProbabilityInput(
        side: _side,
        spot: _num(_spot),
        shortStrike: _num(_shortStrike),
        longStrike: _side.isSpread ? _num(_longStrike) : null,
        credit: _num(_credit),
        dte: int.tryParse(_dte.text.trim()) ?? 0,
        impliedVolPercent: _num(_iv),
        riskFreeRatePercent: double.tryParse(_rate.text.trim()) ?? 0,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Probability')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<ProbabilitySide>(
            initialValue: _side,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Strategy',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final s in ProbabilitySide.values)
                DropdownMenuItem(value: s, child: Text(_label(s))),
            ],
            onChanged: (s) => setState(() => _side = s!),
          ),
          const SizedBox(height: 12),
          _field(_spot, 'Stock price now'),
          _field(_shortStrike, _side.isSpread ? 'Short strike' : 'Strike'),
          if (_side.isSpread) _field(_longStrike, 'Long (protective) strike'),
          _field(
            _credit,
            _side.isSpread ? 'Net credit per share' : 'Premium per share',
          ),
          _field(_dte, 'Days to expiration', decimal: false),
          _field(_iv, 'Implied volatility %'),
          _field(_rate, 'Risk-free rate %'),
          const SizedBox(height: 8),
          if (result == null)
            const Text('Enter valid trade details to see probabilities.')
          else
            _ResultCard(result: result),
          const SizedBox(height: 8),
          Text(
            'Estimates use implied volatility and a lognormal price model. '
            'They help compare trades and are not forecasts.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool decimal = true}) =>
      ToolField(
        controller: c,
        label: label,
        kind: decimal ? ToolFieldKind.decimal : ToolFieldKind.integer,
        padded: true,
        onChanged: (_) => setState(() {}),
      );
}

class _ResultCard extends StatelessWidget {
  final ProbabilityResult result;
  const _ResultCard({required this.result});

  String _pct(double p) => '${(p * 100).toStringAsFixed(1)}%';
  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final r = result;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_pct(r.probabilityOfProfit)} chance of profit',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ResultRow('Chance of assignment', _pct(r.probabilityInTheMoney)),
            ResultRow(
              'Chance of keeping full credit',
              _pct(r.probabilityMaxProfit),
            ),
            const Divider(height: 24),
            ResultRow('Breakeven', _money(r.breakeven)),
            ResultRow(
              'Breakeven from stock price',
              '${r.breakevenDistancePercent.toStringAsFixed(1)}%',
            ),
            ResultRow(
              'Strike from stock price',
              '${r.strikeDistancePercent.toStringAsFixed(1)}%',
            ),
            ResultRow(
              'Strike distance',
              '${r.strikeSigmaDistance.toStringAsFixed(2)} std devs',
            ),
            ResultRow(
              'Expected move (1 std dev)',
              '±${_money(r.expectedMove)}  (${_money(r.lowerBound)} to ${_money(r.upperBound)})',
            ),
            const Divider(height: 24),
            ResultRow('Max profit', _money(r.maxProfitPerContract)),
            ResultRow(
              'Max loss',
              r.maxLossPerContract == null
                  ? 'Unlimited without shares'
                  : _money(r.maxLossPerContract!),
            ),
            if (r.returnOnRiskPercent != null)
              ResultRow(
                'Return on risk',
                '${r.returnOnRiskPercent!.toStringAsFixed(1)}%',
              ),
          ],
        ),
      ),
    );
  }
}
