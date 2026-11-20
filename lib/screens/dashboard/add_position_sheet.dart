import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../exceptions/app_exceptions.dart';
import '../../models/position.dart';
import '../../services/data/position_repository.dart';

/// Bottom sheet for recording an open cash-secured put or covered call.
class AddPositionSheet extends ConsumerStatefulWidget {
  const AddPositionSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: const AddPositionSheet(),
    ),
  );

  @override
  ConsumerState<AddPositionSheet> createState() => _AddPositionSheetState();
}

class _AddPositionSheetState extends ConsumerState<AddPositionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _symbol = TextEditingController();
  final _strike = TextEditingController();
  final _premium = TextEditingController();
  final _contracts = TextEditingController(text: '1');

  PositionType _type = PositionType.csp;
  DateTime _opened = _today();
  DateTime? _expiration;
  bool _saving = false;

  @override
  void dispose() {
    _symbol.dispose();
    _strike.dispose();
    _premium.dispose();
    _contracts.dispose();
    super.dispose();
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String _date(DateTime d) => '${d.month}/${d.day}/${d.year}';

  Future<void> _pick({required bool expiration}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: expiration
          ? (_expiration ?? _opened.add(const Duration(days: 30)))
          : _opened,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;
    setState(() => expiration ? _expiration = picked : _opened = picked);
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _positiveNumber(String? v, {bool allowZero = false}) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null) return 'Enter a number';
    if (allowZero ? n < 0 : n <= 0) return 'Must be positive';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final expiration = _expiration;
    if (expiration == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pick an expiration date')));
      return;
    }
    if (!expiration.isAfter(_opened)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiration must be after the open date')),
      );
      return;
    }

    setState(() => _saving = true);
    final contracts = int.parse(_contracts.text.trim());
    final position = Position(
      type: _type,
      symbol: _symbol.text.trim().toUpperCase(),
      strategy: _type == PositionType.csp ? 'CSP' : 'CC',
      quantity: contracts,
      expiration: expiration,
      isOpen: true,
      strike: double.parse(_strike.text.trim()),
      premium: double.parse(_premium.text.trim()),
      contracts: contracts,
      openedAt: _opened,
    );

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(positionRepositoryProvider).save(position);
      navigator.pop();
    } on AuthenticationException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sign in to save positions')),
      );
      if (mounted) setState(() => _saving = false);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save the position')),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add open position',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SegmentedButton<PositionType>(
              segments: const [
                ButtonSegment(
                  value: PositionType.csp,
                  label: Text('Cash-Secured Put'),
                ),
                ButtonSegment(
                  value: PositionType.coveredCall,
                  label: Text('Covered Call'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _symbol,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Symbol',
                border: OutlineInputBorder(),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _strike,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Strike',
                      border: OutlineInputBorder(),
                    ),
                    validator: _positiveNumber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _premium,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Premium / share',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _positiveNumber(v, allowZero: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _contracts,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Contracts',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      return (n == null || n < 1) ? 'At least 1' : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pick(expiration: false),
                    child: Text('Opened ${_date(_opened)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pick(expiration: true),
                    child: Text(
                      _expiration == null
                          ? 'Pick expiration'
                          : 'Expires ${_date(_expiration!)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save position'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
