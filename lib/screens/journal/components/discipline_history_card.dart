import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/journal/daily_discipline.dart';

class DisciplineHistoryCard extends StatelessWidget {
  final List<DailyDiscipline> history;

  const DisciplineHistoryCard({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final streak = _computeStreak();
    final avg7 = _average(7);
    final avg30 = _average(30);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Discipline History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _stat('Streak', '$streak days'),
                const SizedBox(width: 12),
                _stat('Avg 7d', avg7.toStringAsFixed(1)),
                const SizedBox(width: 12),
                _stat('Avg 30d', avg30.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      tooltipRoundedRadius: 6,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((t) {
                          final idx = t.x.toInt().clamp(0, history.length - 1);
                          final date = history[idx].date;
                          final value = t.y;
                          final label = '${date.month}/${date.day}: ${value.toStringAsFixed(1)}';
                          return LineTooltipItem(label, const TextStyle(color: Colors.white, fontSize: 12));
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: history
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.score.score))
                          .toList(),
                      isCurved: true,
                      color: Colors.blueAccent,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withAlpha(38)),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _computeStreak() {
    int s = 0;
    for (var i = history.length - 1; i >= 0; i--) {
      if (history[i].score.score >= 70) {
        s++;
      } else {
        break;
      }
    }
    return s;
  }

  double _average(int n) {
    if (history.isEmpty) return 0.0;
    final start = history.length - n < 0 ? 0 : history.length - n;
    final slice = history.sublist(start);
    final sum = slice.fold<double>(0.0, (a, d) => a + d.score.score);
    return sum / slice.length;
  }
  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
