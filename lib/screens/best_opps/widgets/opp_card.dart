import 'package:flutter/material.dart';
import '../../../models/best_opp_model.dart';

class OppCard extends StatelessWidget {
  final BestOppModel opp;
  final VoidCallback onToggleTaken;
  final VoidCallback onDelete;

  const OppCard({
    super.key,
    required this.opp,
    required this.onToggleTaken,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final taken = opp.wasTaken;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            opp.ticker,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _SetupChip(label: opp.setup),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(opp.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withAlpha(120),
                        ),
                      ),
                    ],
                  ),
                ),
                // Taken / Missed toggle
                GestureDetector(
                  onTap: onToggleTaken,
                  child: _TakenBadge(taken: taken),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  color: cs.onSurface.withAlpha(80),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Screenshot ──────────────────────────────────────────
            if (opp.screenshotUrl != null && opp.screenshotUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _ScreenshotWidget(url: opp.screenshotUrl!),
              ),
              const SizedBox(height: 10),
            ],

            // ── Entry Trigger ───────────────────────────────────────
            _FieldBlock(label: 'Entry Trigger', value: opp.entryTrigger),

            const SizedBox(height: 8),

            // ── What Made It Ideal ──────────────────────────────────
            _FieldBlock(
              label: 'What Made It Ideal',
              value: opp.whatMadeItIdeal,
            ),

            // ── Notes ───────────────────────────────────────────────
            if (opp.notes != null && opp.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                opp.notes!,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withAlpha(140),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String yyyy_mm_dd) {
    try {
      final dt = DateTime.parse(yyyy_mm_dd);
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return yyyy_mm_dd;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Opp'),
        content: Text('Remove ${opp.ticker} opp from your log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SetupChip extends StatelessWidget {
  final String label;
  const _SetupChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    ),
  );
}

class _TakenBadge extends StatelessWidget {
  final bool taken;
  const _TakenBadge({required this.taken});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          taken ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: taken ? Colors.green.shade400 : Colors.grey,
        ),
        const SizedBox(width: 4),
        Text(
          taken ? 'Taken' : 'Missed',
          style: TextStyle(
            fontSize: 11,
            color: taken ? Colors.green.shade400 : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FieldBlock extends StatelessWidget {
  final String label;
  final String value;
  const _FieldBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
          letterSpacing: 0.3,
        ),
      ),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontSize: 13)),
    ],
  );
}

class _ScreenshotWidget extends StatelessWidget {
  final String url;
  const _ScreenshotWidget({required this.url});

  bool get _isNetwork =>
      url.startsWith('http://') || url.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return Image.network(
        url,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(context),
      );
    }
    // Local path — show a file icon placeholder
    return _placeholder(context);
  }

  Widget _placeholder(BuildContext context) => Container(
    height: 60,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image_outlined, size: 20),
        SizedBox(width: 6),
        Text('Screenshot attached', style: TextStyle(fontSize: 12)),
      ],
    ),
  );
}
