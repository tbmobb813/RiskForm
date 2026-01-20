import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'parameter_grid_viewmodel.dart';
import 'parameter_presets.dart';
import 'parameter_range.dart';
import '../../services/batch_backtest_service.dart';

class ParameterGridBuilder extends StatelessWidget {
  final String strategyId;

  const ParameterGridBuilder({required this.strategyId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParameterGridViewModel(),
      child: _ParameterGridBuilderView(strategyId: strategyId),
    );
  }
}

class _ParameterGridBuilderView extends StatelessWidget {
  final String strategyId;

  const _ParameterGridBuilderView({required this.strategyId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ParameterGridViewModel>(
      builder: (context, vm, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PresetsRow(onSelect: vm.applyPreset),
            const SizedBox(height: 16),
            _RangeSliders(vm: vm),
            const SizedBox(height: 24),
            _GridPreview(grid: vm.grid),
            const SizedBox(height: 24),
            _RunBatchButton(strategyId: strategyId, grid: vm.grid),
          ],
        );
      },
    );
  }
}

class _PresetsRow extends StatelessWidget {
  final Function(Map<String, ParameterRange>) onSelect;

  const _PresetsRow({required this.onSelect, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _CockpitCard(
      title: 'Presets',
      child: Wrap(
        spacing: 12,
        children: parameterPresets.entries.map((e) {
          return OutlinedButton(
            onPressed: () => onSelect(e.value),
            child: Text(e.key),
          );
        }).toList(),
      ),
    );
  }
}

class _RangeSliders extends StatelessWidget {
  final ParameterGridViewModel vm;

  const _RangeSliders({required this.vm, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _CockpitCard(
      title: 'Parameter Ranges',
      child: Column(
        children: [
          _RangeSliderRow(
            label: 'DTE',
            range: vm.dte,
            min: 5,
            max: 60,
            step: 5,
            onChanged: (r) => vm.updateDte(r),
          ),
          _RangeSliderRow(
            label: 'Delta',
            range: vm.delta,
            min: 0.05,
            max: 0.40,
            step: 0.05,
            onChanged: (r) => vm.updateDelta(r),
          ),
          _RangeSliderRow(
            label: 'Width',
            range: vm.width,
            min: 1,
            max: 10,
            step: 1,
            onChanged: (r) => vm.updateWidth(r),
          ),
        ],
      ),
    );
  }
}

class _RangeSliderRow extends StatefulWidget {
  final String label;
  final ParameterRange range;
  final double min;
  final double max;
  final double step;
  final Function(ParameterRange) onChanged;

  const _RangeSliderRow({
    required this.label,
    required this.range,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<_RangeSliderRow> createState() => _RangeSliderRowState();
}

class _RangeSliderRowState extends State<_RangeSliderRow> {
  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = RangeValues(widget.range.start, widget.range.end);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.label}: ${_values.start} → ${_values.end} (step ${widget.step})'),
        RangeSlider(
          values: _values,
          min: widget.min,
          max: widget.max,
          divisions: ((widget.max - widget.min) / widget.step).round(),
          labels: RangeLabels('${_values.start}', '${_values.end}'),
          onChanged: (v) {
            setState(() => _values = v);
            widget.onChanged(ParameterRange(start: v.start, end: v.end, step: widget.step));
          },
        ),
      ],
    );
  }
}

class _GridPreview extends StatelessWidget {
  final List<Map<String, dynamic>> grid;

  const _GridPreview({required this.grid, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _CockpitCard(
      title: 'Generated Parameter Grid (${grid.length} sets)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...grid.take(10).map((g) => Text(g.toString())),
          if (grid.length > 10) Text('… +${grid.length - 10} more'),
        ],
      ),
    );
  }
}

class _RunBatchButton extends StatelessWidget {
  final String strategyId;
  final List<Map<String, dynamic>> grid;

  const _RunBatchButton({required this.strategyId, required this.grid, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: grid.isEmpty
          ? null
          : () async {
              final batchService = BatchBacktestService();
              await batchService.createBatchJob(strategyId: strategyId, parameterGrid: grid);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch Backtest Started')));
            },
      child: const Text('Run Batch Backtest'),
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
