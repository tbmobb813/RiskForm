import 'package:flutter/material.dart';
import '../../models/analytics/regime_segment.dart';
import '../../models/analytics/market_regime.dart';

class PayoffChart extends StatelessWidget {
  final List<Offset> curve;
  final double breakeven;
  final List<RegimeSegment>? regimes;

  const PayoffChart({
    super.key,
    required this.curve,
    required this.breakeven,
    this.regimes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final axisColor = theme.colorScheme.onSurface.withAlpha((0.6 * 255).round());
    return SizedBox(
      height: 240,
      child: Card(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CustomPaint(
            painter: _PayoffPainter(
              curve: curve,
              breakeven: breakeven,
              lineColor: theme.colorScheme.primary,
              axisColor: axisColor,
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
  final Color axisColor;
  final List<RegimeSegment>? regimes;

  _PayoffPainter({
    required this.curve,
    required this.breakeven,
    required this.lineColor,
    required this.axisColor,
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
      if (p.dy < minY) { minY = p.dy; }
      if (p.dy > maxY) { maxY = p.dy; }
    }
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    // axis paint reserved for other uses; specific paints below use adjusted alpha

    // draw regime background bands first (if provided)
    if (regimes != null && regimes!.isNotEmpty) {
          for (final seg in regimes!) {
        final start = seg.startIndex.toDouble();
        final end = seg.endIndex.toDouble();
        final left = _mapX(start, minX, maxX, size.width);
        final right = _mapX(end, minX, maxX, size.width);
        Color bandColor;
        switch (seg.regime) {
          case MarketRegime.uptrend:
            	bandColor = Colors.green.withAlpha((0.08 * 255).round());
            break;
          case MarketRegime.downtrend:
            	bandColor = Colors.red.withAlpha((0.08 * 255).round());
            break;
          case MarketRegime.sideways:
            	bandColor = Colors.yellow.withAlpha((0.06 * 255).round());
            break;
        }
        final rect = Rect.fromLTRB(left, 0, right, size.height);
        final paint = Paint()..color = bandColor;
        canvas.drawRect(rect, paint);
      }
    }

    // draw zero line
    final zeroY = _mapY(0, minY, maxY, size.height);
    final zeroPaint = Paint()
      ..color = axisColor.withAlpha((0.35 * 255).round())
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroPaint);

    // draw breakeven vertical
    if (breakeven >= minX && breakeven <= maxX) {
      final bx = _mapX(breakeven, minX, maxX, size.width);
      final bePaint = Paint()
        ..color = axisColor.withAlpha((0.35 * 255).round())
        ..strokeWidth = 1;
      canvas.drawLine(Offset(bx, 0), Offset(bx, size.height), bePaint);
    }

    // draw axes ticks
    final textStyle = TextStyle(color: axisColor, fontSize: 10);
    _drawXTicks(canvas, size, minX, maxX, textStyle);
    _drawYTicks(canvas, size, minY, maxY, textStyle);

    // draw payoff line
    final path = Path();
    for (var i = 0; i < curve.length; i++) {
      final p = curve[i];
      final dx = _mapX(p.dx, minX, maxX, size.width);
      final dy = _mapY(p.dy, minY, maxY, size.height);
      if (i == 0) { path.moveTo(dx, dy); }
      else { path.lineTo(dx, dy); }
    }

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paintLine);
  }

  double _mapX(double x, double minX, double maxX, double width) {
    if (maxX - minX == 0) return 0;
    return ((x - minX) / (maxX - minX)) * width;
  }

  double _mapY(double y, double minY, double maxY, double height) {
    if (maxY - minY == 0) return height / 2;
    // invert y for canvas coordinates
    return height - ((y - minY) / (maxY - minY)) * height;
  }

  void _drawXTicks(Canvas canvas, Size size, double minX, double maxX, TextStyle style) {
    final tickCount = 4;
    final interval = (maxX - minX) / tickCount;
    for (int i = 0; i <= tickCount; i++) {
      final value = minX + (i * interval);
      final x = _mapX(value, minX, maxX, size.width);
      final tp = TextPainter(
        text: TextSpan(text: value.toStringAsFixed(0), style: style),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height));
    }
  }

  void _drawYTicks(Canvas canvas, Size size, double minY, double maxY, TextStyle style) {
    final tickCount = 4;
    final interval = (maxY - minY) / tickCount;
    for (int i = 0; i <= tickCount; i++) {
      final value = minY + (i * interval);
      final y = _mapY(value, minY, maxY, size.height);
      final tp = TextPainter(
        text: TextSpan(text: _formatCurrency(value), style: style),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
  }

  String _formatCurrency(double v) {
    if (v.abs() >= 1000) {
      return '\$${(v / 1000).toStringAsFixed(1)}k';
    }
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

