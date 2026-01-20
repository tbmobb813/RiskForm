import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'batch_backtest_viewmodel.dart';
import 'batch_backtest_status.dart';

class BatchBacktestLauncher extends StatefulWidget {
  final String strategyId;

  const BatchBacktestLauncher({required this.strategyId, Key? key})
      : super(key: key);

  @override
  State<BatchBacktestLauncher> createState() => _BatchBacktestLauncherState();
}

class _BatchBacktestLauncherState extends State<BatchBacktestLauncher> {
  final List<Map<String, dynamic>> grid = [];
  final Map<String, dynamic> currentParams = {};

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BatchBacktestViewModel(strategyId: widget.strategyId),
      child: Consumer<BatchBacktestViewModel>(
        builder: (context, vm, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Batch Backtest",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),

              _ParameterBuilder(
                currentParams: currentParams,
                onAdd: () {
                  setState(() {
                    grid.add(Map<String, dynamic>.from(currentParams));
                    currentParams.clear();
                  });
                },
              ),

              const SizedBox(height: 12),
              _GridPreview(grid: grid),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: vm.loading
                    ? null
                    : () async {
                        await vm.createBatch(grid);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Batch created")),
                        );
                      },
                child: vm.loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Run Batch Backtest"),
              ),

              if (vm.batchId != null) ...[
                const SizedBox(height: 24),
                BatchBacktestStatus(
                    strategyId: widget.strategyId, batchId: vm.batchId!),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ParameterBuilder extends StatelessWidget {
  final Map<String, dynamic> currentParams;
  final VoidCallback onAdd;

  const _ParameterBuilder({required this.currentParams, required this.onAdd, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _CockpitCard(
      title: "Add Parameter Set",
      child: Column(
        children: [
          _ParamField(
            label: "DTE",
            onChanged: (v) => currentParams['dte'] = int.tryParse(v),
          ),
          _ParamField(
            label: "Delta",
            onChanged: (v) => currentParams['delta'] = double.tryParse(v),
          ),
          _ParamField(
            label: "Width",
            onChanged: (v) => currentParams['width'] = double.tryParse(v),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onAdd,
            child: const Text("Add Parameter Set"),
          ),
        ],
      ),
    );
  }
}

class _ParamField extends StatelessWidget {
  final String label;
  final Function(String) onChanged;

  const _ParamField({required this.label, required this.onChanged, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }
}

class _GridPreview extends StatelessWidget {
  final List<Map<String, dynamic>> grid;

  const _GridPreview({required this.grid, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (grid.isEmpty) {
      return const Text("No parameter sets added.");
    }

    return _CockpitCard(
      title: "Parameter Grid",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: grid.map((g) => Text(g.toString())).toList(),
      ),
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
      width: double.infinity,
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
