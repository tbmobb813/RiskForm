import 'package:flutter/material.dart';
import '../models/pending_journal_trade.dart';

/// Required Action Card - Shown when user is blocked from trading
///
/// Implements behavioral friction by requiring journal completion
/// before allowing new trades.
class RequiredActionCard extends StatelessWidget {
  final List<PendingJournalTrade> pendingJournals;
  final void Function(PendingJournalTrade) onJournalTap;

  const RequiredActionCard({
    super.key,
    required this.pendingJournals,
    required this.onJournalTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: const Color(0xFFFEF3C7), // Amber-50
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFF59E0B), width: 2), // Amber-500
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Row(
              children: [
                Icon(Icons.warning, color: Color(0xFFD97706)), // Amber-600
                SizedBox(width: 8),
                Text(
                  'Required Action',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E), // Amber-800
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              pendingJournals.length == 1
                  ? '⚠️ You must journal your last trade before opening new positions'
                  : '⚠️ You must journal your last ${pendingJournals.length} trades before opening new positions',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF92400E), // Amber-800
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // Pending journals list
            ...pendingJournals.map((trade) => _buildPendingJournalTile(trade)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingJournalTile(PendingJournalTrade trade) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFBBF24)), // Amber-400
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trade.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Closed ${trade.timeAgo}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => onJournalTap(trade),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B), // Amber-500
              foregroundColor: Colors.white,
            ),
            child: const Text('Journal Now'),
          ),
        ],
      ),
    );
  }
}
