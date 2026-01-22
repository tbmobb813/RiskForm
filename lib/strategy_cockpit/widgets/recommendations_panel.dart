import 'package:flutter/material.dart';
import '../analytics/strategy_recommendations_engine.dart';

/// Lightweight Recommendations Panel: shows top up to 3 recommendations
class RecommendationsPanel extends StatelessWidget {
  final StrategyRecommendationsBundle? bundle;

  const RecommendationsPanel({super.key, this.bundle});

  @override
  Widget build(BuildContext context) {
    final recs = bundle?.recommendations ?? [];
    if (recs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(children: [Icon(Icons.lightbulb_outline), SizedBox(width: 8), Text('No recommendations')]),
        ),
      );
    }

    final top = recs.length <= 3 ? recs : recs.sublist(0, 3);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.lightbulb, size: 20),
                SizedBox(width: 8),
                Text('Recommendations', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ...top.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _priorityIcon(r.priority),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r.message)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  static Widget _priorityIcon(int p) {
    final color = p <= 2 ? Colors.redAccent : (p == 3 ? Colors.orange : Colors.grey);
    return CircleAvatar(radius: 10, backgroundColor: color, child: Text('$p', style: const TextStyle(fontSize: 12, color: Colors.white)));
  }
}
