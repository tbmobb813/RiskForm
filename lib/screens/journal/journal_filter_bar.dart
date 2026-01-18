import 'package:flutter/material.dart';

class JournalFilterBar extends StatelessWidget {
  final String selectedType;
  final void Function(String) onChanged;

  const JournalFilterBar({super.key, required this.selectedType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('all'),
          _chip('cycle'),
          _chip('assignment'),
          _chip('calledAway'),
          _chip('backtest'),
        ],
      ),
    );
  }

  Widget _chip(String type) {
    final isSelected = selectedType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(type),
        selected: isSelected,
        onSelected: (_) => onChanged(type),
      ),
    );
  }
}
