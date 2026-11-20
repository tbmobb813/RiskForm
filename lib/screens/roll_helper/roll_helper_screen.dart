import 'package:flutter/material.dart';

import '../../services/engines/roll_decision_engine.dart';

class _CandidateFields {
  final strike = TextEditingController();
  final dte = TextEditingController();
  final credit = TextEditingController();

  void dispose() {
    strike.dispose();
    dte.dispose();
    credit.dispose();
  }
}

class RollHelperScreen extends StatefulWidget {
  const RollHelperScreen({super.key});

  @override
  State<RollHelperScreen> createState() => _RollHelperScreenState();
}

class _RollHelperScreenState extends State<RollHelperScreen> {
  static const _engine = RollDecisionEngine();
  static const _maxCandidates = 4;

  final _strike = TextEditingController();
  final _dte = TextEditingController();
  final _underlying = TextEditingController();
  final _buyback = TextEditingController();
  final _original = TextEditingController();
  final _buyingPower = TextEditingController();
  final _candidates = <_CandidateFields>[_CandidateFields()];

  RollSide _side = RollSide.shortPut;

  @override
  void dispose() {
    for (final c in [
      _strike,
      _dte,
      _underlying,
      _buyback,
      _original,
      _buyingPower,
    ]) {
      c.dispose();
    }
    for (final c in _candidates) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;
  int _int(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  RollResult? _analyze() {
    final bp = _buyingPower.text.trim();
    return _engine.analyze(
      RollInput(
        side: _side,
        strike: _num(_strike),
        dte: _int(_dte),
        underlyingPrice: _num(_underlying),
        buybackPrice: _num(_buyback),
        originalPremium: _num(_original),
        availableBuyingPower: bp.isEmpty ? double.infinity : _num(_buyingPower),
        candidates: [
          for (final c in _candidates)
            RollCandidate(
              newStrike: _num(c.strike),
              newDte: _int(c.dte),
              newCredit: _num(c.credit),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPut = _side == RollSide.shortPut;
    final result = _analyze();

    return Scaffold(
      appBar: AppBar(title: const Text('Roll Helper')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<RollSide>(
            segments: const [
              ButtonSegment(value: RollSide.shortPut, label: Text('Short Put')),
              ButtonSegment(
                value: RollSide.shortCall,
                label: Text('Short Call'),
              ),
            ],
            selected: {_side},
            onSelectionChanged: (s) => setState(() => _side = s.first),
          ),
          const SizedBox(height: 16),
          Text(
            'Current position',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          _field(_strike, 'Current strike'),
          _field(_dte, 'Days to expiration', decimal: false),
          _field(_underlying, 'Stock price now'),
          _field(_buyback, 'Cost to buy back (per share)'),
          _field(_original, 'Premium originally received (per share)'),
          if (isPut) _field(_buyingPower, 'Extra buying power (optional)'),
          const SizedBox(height: 8),
          Text(
            'Roll candidates',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (var n = 0; n < _candidates.length; n++) _candidateRow(n),
          Row(
            children: [
              TextButton.icon(
                onPressed: _candidates.length >= _maxCandidates
                    ? null
                    : () => setState(() => _candidates.add(_CandidateFields())),
                icon: const Icon(Icons.add),
                label: const Text('Add candidate'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (result == null)
            const Text('Enter valid position and candidate details.')
          else
            _ResultView(result: result, isPut: isPut),
        ],
      ),
    );
  }

  Widget _candidateRow(int n) {
    final c = _candidates[n];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: _plainField(c.strike, 'New strike')),
          const SizedBox(width: 8),
          Expanded(child: _plainField(c.dte, 'New DTE', decimal: false)),
          const SizedBox(width: 8),
          Expanded(child: _plainField(c.credit, 'New credit')),
          if (_candidates.length > 1)
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.close),
              onPressed: () =>
                  setState(() => _candidates.removeAt(n).dispose()),
            ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool decimal = true}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _plainField(c, label, decimal: decimal),
      );

  Widget _plainField(
    TextEditingController c,
    String label, {
    bool decimal = true,
  }) => TextField(
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
  final RollResult result;
  final bool isPut;
  const _ResultView({required this.result, required this.isPut});

  String _signed(double v) =>
      '${v < 0 ? '-' : '+'}\$${v.abs().toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headline = switch (result.verdict) {
      RollVerdict.roll => 'Roll',
      RollVerdict.hold => 'Hold',
      RollVerdict.takeAssignment =>
        isPut ? 'Take assignment' : 'Let it be called',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(result.reason),
                const Divider(height: 24),
                _row(
                  'In the money',
                  result.inTheMoney
                      ? '${result.inTheMoneyPercent.toStringAsFixed(1)}%'
                      : 'No',
                ),
                _row(
                  'Premium captured',
                  '${result.premiumCapturedPercent.toStringAsFixed(0)}%',
                ),
                _row(
                  isPut ? 'Cost basis if assigned' : 'Sale price if called',
                  '\$${result.assignmentPrice.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        ),
        for (var n = 0; n < result.candidates.length; n++)
          _candidateCard(context, n),
      ],
    );
  }

  Widget _candidateCard(BuildContext context, int n) {
    final theme = Theme.of(context);
    final r = result.candidates[n];
    final best = result.bestIndex == n;

    return Card(
      shape: best
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.primary, width: 2),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${r.candidate.newStrike.toStringAsFixed(2)} · '
              '${r.candidate.newDte} DTE${best ? '  (best)' : ''}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _row('Net credit / share', _signed(r.netCredit)),
            _row('Net credit / contract', _signed(r.netCreditPerContract)),
            _row(
              isPut ? 'New effective cost basis' : 'New effective sale price',
              '\$${r.effectivePrice.toStringAsFixed(2)}',
            ),
            _row('Vs. assignment now', _signed(r.improvementVsAssignment)),
            _row('Extra days', '${r.extraDays}'),
            if (isPut)
              _row('Collateral change', _signed(r.capitalDeltaPerContract)),
            for (final note in r.notes)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  note,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Text(label)),
        Text(value),
      ],
    ),
  );
}
