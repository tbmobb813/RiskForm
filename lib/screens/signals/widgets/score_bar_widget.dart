import 'package:flutter/material.dart';

class ScoreBarWidget extends StatelessWidget {
  final String label;
  final int value;

  const ScoreBarWidget({super.key, required this.label, required this.value});

  Color get _color {
    if (value > 20) return const Color(0xFF00FF88);
    if (value < -20) return const Color(0xFFFF4400);
    return const Color(0xFFFFAA00);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    // Normalize value (-100..100) to 0..1 for display
    final absNorm = value.abs() / 100.0;
    final isPositive = value >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF888888),
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '${value > 0 ? '+' : ''}$value',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final halfWidth = totalWidth / 2;
                final fillWidth = halfWidth * absNorm;

                return Stack(
                  children: [
                    // Track
                    Container(
                      width: totalWidth,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Center divider
                    Positioned(
                      left: halfWidth - 0.5,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 1,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    // Fill bar
                    Positioned(
                      left: isPositive ? halfWidth : halfWidth - fillWidth,
                      top: 0,
                      child: Container(
                        width: fillWidth,
                        height: 3,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withAlpha(100),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
