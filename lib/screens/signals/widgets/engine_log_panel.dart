import 'package:flutter/material.dart';
import '../../../state/signal_engine_notifier.dart';

class EngineLogPanel extends StatefulWidget {
  final List<LogLine> lines;

  const EngineLogPanel({super.key, required this.lines});

  @override
  State<EngineLogPanel> createState() => _EngineLogPanelState();
}

class _EngineLogPanelState extends State<EngineLogPanel> {
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(EngineLogPanel old) {
    super.didUpdateWidget(old);
    if (widget.lines.length != old.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Color _lineColor(LogType type) => switch (type) {
    LogType.success => const Color(0xFF00FF88),
    LogType.error => const Color(0xFFFF4400),
    LogType.info => const Color(0xFF555555),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF050505),
        border: Border.all(color: const Color(0xFF1A1A1A)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(12),
      child: widget.lines.isEmpty
          ? const Text(
              '// awaiting signal generation...',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF2A2A2A),
                fontFamily: 'monospace',
              ),
            )
          : ListView.builder(
              controller: _scroll,
              itemCount: widget.lines.length,
              itemBuilder: (context, i) {
                final line = widget.lines[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${line.time}  ',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF333333),
                            fontFamily: 'monospace',
                          ),
                        ),
                        TextSpan(
                          text: line.text,
                          style: TextStyle(
                            fontSize: 10,
                            color: _lineColor(line.type),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
