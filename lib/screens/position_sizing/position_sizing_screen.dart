import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/engines/position_sizing_engine.dart';
import '../../state/account_context_provider.dart';
import '../../widgets/tools/tool_widgets.dart';

class PositionSizingScreen extends ConsumerStatefulWidget {
  /// Overrides the buying power otherwise taken from the saved account.
  final double? initialBuyingPower;

  const PositionSizingScreen({super.key, this.initialBuyingPower});

  @override
  ConsumerState<PositionSizingScreen> createState() =>
      _PositionSizingScreenState();
}

class _PositionSizingScreenState extends ConsumerState<PositionSizingScreen> {
  static const _engine = PositionSizingEngine();

  final _strike = TextEditingController();
  final _premium = TextEditingController();
  final _width = TextEditingController();
  final _account = TextEditingController();
  final _buyingPower = TextEditingController();
  final _maxCapital = TextEditingController(text: '30');
  final _maxLoss = TextEditingController(text: '10');

  SizingStrategy _strategy = SizingStrategy.csp;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    final bp = widget.initialBuyingPower;
    if (bp != null) _buyingPower.text = bp.toStringAsFixed(0);
  }

  void _applyAccount(double size, double buyingPower) {
    _account.text = size.toStringAsFixed(0);
    if (widget.initialBuyingPower == null) {
      _buyingPower.text = buyingPower.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _strike,
      _premium,
      _width,
      _account,
      _buyingPower,
      _maxCapital,
      _maxLoss,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    ref.listen(accountContextProvider, (_, next) {
      final acct = next.asData?.value;
      if (acct != null && !_prefilled && acct.accountSize > 0) {
        _prefilled = true;
        setState(() => _applyAccount(acct.accountSize, acct.buyingPower));
      }
    });
    final existing = ref.read(accountContextProvider).asData?.value;
    if (!_prefilled && existing != null && existing.accountSize > 0) {
      _prefilled = true;
      _applyAccount(existing.accountSize, existing.buyingPower);
    }

    final result = _engine.size(
      PositionSizingInput(
        strategy: _strategy,
        strike: _num(_strike),
        spreadWidth: _num(_width),
        premium: _num(_premium),
        accountSize: _num(_account),
        buyingPower: _num(_buyingPower),
        maxCapitalPercent: _num(_maxCapital),
        maxLossPercent: _num(_maxLoss),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Position Sizing')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<SizingStrategy>(
            segments: const [
              ButtonSegment(
                value: SizingStrategy.csp,
                label: Text('Cash-Secured Put'),
              ),
              ButtonSegment(
                value: SizingStrategy.creditSpread,
                label: Text('Credit Spread'),
              ),
            ],
            selected: {_strategy},
            onSelectionChanged: (s) => setState(() => _strategy = s.first),
          ),
          const SizedBox(height: 16),
          _field(
            _strike,
            _strategy == SizingStrategy.csp ? 'Put strike' : 'Short strike',
          ),
          if (_strategy == SizingStrategy.creditSpread)
            _field(_width, 'Spread width (\$)'),
          _field(
            _premium,
            _strategy == SizingStrategy.csp
                ? 'Premium per share'
                : 'Net credit per share',
          ),
          _field(_account, 'Account size (\$)'),
          _field(_buyingPower, 'Buying power (\$)'),
          _field(_maxCapital, 'Max % of account in this position'),
          _field(_maxLoss, 'Max % of account at risk'),
          const SizedBox(height: 16),
          if (result == null)
            const Text('Enter valid trade and account details to size a trade.')
          else
            _ResultCard(result: result),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => ToolField(
    controller: c,
    label: label,
    padded: true,
    onChanged: (_) => setState(() {}),
  );
}

class _ResultCard extends StatelessWidget {
  final PositionSizingResult result;
  const _ResultCard({required this.result});

  String _money(double v) => '\$${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = result;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              r.recommendedContracts == 0
                  ? 'No contracts fit your limits'
                  : '${r.recommendedContracts} contract'
                        '${r.recommendedContracts == 1 ? '' : 's'}',
              style: theme.textTheme.headlineSmall,
            ),
            if (r.recommendedContracts > 0)
              Text(
                'Limited by ${r.limitingFactor == SizingLimit.capital ? 'capital' : 'max loss'}',
                style: theme.textTheme.bodySmall,
              ),
            const Divider(height: 24),
            ResultRow('Capital per contract', _money(r.capitalPerContract)),
            ResultRow('Max loss per contract', _money(r.maxLossPerContract)),
            ResultRow('Premium per contract', _money(r.premiumPerContract)),
            ResultRow(
              'Return on capital',
              '${r.returnOnCapitalPercent.toStringAsFixed(2)}%',
            ),
            const Divider(height: 24),
            ResultRow('Max by capital', '${r.maxContractsByCapital}'),
            ResultRow('Max by risk', '${r.maxContractsByRisk}'),
            ResultRow('Total capital used', _money(r.totalCapital)),
            ResultRow(
              'Share of account',
              '${r.capitalPercentOfAccount.toStringAsFixed(1)}%',
            ),
            ResultRow('Total premium', _money(r.totalPremium)),
            ResultRow('Total max loss', _money(r.totalMaxLoss)),
            ResultRow(
              'Min account for 1 contract',
              _money(r.minAccountForOneContract),
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
    );
  }
}
