import 'package:flutter/material.dart';

/// Quick Actions Card
///
/// Provides fast access to common actions:
/// - New Trade Plan (with blocking if needed)
/// - Performance Dashboard
/// - Behavior Dashboard
class QuickActionsCard extends StatelessWidget {
  final bool isBlocked;
  final VoidCallback onNewTradePlan;
  final VoidCallback onPerformance;
  final VoidCallback onBehavior;

  const QuickActionsCard({
    super.key,
    required this.isBlocked,
    required this.onNewTradePlan,
    required this.onPerformance,
    required this.onBehavior,
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
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.edit_note,
                    label: 'New Trade\nPlan',
                    onTap: onNewTradePlan,
                    color: isBlocked ? Colors.grey : Colors.blue,
                    disabled: false, // Show warning, don't disable
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.trending_up,
                    label: 'Performance',
                    onTap: onPerformance,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    context,
                    icon: Icons.psychology,
                    label: 'Behavior',
                    onTap: onBehavior,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool disabled = false,
  }) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade100 : color.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled ? Colors.grey.shade300 : color.withAlpha((0.3 * 255).round()),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: disabled ? Colors.grey : color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: disabled ? Colors.grey : color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
