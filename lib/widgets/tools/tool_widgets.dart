import 'package:flutter/material.dart';

/// A label on the left and a value on the right. Both wrap instead of
/// overflowing on narrow screens.
class ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const ResultRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: Text(label)),
          const SizedBox(width: 8),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

/// A card with a title followed by [children], usually [ResultRow]s.
class ResultSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ResultSection(this.title, this.children, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

enum ToolFieldKind { decimal, integer, text }

/// Outlined input used across the calculator screens.
class ToolField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ToolFieldKind kind;
  final ValueChanged<String>? onChanged;

  /// Adds the spacing used when fields are stacked in a column.
  final bool padded;

  const ToolField({
    super.key,
    required this.controller,
    required this.label,
    this.kind = ToolFieldKind.decimal,
    this.onChanged,
    this.padded = false,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      keyboardType: switch (kind) {
        ToolFieldKind.decimal => const TextInputType.numberWithOptions(
          decimal: true,
        ),
        ToolFieldKind.integer => const TextInputType.numberWithOptions(
          decimal: false,
        ),
        ToolFieldKind.text => TextInputType.text,
      },
      textCapitalization: kind == ToolFieldKind.text
          ? TextCapitalization.characters
          : TextCapitalization.none,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );

    return padded
        ? Padding(padding: const EdgeInsets.only(bottom: 12), child: field)
        : field;
  }
}
