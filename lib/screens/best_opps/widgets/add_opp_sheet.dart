import 'package:flutter/material.dart';
import '../../../models/best_opp_model.dart';

/// Bottom sheet form for logging a new Best Opp.
class AddOppSheet extends StatefulWidget {
  final String defaultDate;
  final void Function({
    required String ticker,
    required String setup,
    required String entryTrigger,
    required String whatMadeItIdeal,
    required bool wasTaken,
    String? screenshotUrl,
    String? notes,
  })
  onSave;

  const AddOppSheet({
    super.key,
    required this.defaultDate,
    required this.onSave,
  });

  @override
  State<AddOppSheet> createState() => _AddOppSheetState();
}

class _AddOppSheetState extends State<AddOppSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tickerCtrl = TextEditingController();
  final _triggerCtrl = TextEditingController();
  final _idealCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _screenshotCtrl = TextEditingController();

  String _setup = kOppSetups.first;
  bool _wasTaken = false;
  bool _saving = false;

  @override
  void dispose() {
    _tickerCtrl.dispose();
    _triggerCtrl.dispose();
    _idealCtrl.dispose();
    _notesCtrl.dispose();
    _screenshotCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    widget.onSave(
      ticker: _tickerCtrl.text.trim().toUpperCase(),
      setup: _setup,
      entryTrigger: _triggerCtrl.text.trim(),
      whatMadeItIdeal: _idealCtrl.text.trim(),
      wasTaken: _wasTaken,
      screenshotUrl: _screenshotCtrl.text.trim().isEmpty
          ? null
          : _screenshotCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle + Title ─────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Log Best Opp',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // ── Ticker + Setup row ─────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _tickerCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Ticker *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: _setup,
                    decoration: const InputDecoration(
                      labelText: 'Setup',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: kOppSetups
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _setup = v ?? _setup),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Entry Trigger ──────────────────────────────────────
            TextFormField(
              controller: _triggerCtrl,
              decoration: const InputDecoration(
                labelText: 'Entry Trigger *',
                hintText: 'e.g. Break above VWAP with volume surge',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // ── What Made It Ideal ─────────────────────────────────
            TextFormField(
              controller: _idealCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'What Made It Ideal *',
                hintText:
                    'e.g. IV rank 72, clean breakout level, earnings catalyst',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),

            // ── Notes (optional) ───────────────────────────────────
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Screenshot URL (optional) ──────────────────────────
            TextFormField(
              controller: _screenshotCtrl,
              decoration: const InputDecoration(
                labelText: 'Screenshot URL (optional)',
                hintText: 'https://...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Taken toggle ───────────────────────────────────────
            Row(
              children: [
                Switch(
                  value: _wasTaken,
                  onChanged: (v) => setState(() => _wasTaken = v),
                ),
                const SizedBox(width: 8),
                Text(
                  _wasTaken ? 'Taken' : 'Missed',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _wasTaken ? Colors.green.shade400 : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Submit ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _saving ? 'Saving…' : 'Save Opp',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
