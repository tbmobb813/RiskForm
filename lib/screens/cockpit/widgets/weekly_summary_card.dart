import 'package:flutter/material.dart';
import '../models/weekly_summary.dart';

/// Weekly Summary Card
///
/// Shows weekly trading performance:
/// - P/L ($ and %)
/// - Number of trades
/// - Win rate
/// - Average discipline score
/// - Daily trading calendar (Mon-Sun with ✓/✗/- indicators)
class WeeklySummaryCard extends StatelessWidget {
  final WeeklySummary summary;

  const WeeklySummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This Week',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Top metrics row: P/L + Trades + Win Rate
            Row(
              children: [
                Expanded(
                  child: _buildMetric(
                    'P/L',
                    '${summary.pnlDisplay} (${summary.pnlPercentDisplay})',
                    color: summary.isPositive ? Colors.green : summary.isNegative ? Colors.red : null,
                  ),
                ),
                Expanded(
                  child: _buildMetric('Trades', '${summary.trades}'),
                ),
                Expanded(
                  child: _buildMetric('Win Rate', summary.winRateDisplay),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Avg Discipline
            _buildMetric('Avg Discipline', '${summary.avgDiscipline.toStringAsFixed(0)}/100'),

            const SizedBox(height: 16),

            // Daily calendar
            _buildDailyCalendar(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyCalendar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Activity',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 8),

        // Days of week
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: summary.dailyTrades.map((day) {
            return Column(
              children: [
                Text(
                  day.dayName,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                _buildDayIndicator(day),
              ],
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('✓', 'Clean', Colors.green),
            const SizedBox(width: 16),
            _buildLegendItem('✗', 'Violation', Colors.red),
            const SizedBox(width: 16),
            _buildLegendItem('-', 'No trade', Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildDayIndicator(DayTrade day) {
    Color color;
    if (!day.hadTrade) {
      color = Colors.grey;
    } else if (day.wasClean) {
      color = Colors.green;
    } else {
      color = Colors.red;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        day.indicator,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String symbol, String label, Color color) {
    return Row(
      children: [
        Text(
          symbol,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ],
    );
  }
}
