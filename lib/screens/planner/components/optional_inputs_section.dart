import 'package:flutter/material.dart';

class OptionalInputsSection extends StatefulWidget {
  final ValueChanged<String> onNotesChanged;

  const OptionalInputsSection({
    super.key,
    required this.onNotesChanged,
  });

  @override
  State<OptionalInputsSection> createState() => _OptionalInputsSectionState();
}

class _OptionalInputsSectionState extends State<OptionalInputsSection> {
  bool expanded = false;
  final notesController = TextEditingController();

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text("Optional Context"),
      initiallyExpanded: false,
      onExpansionChanged: (v) => setState(() => expanded = v),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: "Notes",
              border: OutlineInputBorder(),
            ),
            onChanged: widget.onNotesChanged,
          ),
        ),
      ],
    );
  }
}