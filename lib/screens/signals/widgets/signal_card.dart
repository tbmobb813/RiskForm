import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/signal_model.dart';
import '../../../models/signal_planner_preset.dart';
import 'score_bar_widget.dart';

// ── Color helpers ──────────────────────────────────────────────────────────────

Color _signalColor(SignalType t) => switch (t) {
  SignalType.strongBuy => const Color(0xFF00FF88),
  SignalType.buy => const Color(0xFF00CC66),
  SignalType.neutral => const Color(0xFFFFAA00),
  SignalType.sell => const Color(0xFFFF4400),
  SignalType.strongSell => const Color(0xFFFF0000),
};

String _signalLabel(SignalType t) => switch (t) {
  SignalType.strongBuy => 'STRONG BUY',
  SignalType.buy => 'BUY',
  SignalType.neutral => 'NEUTRAL',
  SignalType.sell => 'SELL',
  SignalType.strongSell => 'STRONG SELL',
};

Color _regimeColor(RegimeType r) => switch (r) {
  RegimeType.riskOn => const Color(0xFF00FF88),
  RegimeType.riskOff => const Color(0xFFFF4400),
  RegimeType.transitional => const Color(0xFFFFAA00),
};

String _regimeLabel(RegimeType r) => switch (r) {
  RegimeType.riskOn => 'RISK ON',
  RegimeType.riskOff => 'RISK OFF',
  RegimeType.transitional => 'TRANSITIONAL',
};

// ── Widget ─────────────────────────────────────────────────────────────────────

class SignalCard extends StatelessWidget {
  final SignalModel signal;
  final VoidCallback onRemove;

  const SignalCard({super.key, required this.signal, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final sigColor = _signalColor(signal.signal);
    final regColor = _regimeColor(signal.regime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          left: BorderSide(color: sigColor, width: 3),
          top: BorderSide(color: sigColor.withAlpha(50), width: 1),
          right: BorderSide(color: sigColor.withAlpha(50), width: 1),
          bottom: BorderSide(color: sigColor.withAlpha(50), width: 1),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signal.ticker,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      signal.timeframe,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF555555),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: sigColor.withAlpha(30),
                        border: Border.all(color: sigColor),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        _signalLabel(signal.signal),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: sigColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CONFIDENCE: ${signal.confidence}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: sigColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF444444),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Regime + Catalyst chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Chip(label: _regimeLabel(signal.regime), color: regColor),
                if (signal.catalyst != null)
                  _Chip(
                    label: '⚡ ${signal.catalyst!}',
                    color: const Color(0xFFAAAAAA),
                    borderColor: const Color(0xFF333333),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Price levels
            Row(
              children: [
                _PriceTile(
                  label: 'ENTRY ZONE',
                  value: signal.entryZone,
                  color: const Color(0xFFCCCCCC),
                ),
                const SizedBox(width: 8),
                _PriceTile(
                  label: 'TARGET',
                  value: signal.target,
                  color: const Color(0xFF00FF88),
                ),
                const SizedBox(width: 8),
                _PriceTile(
                  label: 'STOP',
                  value: signal.stop,
                  color: const Color(0xFFFF4400),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Score bars
            ScoreBarWidget(label: 'MACRO', value: signal.macroScore),
            ScoreBarWidget(label: 'TECHNICAL', value: signal.technicalScore),
            ScoreBarWidget(label: 'SENTIMENT', value: signal.sentimentScore),
            ScoreBarWidget(label: 'COMPOSITE', value: signal.compositeScore),

            const SizedBox(height: 12),

            // Thesis
            _SectionLabel('THESIS'),
            const SizedBox(height: 4),
            Text(
              signal.thesis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFBBBBBB),
                height: 1.6,
              ),
            ),

            const SizedBox(height: 10),

            // Macro context
            _SectionLabel('MACRO CONTEXT'),
            const SizedBox(height: 4),
            Text(
              signal.macroContext,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF888888),
                height: 1.6,
              ),
            ),

            // Options edge
            if (signal.optionsEdge != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1A14),
                  border: Border.all(color: const Color(0x3000FF88)),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OPTIONS EDGE',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0x6600FF88),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      signal.optionsEdge!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF00CC66),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tap to open strategy planner pre-filled from this signal
                    GestureDetector(
                      onTap: () => context.pushNamed(
                        'planner',
                        extra: SignalPlannerPreset.fromSignal(signal),
                      ),
                      child: const Text(
                        'Open in Planner →',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF00FF88),
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0x6600FF88),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Key risks
            if (signal.keyRisks.isNotEmpty) ...[
              const SizedBox(height: 10),
              _SectionLabel('KEY RISKS'),
              const SizedBox(height: 4),
              ...signal.keyRisks.map(
                (r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '▸  ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0x66FF4400),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          r,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Sources
            if (signal.dataSourcesUsed.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF1A1A1A), thickness: 1),
              const SizedBox(height: 6),
              Text(
                'SOURCES: ${signal.dataSourcesUsed.join(' · ')}',
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF444444),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Small helpers ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 9,
      color: Color(0xFF555555),
      letterSpacing: 1.2,
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color? borderColor;

  const _Chip({required this.label, required this.color, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final bc = borderColor ?? color.withAlpha(70);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: bc),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: color, letterSpacing: 0.8),
      ),
    );
  }
}

class _PriceTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PriceTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xFF555555),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    ),
  );
}
