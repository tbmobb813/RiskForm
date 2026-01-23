import 'package:flutter/material.dart';
import '../models/cockpit_state.dart';

/// Open Positions Card
///
/// Shows all open positions with key metrics:
/// - Strategy + ticker + strike
/// - Days to expiration (DTE)
/// - Theta per day
/// - Unrealized P/L
/// - Action buttons: Manage, Journal & Close
class OpenPositionsCard extends StatelessWidget {
  final List<OpenPosition> positions;
  final void Function(OpenPosition) onManageTap;
  final void Function(OpenPosition) onJournalAndCloseTap;

  const OpenPositionsCard({
    super.key,
    required this.positions,
    required this.onManageTap,
    required this.onJournalAndCloseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Open Positions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${positions.length}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (positions.isEmpty)
              _buildEmptyState()
            else
              ...positions.map((position) => _buildPositionTile(position)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.assessment_outlined, size: 48, color: Colors.black26),
          SizedBox(height: 8),
          Text(
            'No open positions',
            style: TextStyle(color: Colors.black54),
          ),
          SizedBox(height: 4),
          Text(
            'Create a trade plan to open your first position',
            style: TextStyle(fontSize: 12, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionTile(OpenPosition position) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Strategy name + P/L
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                position.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                position.pnlDisplay,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: position.isProfit
                      ? Colors.green
                      : position.isLoss
                          ? Colors.red
                          : Colors.black54,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Metrics row: DTE + Theta
          Row(
            children: [
              _buildMetric('${position.dte} DTE'),
              const SizedBox(width: 16),
              _buildMetric('Θ: ${position.thetaDisplay}'),
              if (position.isPaper) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Text(
                    'PAPER',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onManageTap(position),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Manage', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => onJournalAndCloseTap(position),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Journal & Close', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String text) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 6, color: Colors.black54),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}
