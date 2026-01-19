import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../journal/journal_detail_screen.dart';

class ExecuteTradeModal extends StatefulWidget {
  final String planId; // journal entry id for the plan
  final String strategyId;

  const ExecuteTradeModal({super.key, required this.planId, required this.strategyId});

  static Future<void> show(BuildContext context, {required String planId, required String strategyId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ExecuteTradeModal(planId: planId, strategyId: strategyId),
      ),
    );
  }

  @override
  State<ExecuteTradeModal> createState() => _ExecuteTradeModalState();
}

class _ExecuteTradeModalState extends State<ExecuteTradeModal> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _contractsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _priceCtrl.dispose();
    _contractsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _execute() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final entryPrice = double.parse(_priceCtrl.text.trim());
    final contracts = int.parse(_contractsCtrl.text.trim());
    final notes = _notesCtrl.text.trim();

    final firestore = FirebaseFirestore.instance;

    try {
      // 1. Create position
      final positionRef = firestore.collection('positions').doc();
      await positionRef.set({
        'openedAt': FieldValue.serverTimestamp(),
        'strategyId': widget.strategyId,
        'planId': widget.planId,
        'entryPrice': entryPrice,
        'contracts': contracts,
        'cycleState': 'opened',
      });

      // 2. Update journal entry (planId assumed to be journal doc id)
      final journalRef = firestore.collection('journalEntries').doc(widget.planId);
      final updates = <String, dynamic>{
        'positionId': positionRef.id,
        'cycleState': 'opened',
      };
      if (notes.isNotEmpty) updates['notes'] = notes;
      await journalRef.update(updates);

      if (!mounted) return;
      Navigator.pop(context); // close modal

      // Navigate to journal detail to show updated entry
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => JournalDetailScreen(entryId: widget.planId)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Execution failed: $e')));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Execute Trade', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Entry Price'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = double.tryParse(v.trim());
                    if (n == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contractsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Contracts'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final n = int.tryParse(v.trim());
                    if (n == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesCtrl,
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loading ? null : _execute,
                        child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Confirm Execution'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
