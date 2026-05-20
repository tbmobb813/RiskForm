import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/signal_engine_notifier.dart';
import 'widgets/signal_card.dart';
import 'widgets/engine_log_panel.dart';

const _kPresets = [
  (label: 'MAG7', tickers: 'AAPL MSFT NVDA GOOGL META AMZN TSLA'),
  (label: 'MACRO PLAYS', tickers: 'TLT GLD SPY QQQ DXY'),
  (label: 'OPTIONS HEAVY', tickers: 'SPY QQQ TSLA NVDA AMD'),
  (label: 'SMALL ACCOUNT', tickers: 'SOXL TQQQ UVXY'),
];

class SignalEngineScreen extends ConsumerStatefulWidget {
  const SignalEngineScreen({super.key});

  @override
  ConsumerState<SignalEngineScreen> createState() => _SignalEngineScreenState();
}

class _SignalEngineScreenState extends ConsumerState<SignalEngineScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _generate() {
    final tickers = _controller.text
        .trim()
        .split(RegExp(r'[\s,]+'))
        .map((t) => t.trim().toUpperCase())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tickers.isEmpty) return;
    ref.read(signalEngineProvider.notifier).generateSignals(tickers);
    // Switch to signals tab
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signalEngineProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RISKFORM // SIGNAL ENGINE',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFF333333),
                letterSpacing: 2,
              ),
            ),
            Row(
              children: [
                const Text(
                  'SIGNAL ENGINE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                _PulseDot(active: state.isLoading),
              ],
            ),
          ],
        ),
        actions: [
          if (state.signals.isNotEmpty)
            TextButton(
              onPressed: () =>
                  ref.read(signalEngineProvider.notifier).clearSignals(),
              child: const Text(
                'CLEAR ALL',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFFF4400),
                  letterSpacing: 0.8,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00FF88),
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: const Color(0xFF00FF88),
          unselectedLabelColor: const Color(0xFF444444),
          labelStyle: const TextStyle(fontSize: 10, letterSpacing: 1.5),
          tabs: [
            Tab(text: 'SIGNALS (${state.signals.length})'),
            const Tab(text: 'ENGINE LOG'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Input panel
          _InputPanel(
            controller: _controller,
            isLoading: state.isLoading,
            onGenerate: _generate,
            onPreset: (t) => setState(() => _controller.text = t),
          ),

          // Tab body
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Signals tab
                _SignalsTab(state: state),
                // Log tab
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: EngineLogPanel(lines: state.logs),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input panel ────────────────────────────────────────────────────────────────

class _InputPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onGenerate;
  final void Function(String) onPreset;

  const _InputPanel({
    required this.controller,
    required this.isLoading,
    required this.onGenerate,
    required this.onPreset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TICKER INPUT — SPACE OR COMMA SEPARATED',
            style: TextStyle(
              fontSize: 9,
              color: Color(0xFF444444),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'AAPL NVDA SPY...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF050505),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(3),
                      borderSide: const BorderSide(color: Color(0xFF222222)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(3),
                      borderSide: const BorderSide(color: Color(0xFF222222)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(3),
                      borderSide: const BorderSide(color: Color(0x6600FF88)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) => !isLoading ? onGenerate() : null,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onGenerate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLoading
                        ? const Color(0xFF0A2A18)
                        : const Color(0xFF00FF88),
                    foregroundColor: isLoading
                        ? const Color(0xFF00FF88)
                        : Colors.black,
                    disabledBackgroundColor: const Color(0xFF0A2A18),
                    disabledForegroundColor: const Color(0xFF00FF88),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                    elevation: 0,
                    side: isLoading
                        ? const BorderSide(color: Color(0x4400FF88))
                        : BorderSide.none,
                  ),
                  child: Text(
                    isLoading ? 'ANALYZING...' : 'GENERATE →',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Presets
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'PRESETS:',
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF333333),
                  letterSpacing: 0.8,
                ),
              ),
              ..._kPresets.map(
                (p) => _PresetChip(
                  label: p.label,
                  onTap: () => onPreset(p.tickers),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});

  @override
  State<_PresetChip> createState() => _PresetChipState();
}

class _PresetChipState extends State<_PresetChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hovered
                  ? const Color(0x4400FF88)
                  : const Color(0xFF222222),
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 9,
              color: _hovered
                  ? const Color(0xFF00FF88)
                  : const Color(0xFF555555),
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Signals tab ────────────────────────────────────────────────────────────────

class _SignalsTab extends StatelessWidget {
  final SignalEngineState state;
  const _SignalsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                border: Border.all(color: const Color(0x2200FF88)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  const Text(
                    '◈  AUTONOMOUS ANALYSIS IN PROGRESS',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF00FF88),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'QUERYING MACRO · TECHNICAL · SENTIMENT LAYERS',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF333333),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  EngineLogPanel(lines: state.logs),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (state.error != null && state.signals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A0500),
            border: Border.all(color: const Color(0x44FF4400)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            'ERROR: ${state.error}',
            style: const TextStyle(fontSize: 11, color: Color(0xFFFF4400)),
          ),
        ),
      );
    }

    if (state.signals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('◈', style: TextStyle(fontSize: 40, color: Color(0xFF222222))),
            SizedBox(height: 12),
            Text(
              'NO SIGNALS GENERATED',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF333333),
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Enter tickers above and run the engine',
              style: TextStyle(fontSize: 10, color: Color(0xFF222222)),
            ),
          ],
        ),
      );
    }

    return Consumer(
      builder: (context, ref, _) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.signals.length,
        itemBuilder: (context, i) => SignalCard(
          signal: state.signals[i],
          onRemove: () =>
              ref.read(signalEngineProvider.notifier).removeSignal(i),
        ),
      ),
    );
  }
}

// ── Pulsing status dot ─────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final bool active;
  const _PulseDot({required this.active});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) {
      return const _Dot(opacity: 1);
    }
    return FadeTransition(opacity: _anim, child: const _Dot(opacity: 1));
  }
}

class _Dot extends StatelessWidget {
  final double opacity;
  const _Dot({required this.opacity});

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: opacity,
    child: Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF00FF88),
        shape: BoxShape.circle,
      ),
    ),
  );
}
