import 'package:flutter/material.dart';

class StrategyTile extends StatelessWidget {
  final String name;
  final String category;
  final Color color;
  final VoidCallback onTap;
  final bool highlighted;

  const StrategyTile({
    super.key,
    required this.name,
    required this.category,
    required this.color,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlighted ? Colors.white10 : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category Tag
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color),
                ),
                child: Text(
                  category,
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ),

              const SizedBox(width: 12),

              // Strategy Name
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}