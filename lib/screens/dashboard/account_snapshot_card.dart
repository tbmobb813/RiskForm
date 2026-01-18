import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/account_snapshot.dart';

// Placeholder provider — you will replace this with real logic later.
final accountSnapshotProvider = Provider<AccountSnapshot?>((ref) {
  return null; // No snapshot yet
});

class AccountSnapshotCard extends ConsumerWidget {
  const AccountSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(accountSnapshotProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Account Snapshot",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // CASE 1: No snapshot yet
            if (snapshot == null) ...[
              const Text("Account Size: —"),
              const Text("Buying Power: —"),
              const Text("Shares Owned: —"),
              const Text("Risk Exposure: —"),
              const SizedBox(height: 8),
              const Text(
                "No account data available.",
                style: TextStyle(color: Colors.white70),
              ),
            ]

            // CASE 2: Snapshot available
            else ...[
              _row("Account Size", snapshot.accountSizeString),
              _row("Buying Power", snapshot.buyingPowerString),
              const SizedBox(height: 8),

              const Text(
                "Shares Owned",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),

              if (snapshot.sharesOwned.isEmpty)
                const Text("None", style: TextStyle(color: Colors.white70))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: snapshot.sharesOwned.entries.map((entry) {
                    return Text("${entry.key} • ${entry.value} shares");
                  }).toList(),
                ),

              const SizedBox(height: 12),

              _riskExposure(snapshot.totalRiskExposurePercent),

              const SizedBox(height: 12),

              _row("Wheel State", snapshot.wheelStateLabel),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _riskExposure(double percent) {
    Color color;
    if (percent < 10) {
      color = Colors.white70;
    } else if (percent < 25) {
      color = Colors.amber;
    } else {
      color = Colors.redAccent;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Risk Exposure"),
        Text(
          "${percent.toStringAsFixed(1)}%",
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}