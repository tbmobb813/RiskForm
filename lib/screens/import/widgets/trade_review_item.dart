import 'package:flutter/material.dart';
import '../../../models/imported_trade.dart';

class TradeReviewItem extends StatelessWidget {
  final ImportedTrade trade;
  final int index;
  final void Function(int) onToggle;

  const TradeReviewItem({
    super.key,
    required this.trade,
    required this.index,
    required this.onToggle,
  });

  Color _actionColor(BuildContext context, TradeAction a) {
    return switch (a) {
      TradeAction.sellToOpen || TradeAction.sell => Colors.green.shade400,
      TradeAction.buyToClose => Colors.green.shade300,
      TradeAction.buyToOpen || TradeAction.buy => Colors.red.shade400,
      TradeAction.sellToClose => Colors.orange.shade400,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final credit = trade.netValue >= 0;

    return InkWell(
      onTap: () => onToggle(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: trade.selected,
              onChanged: (_) => onToggle(index),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),

            // Date
            SizedBox(
              width: 52,
              child: Text(
                _shortDate(trade.dateTime),
                style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurface.withAlpha(120),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Symbol + action
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trade.underlying,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    trade.actionLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: _actionColor(context, trade.action),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Option details
            if (trade.isOption)
              Expanded(
                flex: 3,
                child: Text(
                  _optionSummary(trade),
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurface.withAlpha(160),
                  ),
                  maxLines: 2,
                ),
              )
            else
              Expanded(
                flex: 3,
                child: Text(
                  '${trade.quantity.toStringAsFixed(0)} shares',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withAlpha(140),
                  ),
                ),
              ),

            const SizedBox(width: 8),

            // Net value
            Text(
              _fmtValue(trade.netValue),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: credit ? Colors.green.shade400 : Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime dt) {
    const m = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[dt.month]} ${dt.day}';
  }

  String _optionSummary(ImportedTrade t) {
    if (t.expiry == null) return '';
    final exp = '${t.expiry!.month}/${t.expiry!.day}';
    final type = t.optionType == 'C' ? 'Call' : 'Put';
    final strike = t.strike != null ? '\$${t.strike!.toStringAsFixed(0)}' : '';
    return '${t.quantity.toInt()} × $exp $strike $type';
  }

  String _fmtValue(double v) {
    final abs = v.abs().toStringAsFixed(2);
    return v >= 0 ? '+\$$abs' : '-\$$abs';
  }
}
