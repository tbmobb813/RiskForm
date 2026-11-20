import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/engines/csp_screener_engine.dart';
import '../../services/options/chain_parser.dart';
import '../../services/options/option_chain.dart';
import '../../state/account_context_provider.dart';
import '../../widgets/tools/tool_widgets.dart';
import '../position_sizing/position_sizing_args.dart';

const _sampleChain = '''type,strike,dte,bid,ask,delta,iv,open interest
put,95,30,1.20,1.30,-0.25,32,500
put,92,30,0.80,0.90,-0.18,31,650
put,90,30,0.50,0.55,-0.12,30,800
put,95,45,1.90,1.95,-0.27,31,400
put,90,45,1.10,1.20,-0.17,30,300
put,97,30,1.80,2.00,-0.33,33,350
put,85,30,0.15,0.30,-0.06,29,900
call,105,30,0.90,1.00,0.22,28,300''';

class CspScreenerScreen extends ConsumerStatefulWidget {
  const CspScreenerScreen({super.key});

  @override
  ConsumerState<CspScreenerScreen> createState() => _CspScreenerScreenState();
}

class _CspScreenerScreenState extends ConsumerState<CspScreenerScreen> {
  static const _parser = ChainParser();
  static const _screener = CspScreenerEngine();

  final _chain = TextEditingController();
  final _spot = TextEditingController();
  final _buyingPower = TextEditingController();
  final _minDte = TextEditingController(text: '21');
  final _maxDte = TextEditingController(text: '60');
  final _maxAssignment = TextEditingController(text: '30');
  final _minReturn = TextEditingController(text: '10');
  final _maxSpread = TextEditingController(text: '15');
  final _minOi = TextEditingController();

  bool _prefilled = false;
  ChainParseResult? _parsed;
  CspScreenResult? _result;
  String? _message;

  @override
  void dispose() {
    for (final c in [
      _chain,
      _spot,
      _buyingPower,
      _minDte,
      _maxDte,
      _maxAssignment,
      _minReturn,
      _maxSpread,
      _minOi,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _optionalNumber(TextEditingController c) =>
      double.tryParse(c.text.trim());

  void _prefill(double buyingPower) {
    if (_prefilled || buyingPower <= 0) return;
    _prefilled = true;
    _buyingPower.text = buyingPower.toStringAsFixed(0);
  }

  void _loadExample() {
    setState(() {
      _chain.text = _sampleChain;
      _spot.text = '100';
      _parsed = null;
      _result = null;
      _message = null;
    });
  }

  void _run() {
    final spot = _optionalNumber(_spot);
    final buyingPower = _optionalNumber(_buyingPower);
    if (spot == null || spot <= 0) {
      setState(() {
        _parsed = null;
        _result = null;
        _message = 'Enter the current stock price.';
      });
      return;
    }
    if (buyingPower == null || buyingPower <= 0) {
      setState(() {
        _parsed = null;
        _result = null;
        _message = 'Enter the cash you can use per position.';
      });
      return;
    }

    final asOf = DateTime.now();
    final parsed = _parser.parse(_chain.text, asOf: asOf);
    final result = parsed.quotes.isEmpty
        ? null
        : _screener.screen(
            ChainSnapshot(
              underlying: '',
              spot: spot,
              asOf: asOf,
              quotes: parsed.quotes,
            ),
            CspCriteria(
              buyingPower: buyingPower,
              minDte: int.tryParse(_minDte.text.trim()) ?? 0,
              maxDte: int.tryParse(_maxDte.text.trim()) ?? 365,
              maxAssignmentPercent: _optionalNumber(_maxAssignment),
              minAnnualizedReturnPercent: _optionalNumber(_minReturn) ?? 0,
              minOpenInterest: _optionalNumber(_minOi)?.round(),
              maxSpreadPercent: _optionalNumber(_maxSpread),
            ),
          );

    setState(() {
      _parsed = parsed;
      _result = result;
      _message = result == null && parsed.quotes.isNotEmpty
          ? 'Check your filters: the expiration range looks backwards.'
          : null;
    });
  }

  Widget _field(
    TextEditingController c,
    String label, {
    ToolFieldKind kind = ToolFieldKind.decimal,
  }) => ToolField(controller: c, label: label, kind: kind);

  @override
  Widget build(BuildContext context) {
    ref.listen(accountContextProvider, (_, next) {
      final a = next.asData?.value;
      if (a != null && !_prefilled && a.buyingPower > 0) {
        setState(() => _prefill(a.buyingPower));
      }
    });
    final existing = ref.read(accountContextProvider).asData?.value;
    if (existing != null) _prefill(existing.buyingPower);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('CSP Screener')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Paste an option chain as CSV or tab-separated text with a header '
            'row. Needed: strike, bid, and expiration or DTE. Optional: ask, '
            'delta, IV, open interest, and type (put or call).',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _chain,
            minLines: 6,
            maxLines: 12,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Option chain',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _loadExample,
              child: const Text('Load example'),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _field(_spot, 'Stock price')),
              const SizedBox(width: 8),
              Expanded(child: _field(_buyingPower, 'Cash per position (\$)')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(_minDte, 'Min DTE', kind: ToolFieldKind.integer),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field(_maxDte, 'Max DTE', kind: ToolFieldKind.integer),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field(_maxAssignment, 'Max assignment %')),
              const SizedBox(width: 8),
              Expanded(child: _field(_minReturn, 'Min annualized %')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field(_maxSpread, 'Max spread %')),
              const SizedBox(width: 8),
              Expanded(
                child: _field(
                  _minOi,
                  'Min open interest',
                  kind: ToolFieldKind.integer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Leave a limit blank to skip it. A limit excludes quotes that are '
            'missing that data.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _run,
              child: const Text('Run screen'),
            ),
          ),
          const SizedBox(height: 16),
          if (_message != null)
            Text(_message!, style: TextStyle(color: theme.colorScheme.error)),
          if (_parsed != null) ..._parseNotes(theme, _parsed!),
          if (_result != null) ..._results(theme, _result!),
        ],
      ),
    );
  }

  List<Widget> _parseNotes(ThemeData theme, ChainParseResult parsed) {
    if (parsed.errors.isEmpty) return const [];
    const shown = 5;
    return [
      ResultSection('Could not read ${parsed.errors.length} line(s)', [
        for (final e in parsed.errors.take(shown)) Text(e),
        if (parsed.errors.length > shown)
          Text('and ${parsed.errors.length - shown} more'),
      ]),
    ];
  }

  List<Widget> _results(ThemeData theme, CspScreenResult result) {
    final spot = _optionalNumber(_spot) ?? 0;
    final buyingPower = _optionalNumber(_buyingPower) ?? 0;
    final n = result.candidates.length;

    return [
      Text(
        '$n ${n == 1 ? 'candidate' : 'candidates'} · '
        '${result.evaluated} quotes checked',
        style: theme.textTheme.titleMedium,
      ),
      if (result.rejections.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          'Filtered out: ${[for (final e in result.rejections.entries) '${e.value} ${e.key.label}'].join(', ')}.',
          style: theme.textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: 8),
      for (final c in result.candidates)
        _candidateCard(c, spot: spot, buyingPower: buyingPower),
    ];
  }

  Widget _candidateCard(
    CspCandidate c, {
    required double spot,
    required double buyingPower,
  }) {
    final q = c.quote;
    final exp = q.expiration;
    final assignment = c.assignmentPercent == null
        ? 'unknown'
        : '${c.assignmentPercent!.toStringAsFixed(1)}% '
              '(${c.assignmentSource == AssignmentSource.delta ? 'delta' : 'from IV'})';

    return ResultSection(
      '\$${q.strike.toStringAsFixed(q.strike == q.strike.roundToDouble() ? 0 : 2)} put · '
      '${c.dte} DTE (${exp.month}/${exp.day}/${exp.year})',
      [
        ResultRow('Credit (bid)', '\$${c.credit.toStringAsFixed(2)}'),
        ResultRow(
          'Annualized return',
          '${c.annualizedReturnPercent.toStringAsFixed(1)}%',
        ),
        ResultRow(
          'Return this cycle',
          '${c.returnPercent.toStringAsFixed(2)}%',
        ),
        ResultRow('Chance of assignment', assignment),
        ResultRow(
          'Breakeven',
          '\$${c.breakeven.toStringAsFixed(2)} '
              '(${c.cushionPercent.toStringAsFixed(1)}% below stock)',
        ),
        ResultRow(
          'Collateral per contract',
          '\$${c.collateral.toStringAsFixed(0)}',
        ),
        ResultRow(
          'Spread',
          c.spreadPercent == null
              ? 'unknown'
              : '${c.spreadPercent!.toStringAsFixed(1)}%',
        ),
        ResultRow('Open interest', q.openInterest?.toString() ?? 'unknown'),
        ResultRow('Contracts you can afford', '${c.contractsAffordable}'),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => GoRouter.of(context).pushNamed(
              'position_sizing',
              extra: PositionSizingArgs(
                buyingPower: buyingPower,
                strike: q.strike,
                premium: c.credit,
              ),
            ),
            icon: const Icon(Icons.straighten),
            label: const Text('Size this trade'),
          ),
        ),
      ],
    );
  }
}
