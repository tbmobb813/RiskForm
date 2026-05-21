import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:riskform/app.dart';

/// Reusable shimmer skeleton card. Drop in place of any loading state.
class SkeletonCard extends StatelessWidget {
  final int lines;
  final String? title;
  final double titleWidth;

  const SkeletonCard({
    super.key,
    this.lines = 3,
    this.title,
    this.titleWidth = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Shimmer.fromColors(
          baseColor: AppColors.surface2,
          highlightColor: AppColors.border.withAlpha(80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title row
              _SkeletonLine(widthFactor: titleWidth, height: 16),
              const SizedBox(height: 16),
              // Content lines
              for (var i = 0; i < lines; i++) ...[
                _SkeletonLine(widthFactor: _widthForLine(i, lines), height: 12),
                if (i < lines - 1) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double _widthForLine(int i, int total) {
    // Vary widths so it looks natural: 0.9, 0.7, 0.8, 0.6...
    const pattern = [0.9, 0.7, 0.85, 0.6, 0.75];
    return pattern[i % pattern.length];
  }
}

class _SkeletonLine extends StatelessWidget {
  final double widthFactor;
  final double height;

  const _SkeletonLine({required this.widthFactor, required this.height});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Slim inline shimmer line — use inside list tiles or stat rows.
class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonLine({super.key, this.width = 80, this.height = 12});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface2,
      highlightColor: AppColors.border.withAlpha(80),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
