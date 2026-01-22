import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/small_account_provider.dart';

class SmallAccountScreen extends ConsumerStatefulWidget {
  const SmallAccountScreen({super.key});

  @override
  ConsumerState<SmallAccountScreen> createState() => _SmallAccountScreenState();
}

class _SmallAccountScreenState extends ConsumerState<SmallAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smallAccountProvider);
    final notifier = ref.read(smallAccountProvider.notifier);

    final s = state.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Small Account Mode')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SwitchListTile(
                title: const Text('Enable Small Account Mode'),
                value: s.enabled,
                onChanged: notifier.updateEnabled,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: s.startingCapital.toStringAsFixed(2),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Starting Capital', errorText: state.errors['startingCapital']),
                onSaved: (v) => notifier.updateStartingCapital(double.tryParse(v ?? '') ?? s.startingCapital),
                validator: (v) {
                  final num = double.tryParse(v ?? '');
                  if (num == null || num <= 0) return 'Enter a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: (s.maxAllocationPct * 100).toStringAsFixed(1),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Max Allocation (%)', errorText: state.errors['maxAllocationPct']),
                onSaved: (v) => notifier.updateMaxAllocationPct((double.tryParse(v ?? '') ?? (s.maxAllocationPct * 100)) / 100.0),
                validator: (v) {
                  final num = double.tryParse(v ?? '');
                  if (num == null || num <= 0 || num > 100) return 'Enter % between 0-100';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: s.minTradeSize.toStringAsFixed(2),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Min Trade Size', errorText: state.errors['minTradeSize']),
                onSaved: (v) => notifier.updateMinTradeSize(double.tryParse(v ?? '') ?? s.minTradeSize),
                validator: (v) {
                  final num = double.tryParse(v ?? '');
                  if (num == null || num <= 0) return 'Enter a positive number';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: s.maxOpenPositions.toString(),
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                decoration: InputDecoration(labelText: 'Max Open Positions', errorText: state.errors['maxOpenPositions']),
                onSaved: (v) => notifier.updateMaxOpenPositions(int.tryParse(v ?? '') ?? s.maxOpenPositions),
                validator: (v) {
                  final num = int.tryParse(v ?? '');
                  if (num == null || num <= 0) return 'Enter an integer >= 1';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final form = _formKey.currentState!;
                  if (!form.validate()) return;
                  form.save();
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await notifier.save();
                  if (!mounted) return;
                  if (ok) {
                    messenger.showSnackBar(const SnackBar(content: Text('Small account settings saved')));
                  } else {
                    messenger.showSnackBar(const SnackBar(content: Text('Fix validation errors')));
                  }
                },
                child: state.saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
