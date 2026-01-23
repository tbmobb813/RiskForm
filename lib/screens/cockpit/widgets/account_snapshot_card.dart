import 'package:flutter/material.dart';
import '../models/cockpit_state.dart';

/// Account Snapshot Card
///
/// Displays:
/// - Account balance
/// - Risk deployed
/// - Available risk
/// - Open positions count
/// - Buying power percentage
/// - Current market regime
class AccountSnapshotCard extends StatelessWidget {
  final AccountSnapshot account;
  final MarketRegime regime;

  const AccountSnapshotCard({
    super.key,
    required this.account,
    required this.regime,
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
              'Account Snapshot',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Top row: Balance + Regime
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatColumn('Balance', account.balanceDisplay),
                _buildRegimeChip(),
              ],
            ),

            const SizedBox(height: 12),

            // Second row: Risk deployed + Available
            Row(
              children: [
                Expanded(child: _buildStatColumn('Risk Deployed', account.riskDeployedDisplay)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatColumn('Available', account.availableRiskDisplay)),
              ],
            ),

            const SizedBox(height: 12),

            // Third row: Open positions + Buying power
            Row(
              children: [
                Expanded(child: _buildStatColumn('Open Positions', '${account.openPositions}')),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buying Power',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: account.buyingPowerPercent,
                                minHeight: 8,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getBuyingPowerColor(account.buyingPowerPercent),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            account.buyingPowerDisplay,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Regime hint
            if (regime != MarketRegime.unknown) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        regime.hint,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRegimeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getRegimeColor(regime).withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getRegimeColor(regime).withAlpha((0.3 * 255).round())),
      ),
      child: Text(
        regime.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getRegimeColor(regime),
        ),
      ),
    );
  }

  Color _getBuyingPowerColor(double percent) {
    if (percent > 0.7) return Colors.green;
    if (percent > 0.4) return Colors.amber;
    return Colors.red;
  }

  Color _getRegimeColor(MarketRegime regime) {
    switch (regime) {
      case MarketRegime.uptrend:
        return Colors.green;
      case MarketRegime.downtrend:
        return Colors.red;
      case MarketRegime.sideways:
        return Colors.blue;
      case MarketRegime.volatile:
        return Colors.orange;
      case MarketRegime.unknown:
        return Colors.grey;
    }
  }
}
