import 'package:flutter/material.dart';
import '../models/watchlist_item.dart';

/// Watchlist Card - Shows up to 5 tickers for small accounts
///
/// Displays:
/// - Ticker symbol
/// - Current price (or N/A if no live data)
/// - IV percentile (or N/A if no live data)
/// - Price change % (or — if no live data)
/// - [Scan] button to open options scanner
class WatchlistCard extends StatelessWidget {
  final List<WatchlistItem> watchlist;
  final VoidCallback onAddTicker;
  final void Function(String ticker) onRemoveTicker;
  final void Function(String ticker) onScanTap;

  const WatchlistCard({
    super.key,
    required this.watchlist,
    required this.onAddTicker,
    required this.onRemoveTicker,
    required this.onScanTap,
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
                  'Watchlist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${watchlist.length}/5',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Watchlist items
            if (watchlist.isEmpty)
              _buildEmptyState()
            else
              ...watchlist.map((item) => _buildWatchlistRow(context, item)),

            const SizedBox(height: 12),

            // Add ticker button
            if (watchlist.length < 5)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAddTicker,
                  icon: const Icon(Icons.add),
                  label: Text('Add Ticker (${watchlist.length}/5 used)'),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Small accounts focus on 5 tickers max. Remove one to add another.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.show_chart, size: 48, color: Colors.black26),
          SizedBox(height: 8),
          Text(
            'No tickers in watchlist',
            style: TextStyle(color: Colors.black54),
          ),
          SizedBox(height: 4),
          Text(
            'Add your first ticker to get started',
            style: TextStyle(fontSize: 12, color: Colors.black38),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistRow(BuildContext context, WatchlistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Ticker symbol
          SizedBox(
            width: 60,
            child: Text(
              item.ticker,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Price
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.priceDisplay,
                  style: const TextStyle(fontSize: 14),
                ),
                if (!item.hasLiveData)
                  const Text(
                    'No data',
                    style: TextStyle(fontSize: 10, color: Colors.black38),
                  ),
              ],
            ),
          ),

          // IV
          SizedBox(
            width: 60,
            child: Text(
              'IV: ${item.ivDisplay}',
              style: const TextStyle(fontSize: 12),
            ),
          ),

          // Change %
          SizedBox(
            width: 70,
            child: Text(
              item.changeDisplay,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: item.isPositive
                    ? Colors.green
                    : item.isNegative
                        ? Colors.red
                        : Colors.black54,
              ),
            ),
          ),

          const Spacer(),

          // Actions
          Row(
            children: [
              TextButton(
                onPressed: () => onScanTap(item.ticker),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('Scan', style: TextStyle(fontSize: 12)),
              ),
              IconButton(
                onPressed: () => _confirmRemove(context, item.ticker),
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Remove',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context, String ticker) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Ticker'),
        content: Text('Remove $ticker from watchlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onRemoveTicker(ticker);
              Navigator.of(ctx).pop();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
