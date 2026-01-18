import 'package:flutter/material.dart';
import '../../../models/comparison/comparison_result.dart';

class ComparisonEquityChart extends StatelessWidget {
  final ComparisonResult result;

  const ComparisonEquityChart({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final curves = result.results
        .map((r) => r.equityCurve.map((e) => e.toDouble()).toList())
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Equity Curve Comparison",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: _MultiLineChart(curves: curves, labels: result.results.map((r) => (r.notes.isNotEmpty) ? r.notes.first : '').toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiLineChart extends StatelessWidget {
  final List<List<double>> curves;
  final List<String> labels;

  const _MultiLineChart({required this.curves, required this.labels});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MultiLinePainter(curves: curves, labels: labels, theme: Theme.of(context)),
      size: Size.infinite,
    );
  }
}

class _MultiLinePainter extends CustomPainter {
  final List<List<double>> curves;
  final List<String> labels;
  final ThemeData theme;

  _MultiLinePainter({required this.curves, required this.labels, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    if (curves.isEmpty) return;

    final allY = <double>[];
    int maxLen = 0;
    for (final c in curves) {
      allY.addAll(c);
      if (c.length > maxLen) maxLen = c.length;
    }
    if (allY.isEmpty) return;

    double minY = allY.reduce((a, b) => a < b ? a : b);
    double maxY = allY.reduce((a, b) => a > b ? a : b);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    // draw axes lines
    final axisPaint = Paint()..color = theme.colorScheme.onSurface.withAlpha(80);
    final leftPadding = 44.0;
    final bottomPadding = 24.0;
    final w = size.width - leftPadding - 8;
    final h = size.height - bottomPadding - 8;

    // y ticks
    final tpStyle = TextStyle(color: theme.colorScheme.onSurface.withAlpha(140), fontSize: 10);
    final tickCount = 4;
    for (int i = 0; i <= tickCount; i++) {
      final v = minY + (i * (maxY - minY) / tickCount);
      final y = 8 + h - (i * h / tickCount);
      final tp = TextPainter(text: TextSpan(text: v.toStringAsFixed(0), style: tpStyle), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(6, y - tp.height / 2));
      canvas.drawLine(Offset(leftPadding, y), Offset(leftPadding + w, y), axisPaint..strokeWidth = 0.5);
    }

    // draw each curve
    for (var ci = 0; ci < curves.length; ci++) {
      final c = curves[ci];
      if (c.isEmpty) continue;
      final color = Colors.primaries[ci % Colors.primaries.length];
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (var i = 0; i < c.length; i++) {
        final x = leftPadding + (i / (maxLen - 1 > 0 ? (maxLen - 1) : 1)) * w;
        final y = 8 + h - ((c[i] - minY) / (maxY - minY)) * h;
        if (i == 0) path.moveTo(x, y);
        else path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }

    // legend
    final legendX = leftPadding + 8;
    double legendY = 8;
    for (var i = 0; i < labels.length; i++) {
      final label = labels[i].isNotEmpty ? labels[i] : 'Series ${i + 1}';
      final color = Colors.primaries[i % Colors.primaries.length];
      final r = Rect.fromLTWH(legendX, legendY, 12, 8);
      final boxPaint = Paint()..color = color;
      canvas.drawRect(r, boxPaint);
      final tp = TextPainter(text: TextSpan(text: '  $label', style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 11)), textDirection: TextDirection.ltr);
      tp.layout(maxWidth: size.width - legendX - 8);
      tp.paint(canvas, Offset(legendX + 18, legendY - 4));
      legendY += 18;
      if (legendY > size.height - 30) break; // avoid overflow
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
