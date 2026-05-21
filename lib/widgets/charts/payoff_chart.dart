import 'package:flutter/material.dart';
import 'package:riskform/app.dart';
import '../../models/analytics/regime_segment.dart';
import '../../models/analytics/market_regime.dart';

class PayoffChart extends StatelessWidget {
  final List<Offset> curve;
  final double breakeven;
  final List<RegimeSegment>? regimes;
  final String? strategyId;

  const PayoffChart({
    super.key,
    required this.curve,
    required this.breakeven,
    this.regimes,
    this.strategyId,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = StrategyTheme.color(strategyId);

    return SizedBox(
      height: 240,
      child: Card(
        color: AppColors.surface2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: CustomPaint(
            painter: _PayoffPainter(
              curve: curve,
              breakeven: breakeven,
              lineColor: lineColor,
              regimes: regimes,
            ),
          ),
        ),
      ),
    );
  }
}

class _PayoffPainter extends CustomPainter {
  final List<Offset> curve;
  final double breakeven;
  final Color lineColor;
  final List<RegimeSegment>? regimes;

  const _PayoffPainter({
    required this.curve,
    required this.breakeven,
    required this.lineColor,
    this.regimes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (curve.isEmpty) return;

    final minX = curve.first.dx;
    final maxX = curve.last.dx;
    double minY = curve.first.dy;
    double maxY = curve.first.dy;
    for (final p in curve) {
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }
    // Add vertical padding so the line never clips the card edge
    final yPad = (maxY - minY) * 0.1;
    minY -= yPad;
    maxY += yPad;

    // ── Regime bands ────────────────────────────────────────────────────────
    if (regimes != null) {
      for (final seg in regimes!) {
        Color bandColor;
        switch (seg.regime) {
          case MarketRegime.uptrend:
            bandColor = AppColors.profit.withAlpha(20);
          case MarketRegime.downtrend:
            bandColor = AppColors.loss.withAlpha(20);
          case MarketRegime.sideways:
            bandColor = AppColors.signal.withAlpha(15);
        }
        final left = _mx(seg.startIndex.toDouble(), minX, maxX, size.width);
        final right = _mx(seg.endIndex.toDouble(), minX, maxX, size.width);
        canvas.drawRect(
          Rect.fromLTRB(left, 0, right, size.height),
          Paint()..color = bandColor,
        );
      }
    }

    // ── Zero line ────────────────────────────────────────────────────────────
    final zeroY = _my(0, minY, maxY, size.height);
    canvas.drawLine(
      Offset(0, zeroY),
      Offset(size.width, zeroY),
      Paint()
        ..color = AppColors.textMuted.withAlpha(80)
        ..strokeWidth = 1.5,
    );

    // ── Profit / loss fill areas ─────────────────────────────────────────────
    _drawFill(canvas, size, minX, maxX, minY, maxY, zeroY, above: true);
    _drawFill(canvas, size, minX, maxX, minY, maxY, zeroY, above: false);

    // ── Payoff line ──────────────────────────────────────────────────────────
    final linePath = Path();
    for (var i = 0; i < curve.length; i++) {
      final dx = _mx(curve[i].dx, minX, maxX, size.width);
      final dy = _my(curve[i].dy, minY, maxY, size.height);
      i == 0 ? linePath.moveTo(dx, dy) : linePath.lineTo(dx, dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── Breakeven vertical ───────────────────────────────────────────────────
    if (breakeven >= minX && breakeven <= maxX) {
      final bx = _mx(breakeven, minX, maxX, size.width);
      canvas.drawLine(
        Offset(bx, 0),
        Offset(bx, size.height),
        Paint()
          ..color = AppColors.signal.withAlpha(120)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
      // Breakeven label badge
      _drawLabel(
        canvas,
        'BE \$${breakeven.toStringAsFixed(0)}',
        Offset(bx + 4, 4),
        AppColors.signal,
      );
    }

    // ── Axis ticks ───────────────────────────────────────────────────────────
    _drawXTicks(canvas, size, minX, maxX);
    _drawYTicks(canvas, size, minY, maxY);
  }

  /// Fill area above (profit) or below (loss) the zero line.
  void _drawFill(
    Canvas canvas,
    Size size,
    double minX,
    double maxX,
    double minY,
    double maxY,
    double zeroY, {
    required bool above,
  }) {
    final fillPath = Path();
    bool started = false;

    for (var i = 0; i < curve.length; i++) {
      final dx = _mx(curve[i].dx, minX, maxX, size.width);
      final dy = _my(curve[i].dy, minY, maxY, size.height);
      final isAbove = dy <= zeroY;

      if (above ? isAbove : !isAbove) {
        if (!started) {
          fillPath.moveTo(dx, zeroY);
          fillPath.lineTo(dx, dy);
          started = true;
        } else {
          fillPath.lineTo(dx, dy);
        }
      } else if (started) {
        fillPath.lineTo(dx, zeroY);
        fillPath.close();
        started = false;
      }
    }

    if (started) {
      final lastDx = _mx(curve.last.dx, minX, maxX, size.width);
      fillPath.lineTo(lastDx, zeroY);
      fillPath.close();
    }

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = (above ? AppColors.profit : AppColors.loss).withAlpha(30)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset pos, Color color) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(canvas, pos);
  }

  void _drawXTicks(Canvas canvas, Size size, double minX, double maxX) {
    const count = 4;
    final interval = (maxX - minX) / count;
    final style = TextStyle(
      color: AppColors.textMuted,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );
    for (var i = 0; i <= count; i++) {
      final v = minX + i * interval;
      final x = _mx(v, minX, maxX, size.width);
      final tp = TextPainter(
        text: TextSpan(text: v.toStringAsFixed(0), style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height - 2));
    }
  }

  void _drawYTicks(Canvas canvas, Size size, double minY, double maxY) {
    const count = 4;
    final interval = (maxY - minY) / count;
    final style = TextStyle(
      color: AppColors.textMuted,
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );
    for (var i = 0; i <= count; i++) {
      final v = minY + i * interval;
      final y = _my(v, minY, maxY, size.height);
      final label = v.abs() >= 1000
          ? '\$${(v / 1000).toStringAsFixed(1)}k'
          : '\$${v.toStringAsFixed(0)}';
      final tp = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(2, y - tp.height / 2));
    }
  }

  double _mx(double x, double minX, double maxX, double w) {
    if (maxX == minX) return 0;
    return ((x - minX) / (maxX - minX)) * w;
  }

  double _my(double y, double minY, double maxY, double h) {
    if (maxY == minY) return h / 2;
    return h - ((y - minY) / (maxY - minY)) * h;
  }

  @override
  bool shouldRepaint(covariant _PayoffPainter old) =>
      old.curve != curve ||
      old.breakeven != breakeven ||
      old.lineColor != lineColor ||
      old.regimes != regimes;
}
