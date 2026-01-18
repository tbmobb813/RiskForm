import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/strategy_recommendation.dart';

// Placeholder provider — you will replace this with real logic later.
final nextStrategyProvider = Provider<StrategyRecommendation?>((ref) {
  return null; // No recommendation yet
});

class NextStrategyCard extends ConsumerWidget {
  const NextStrategyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendation = ref.watch(nextStrategyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Next Logical Strategy",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // CASE 1: No recommendation yet
            if (recommendation == null) ...[
              const Text(
                "No strategy available.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your account state does not currently produce a next logical strategy.",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: null,
                child: const Text("No Action Available"),
              ),
            ]

            // CASE 2: Recommendation exists
            else ...[
              Text(
                recommendation.strategyName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                recommendation.reason,
                style: const TextStyle(color: Colors.white70),
              ),

              // Blocking conditions
              if (recommendation.blockingConditions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: recommendation.blockingConditions.map((msg) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.amber, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              msg,
                              style: const TextStyle(color: Colors.amber),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // CTA
              ElevatedButton(
                onPressed: recommendation.blockingConditions.isNotEmpty
                    ? null
                    : () {
                        // Navigate to StrategySelectorScreen with preselection
                        GoRouter.of(context).pushNamed(
                          "planner",
                          extra: recommendation.strategyId,
                        );
                      },
                child: const Text("Plan This Strategy"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}