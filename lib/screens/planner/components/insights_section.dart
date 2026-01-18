import 'package:flutter/material.dart';

class InsightsSection extends StatelessWidget {
  final String? strategyId;

  const InsightsSection({super.key, required this.strategyId});

  @override
  Widget build(BuildContext context) {
    final insights = _insightsForStrategy(strategyId);

    return ExpansionTile(
      title: const Text("Strategy Insights"),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: insights
                .map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(i, style: const TextStyle(color: Colors.white70)),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  List<String> _insightsForStrategy(String? id) {
    switch (id) {
      case "csp":
        return [
          "This strategy is typically used for income generation.",
          "Assignment risk increases below breakeven.",
        ];
      case "cc":
        return [
          "Covered calls generate income but cap upside.",
          "Assignment occurs if price exceeds strike at expiration.",
        ];
      case "credit_spread":
        return [
          "Defined-risk income strategy.",
          "Max gain occurs if underlying stays above short strike.",
        ];
      case "collar":
        return [
          "Collars reduce downside at the cost of capped upside.",
          "Useful for protecting long stock positions.",
        ];
      default:
        return ["No insights available."];
    }
  }
}
