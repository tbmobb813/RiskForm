import 'package:flutter/material.dart';
import 'package:riskform/app.dart';

/// First-class Greeks display. Delta is live from trade inputs;
/// Gamma/Theta/Vega are placeholders until a pricing engine is wired in.
class GreeksPanel extends StatelessWidget {
  final double? delta;
  final double? gamma;
  final double? theta;
  final double? vega;

  const GreeksPanel({super.key, this.delta, this.gamma, this.theta, this.vega});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        children: [
          _Greek(
            symbol: 'Δ',
            name: 'Delta',
            value: delta,
            formatFn: (v) => v.toStringAsFixed(2),
            color: _deltaColor(delta),
          ),
          _divider(),
          _Greek(
            symbol: 'Γ',
            name: 'Gamma',
            value: gamma,
            formatFn: (v) => v.toStringAsFixed(4),
          ),
          _divider(),
          _Greek(
            symbol: 'Θ',
            name: 'Theta',
            value: theta,
            formatFn: (v) => v.toStringAsFixed(2),
            color: theta != null && theta! < 0 ? AppColors.loss : null,
          ),
          _divider(),
          _Greek(
            symbol: 'V',
            name: 'Vega',
            value: vega,
            formatFn: (v) => v.toStringAsFixed(2),
          ),
        ],
      ),
    );
  }

  Color _deltaColor(double? d) {
    if (d == null) return AppColors.textSecondary;
    if (d > 0.3) return AppColors.profit;
    if (d < -0.3) return AppColors.loss;
    return AppColors.signal;
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.border);
}

class _Greek extends StatelessWidget {
  final String symbol;
  final String name;
  final double? value;
  final String Function(double) formatFn;
  final Color? color;

  const _Greek({
    required this.symbol,
    required this.name,
    required this.value,
    required this.formatFn,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    final displayValue = value != null ? formatFn(value!) : '—';

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(symbol, style: AppTextStyles.mono(18, color: c)),
          const SizedBox(height: 2),
          Text(displayValue, style: AppTextStyles.mono(13, color: c)),
          const SizedBox(height: 1),
          Text(
            name,
            style: AppTextStyles.body(
              9,
            ).copyWith(color: AppColors.textMuted, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}
