import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:riskform/app.dart';

class DisciplineRing extends StatelessWidget {
  final double score; // 0–100
  final double size;

  const DisciplineRing({super.key, required this.score, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final color = score >= 70
        ? AppColors.profit
        : score >= 40
        ? AppColors.signal
        : AppColors.loss;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(score / 100, color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toStringAsFixed(0),
                style: AppTextStyles.mono(size * 0.22, color: color),
              ),
              Text(
                'DISC',
                style: AppTextStyles.body(
                  size * 0.14,
                ).copyWith(color: AppColors.textMuted, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0.0–1.0
  final Color color;

  _RingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width / 2) - 4;
    const stroke = 5.0;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = AppColors.border.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
