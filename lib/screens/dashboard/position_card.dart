import 'package:flutter/material.dart';
import '../../models/position.dart';

class PositionCard extends StatelessWidget {
  final Position position;

  const PositionCard({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          // Placeholder navigation — you will implement PositionDetailScreen later
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Open details for ${position.symbol}")),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Symbol + Strategy Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    position.symbol,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _StrategyTag(strategy: position.strategy),
                ],
              ),

              const SizedBox(height: 8),

              // Expiration + DTE
              Text(
                "Expires ${position.expirationDateString} • ${position.dte} DTE",
                style: const TextStyle(color: Colors.white70),
              ),

              const SizedBox(height: 8),

              // Risk flags
              if (position.riskFlags.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: position.riskFlags.map((flag) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.amber, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              flag,
                              style: const TextStyle(color: Colors.amber),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrategyTag extends StatelessWidget {
  final String strategy;

  const _StrategyTag({required this.strategy});

  @override
  Widget build(BuildContext context) {
    final color = _tagColor(strategy);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        strategy,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }

  Color _tagColor(String strategy) {
    if (strategy == "CSP" || strategy == "CC" || strategy == "Credit Spread") {
      return Colors.greenAccent;
    }
    if (strategy == "Collar" || strategy == "Protective Put") {
      return Colors.yellowAccent;
    }
    return Colors.blueAccent; // Speculation
  }
}