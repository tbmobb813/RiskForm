import 'package:flutter/material.dart';

class TagsSection extends StatefulWidget {
  final List<String> selectedTags;
  final ValueChanged<List<String>> onChanged;

  const TagsSection({
    super.key,
    required this.selectedTags,
    required this.onChanged,
  });

  @override
  State<TagsSection> createState() => _TagsSectionState();
}

class _TagsSectionState extends State<TagsSection> {
  late List<String> _tags;
  final TextEditingController _controller = TextEditingController();

  // Available tag options
  static const List<String> availableTags = [
    'bullish',
    'bearish',
    'high_risk',
    'low_risk',
    'earnings_play',
    'swing_trade',
    'day_trade',
    'hedge',
    'income',
    'speculative',
  ];

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.selectedTags);
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
      widget.onChanged(_tags);
      _controller.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    widget.onChanged(_tags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tags (Optional)",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        // Display selected tags
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () => _removeTag(tag),
              );
            }).toList(),
          ),
        if (_tags.isNotEmpty) const SizedBox(height: 12),
        // Tag input field with suggestions
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: "Add a tag (e.g., bullish, hedge, income)",
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_controller.text.toLowerCase()),
            ),
          ),
          onSubmitted: (value) => _addTag(value.toLowerCase()),
        ),
        const SizedBox(height: 8),
        // Show available tag suggestions
        Wrap(
          spacing: 8,
          children: availableTags
              .where((tag) => !_tags.contains(tag))
              .map((tag) {
                return ActionChip(
                  label: Text(tag),
                  onPressed: () => _addTag(tag),
                );
              })
              .toList(),
        ),
      ],
    );
  }
}