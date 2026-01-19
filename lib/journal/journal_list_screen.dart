import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'journal_entry_model.dart';
import 'journal_detail_screen.dart';

class JournalListScreen extends StatelessWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('journalEntries')
        .orderBy('createdAt', descending: true)
        .snapshots();

    String _strategyName(String id) {
      // Minimal local mapping for friendly names; extend as needed.
      const map = {
        'csp': 'Cash-Secured Put',
        'cc': 'Covered Call',
        'credit_spread': 'Credit Spread',
        'protective_put': 'Protective Put',
        'collar': 'Collar',
        'long_call': 'Long Call',
        'long_put': 'Long Put',
        'debit_spread': 'Debit Spread',
        'wheel': 'Wheel',
      };
      return map[id] ?? id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No journal entries'));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final entry = JournalEntry.fromFirestore(doc);

              return ListTile(
                title: Text(_strategyName(entry.strategyId)),
                subtitle: Text(
                    '${entry.cycleState} • ${entry.createdAt.toLocal().toString().split('.').first}'),
                trailing: entry.disciplineScore != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Score'),
                          Text('${entry.disciplineScore}'),
                        ],
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JournalDetailScreen(entryId: entry.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
