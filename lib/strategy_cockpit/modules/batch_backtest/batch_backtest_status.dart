import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'batch_backtest_summary.dart';

class BatchBacktestStatus extends StatelessWidget {
  final String strategyId;
  final String batchId;

  const BatchBacktestStatus({required this.strategyId, required this.batchId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('strategyBacktests')
        .doc(strategyId)
        .collection('batches')
        .doc(batchId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        final data = snap.data!.data() ?? {};
        final status = data['status'];
        final summary = data['summary'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CockpitCard(
              title: "Batch Status",
              child: Text("Status: $status"),
            ),
            const SizedBox(height: 12),
            if (status == 'complete' && summary != null)
              BatchBacktestSummary(summary: Map<String, dynamic>.from(summary)),
          ],
        );
      },
    );
  }
}

class _CockpitCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _CockpitCard({required this.title, required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
