import 'package:flutter/material.dart';

class NotesField extends StatelessWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const NotesField({
    super.key,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Notes (Optional)",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Why are you planning this trade? What conditions matter?",
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}