import 'package:flutter/material.dart';
import '../models/discipline_snapshot.dart';

/// Discipline Header Card - Most prominent element in the cockpit
///
/// Displays:
/// - Current discipline score (0-100) with progress bar
/// - Clean streak with fire emoji
/// - Pending journal count (if any)
/// - Contextual status message
///
/// Color-coded by discipline level (excellent/good/fair/poor)
class DisciplineHeaderCard extends StatelessWidget {
  final DisciplineSnapshot discipline;

  const DisciplineHeaderCard({
    super.key,
    required this.discipline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = _getColorScheme(discipline.level);

    return Card(
      elevation: 4,
      color: colorScheme.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Score + Streak + Pending
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score
                Expanded(
                  child: _buildScoreSection(colorScheme),
                ),

                const SizedBox(width: 16),

                // Streak
                _buildStreakSection(colorScheme),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            _buildProgressBar(colorScheme),

            const SizedBox(height: 12),

            // Status message
            Text(
              discipline.statusMessage,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.textColor.withAlpha((0.8 * 255).round()),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSection(_ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${discipline.currentScore}/100',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: colorScheme.textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          discipline.level.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakSection(_ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.accentColor.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            discipline.cleanStreak >= 5 ? '🔥' : '⭐',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            '${discipline.cleanStreak}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'streak',
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.textColor.withAlpha((0.6 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(_ColorScheme colorScheme) {
    final progress = discipline.currentScore / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: colorScheme.accentColor.withAlpha((0.2 * 255).round()),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.accentColor),
          ),
        ),
      ],
    );
  }

  _ColorScheme _getColorScheme(DisciplineLevel level) {
    switch (level) {
      case DisciplineLevel.excellent:
        return _ColorScheme(
          backgroundColor: const Color(0xFFECFDF5), // Green-50
          accentColor: const Color(0xFF10B981), // Green-500
          textColor: const Color(0xFF065F46), // Green-800
        );
      case DisciplineLevel.good:
        return _ColorScheme(
          backgroundColor: const Color(0xFFEFF6FF), // Blue-50
          accentColor: const Color(0xFF3B82F6), // Blue-500
          textColor: const Color(0xFF1E40AF), // Blue-700
        );
      case DisciplineLevel.fair:
        return _ColorScheme(
          backgroundColor: const Color(0xFFFEF3C7), // Amber-50
          accentColor: const Color(0xFFF59E0B), // Amber-500
          textColor: const Color(0xFF92400E), // Amber-800
        );
      case DisciplineLevel.poor:
        return _ColorScheme(
          backgroundColor: const Color(0xFFFEE2E2), // Red-50
          accentColor: const Color(0xFFEF4444), // Red-500
          textColor: const Color(0xFF991B1B), // Red-800
        );
      case DisciplineLevel.none:
        return _ColorScheme(
          backgroundColor: const Color(0xFFF3F4F6), // Gray-100
          accentColor: const Color(0xFF6B7280), // Gray-500
          textColor: const Color(0xFF374151), // Gray-700
        );
    }
  }
}

class _ColorScheme {
  final Color backgroundColor;
  final Color accentColor;
  final Color textColor;

  _ColorScheme({
    required this.backgroundColor,
    required this.accentColor,
    required this.textColor,
  });
}
