import 'package:flutter/material.dart';

class ToolTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool locked;
  final VoidCallback onTap;

  const ToolTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = locked ? Colors.white24 : Colors.white;

    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color)),
            if (locked)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Icon(Icons.lock, size: 16, color: Colors.white38),
              ),
          ],
        ),
      ),
    );
  }
}