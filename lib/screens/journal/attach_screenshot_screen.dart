import 'package:flutter/material.dart';

class AttachScreenshotScreen extends StatefulWidget {
  const AttachScreenshotScreen({super.key});

  @override
  State<AttachScreenshotScreen> createState() => _AttachScreenshotScreenState();
}

class _AttachScreenshotScreenState extends State<AttachScreenshotScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attach Screenshot')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          const Text('Enter local file path for the screenshot (or URL)'),
          const SizedBox(height: 12),
          TextField(controller: _controller, decoration: const InputDecoration(labelText: 'Path or URL')),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop({'path': _controller.text});
                },
                child: const Text('Attach'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
