import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/planner_notifier.dart';
import '../../../state/planner_state.dart';

/// Displays a RangeSlider that highlights the recommended range for a given
/// planner field (e.g. 'delta', 'dte', 'width'). This widget reads the
/// `plannerNotifierProvider` to find `hintsBundle.recommendedRanges` and
/// initializes the slider to that range when present.
class RecommendedRangeSlider extends ConsumerStatefulWidget {
  final String field;
  final double min;
  final double max;

  final PlannerState? initialState;

  const RecommendedRangeSlider({super.key, required this.field, required this.min, required this.max, this.initialState});

  @override
  ConsumerState<RecommendedRangeSlider> createState() => _RecommendedRangeSliderState();
}

class _RecommendedRangeSliderState extends ConsumerState<RecommendedRangeSlider> with SingleTickerProviderStateMixin {
  RangeValues? _values;

  late final AnimationController _controller;

  // animation anchors: previous and target values for a smooth transition
  double _prevRecStart = 0, _prevRecEnd = 0, _prevBest = 0, _prevWeakStart = 0, _prevWeakEnd = 0;
  double _targetRecStart = 0, _targetRecEnd = 0, _targetBest = 0, _targetWeakStart = 0, _targetWeakEnd = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    // Controller initialized. Widget observes provider via `ref.watch` in
    // `build` and triggers transitions there; avoid `ref.listen` here because
    // Riverpod requires `ref.listen` to be used during a widget build context
    // in tests (it asserts otherwise).
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // initialize from either the injected initialState or the current provider
    final PlannerState state = widget.initialState ?? ref.read(plannerNotifierProvider);
    _applyBundle(state);
  }

  void _applyBundle(PlannerState state) {
    final bundle = state.hintsBundle;

    // initialize slider values when a recommended range exists
    if (bundle != null && bundle.recommendedRanges.containsKey(widget.field)) {
      final r = bundle.recommendedRanges[widget.field]!;
      setState(() {
        _values = RangeValues(r.start.clamp(widget.min, widget.max), r.end.clamp(widget.min, widget.max));
      });
    } else {
      setState(() {
        _values ??= RangeValues(widget.min, widget.max);
      });
    }

    // Initialize animation anchors from current bundle (or defaults)
    final recommended = bundle?.recommendedRanges[widget.field];
    final best = bundle?.bestPoints[widget.field];
    final weak = bundle?.weakRanges[widget.field];

    // When reacting to provider updates we preserve current animated
    // progress by interpolating from previous anchors using controller.value
    final t = _controller.value;
    double interp(double a, double b, double tt) => a + (b - a) * tt;

    final curRecStart = interp(_prevRecStart, _targetRecStart, t);
    final curRecEnd = interp(_prevRecEnd, _targetRecEnd, t);
    final curBest = interp(_prevBest, _targetBest, t);
    final curWeakStart = interp(_prevWeakStart, _targetWeakStart, t);
    final curWeakEnd = interp(_prevWeakEnd, _targetWeakEnd, t);

    _prevRecStart = curRecStart;
    _prevRecEnd = curRecEnd;
    _prevBest = curBest;
    _prevWeakStart = curWeakStart;
    _prevWeakEnd = curWeakEnd;

    _targetRecStart = recommended?.start ?? widget.min;
    _targetRecEnd = recommended?.end ?? widget.max;
    _targetBest = best ?? widget.min;
    _targetWeakStart = weak?.start ?? widget.min;
    _targetWeakEnd = weak?.end ?? widget.max;

    // kick off transition
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = _values ?? RangeValues(widget.min, widget.max);
    final PlannerState state = widget.initialState ?? ref.watch(plannerNotifierProvider);
    final bundle = state.hintsBundle;
    final recommended = bundle?.recommendedRanges[widget.field];
    final best = bundle?.bestPoints[widget.field];
    final weak = bundle?.weakRanges[widget.field];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recommended ${widget.field.toUpperCase()}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            // Stack the custom overlay painter under the slider so we can draw
            // recommended shaded ranges and dotted best-config markers.
            LayoutBuilder(builder: (context, constraints) {
              // Use the already-watched `bundle` from above so the widget
              // rebuilds when the provider changes.

              return SizedBox(
                height: 56,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Animated overlay driven by a single controller
                    Positioned.fill(
                      child: Builder(builder: (context) {
                        // Compute new target anchors from the bundle (or defaults)
                        final newRecStart = recommended?.start ?? widget.min;
                        final newRecEnd = recommended?.end ?? widget.max;
                        final newBest = best ?? widget.min;
                        final newWeakStart = weak?.start ?? widget.min;
                        final newWeakEnd = weak?.end ?? widget.max;

                        // Prepare a smooth transition if values changed
                        void startTransitionIfNeeded() {
                          if (_targetRecStart != newRecStart || _targetRecEnd != newRecEnd || _targetBest != newBest || _targetWeakStart != newWeakStart || _targetWeakEnd != newWeakEnd) {
                            final t = _controller.value;
                            double interp(double a, double b, double tt) => a + (b - a) * tt;

                            final curRecStart = interp(_prevRecStart, _targetRecStart, t);
                            final curRecEnd = interp(_prevRecEnd, _targetRecEnd, t);
                            final curBest = interp(_prevBest, _targetBest, t);
                            final curWeakStart = interp(_prevWeakStart, _targetWeakStart, t);
                            final curWeakEnd = interp(_prevWeakEnd, _targetWeakEnd, t);

                            _prevRecStart = curRecStart;
                            _prevRecEnd = curRecEnd;
                            _prevBest = curBest;
                            _prevWeakStart = curWeakStart;
                            _prevWeakEnd = curWeakEnd;

                            _targetRecStart = newRecStart;
                            _targetRecEnd = newRecEnd;
                            _targetBest = newBest;
                            _targetWeakStart = newWeakStart;
                            _targetWeakEnd = newWeakEnd;

                            _controller.forward(from: 0.0);
                          }
                        }

                        startTransitionIfNeeded();

                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            final t = Curves.easeOut.transform(_controller.value);
                            double lerp(double a, double b) => a + (b - a) * t;

                            final animRecStart = lerp(_prevRecStart, _targetRecStart);
                            final animRecEnd = lerp(_prevRecEnd, _targetRecEnd);
                            final animBest = lerp(_prevBest, _targetBest);
                            final animWeakStart = lerp(_prevWeakStart, _targetWeakStart);
                            final animWeakEnd = lerp(_prevWeakEnd, _targetWeakEnd);

                            return CustomPaint(
                              painter: _SliderOverlayPainter(
                                min: widget.min,
                                max: widget.max,
                                recommendedStart: animRecStart,
                                recommendedEnd: animRecEnd,
                                bestPoint: animBest,
                                weakStart: animWeakStart,
                                weakEnd: animWeakEnd,
                              ),
                            );
                          },
                        );
                      }),
                    ),

                    // Actual interactive RangeSlider on top
                    Center(
                      child: RangeSlider(
                        values: values,
                        min: widget.min,
                        max: widget.max,
                        divisions: 100,
                        labels: RangeLabels(values.start.toStringAsFixed(2), values.end.toStringAsFixed(2)),
                        onChanged: (rv) {
                          setState(() => _values = rv);
                          final midpoint = (rv.start + rv.end) / 2.0;
                          final notifier = ref.read(plannerNotifierProvider.notifier);
                          if (widget.field == 'delta') {
                            notifier.updateInputsFromSliders(delta: midpoint);
                          } else if (widget.field == 'dte') {
                            notifier.updateInputsFromSliders(dte: midpoint.round());
                          } else if (widget.field == 'width') {
                            notifier.updateInputsFromSliders(width: midpoint);
                          } else {
                            notifier.updateInputsFromSliders();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Text('Recommended range: ${values.start.toStringAsFixed(2)} — ${values.end.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            // Legend for markers
            AnimatedOpacity(
              opacity: bundle == null ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: Row(
                children: [
                  if (weak != null) ...[
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.red.withAlpha((0.24 * 255).round()), borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.red)),),
                    const SizedBox(width: 6),
                    const Text('Weak config', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                  ],
                  if (recommended != null) ...[
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.blue.withAlpha((0.18 * 255).round()), borderRadius: BorderRadius.circular(3), border: Border.all(color: Colors.blue)),),
                    const SizedBox(width: 6),
                    const Text('Recommended', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 12),
                  ],
                  if (best != null) ...[
                    // small dotted-line indicator
                    CustomPaint(size: const Size(12, 12), painter: _DotLegendPainter(color: Colors.blue)),
                    const SizedBox(width: 6),
                    const Text('Best backtest', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotLegendPainter extends CustomPainter {
  final Color color;
  _DotLegendPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final top = 2.0;
    final bottom = size.height - 2.0;
    const dash = 2.0;
    const gap = 2.0;
    double y = top;
    while (y < bottom) {
      final y2 = (y + dash).clamp(top, bottom);
      canvas.drawLine(Offset(centerX, y), Offset(centerX, y2), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DotLegendPainter oldDelegate) => oldDelegate.color != color;
}

class _SliderOverlayPainter extends CustomPainter {
  final double min;
  final double max;
  // Animated numeric values (preferred)
  final double? recommendedStart;
  final double? recommendedEnd;
  final double? bestPoint;
  final double? weakStart;
  final double? weakEnd;
  // Backwards compat: (legacy RangeValues fields removed — animation uses numeric anchors)

  _SliderOverlayPainter({
    required this.min,
    required this.max,
    this.recommendedStart,
    this.recommendedEnd,
    this.bestPoint,
    this.weakStart,
    this.weakEnd,
    // legacy optional fields removed
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Horizontal padding to align roughly with slider thumb padding
    const horizontalPadding = 16.0;
    final trackLeft = horizontalPadding;
    final trackRight = size.width - horizontalPadding;
    final trackWidth = trackRight - trackLeft;

    // Draw weak config zone first (red shaded) using animated values if provided
    if (weakStart != null && weakEnd != null) {
      final sfrac = ((weakStart! - min) / (max - min)).clamp(0.0, 1.0);
      final efrac = ((weakEnd! - min) / (max - min)).clamp(0.0, 1.0);
      final l = trackLeft + (trackWidth * sfrac);
      final r = trackLeft + (trackWidth * efrac);
      paint.color = Colors.red.withAlpha((0.12 * 255).round());
      final rectW = Rect.fromLTRB(l, size.height * 0.2, r, size.height * 0.8);
      canvas.drawRRect(RRect.fromRectAndRadius(rectW, const Radius.circular(4)), paint);
      _drawDottedLine(canvas, Offset(l, size.height * 0.2), Offset(l, size.height * 0.8), color: Colors.red);
      _drawDottedLine(canvas, Offset(r, size.height * 0.2), Offset(r, size.height * 0.8), color: Colors.red);
    }

    // Draw recommended range in blue
    if (recommendedStart != null && recommendedEnd != null) {
      final startFrac = ((recommendedStart! - min) / (max - min)).clamp(0.0, 1.0);
      final endFrac = ((recommendedEnd! - min) / (max - min)).clamp(0.0, 1.0);
      final left = trackLeft + (trackWidth * startFrac);
      final right = trackLeft + (trackWidth * endFrac);

      paint.color = Colors.blue.withAlpha((0.12 * 255).round());
      final rect = Rect.fromLTRB(left, size.height * 0.25, right, size.height * 0.75);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);

      if ((recommendedEnd! - recommendedStart!).abs() < 1e-6) {
        final markerX = left;
        _drawDottedLine(canvas, Offset(markerX, size.height * 0.15), Offset(markerX, size.height * 0.85), color: Colors.blue);
      }
    }

    // Draw best-config dotted blue marker if present (animated preferred)
    if (bestPoint != null) {
      final bfrac = ((bestPoint! - min) / (max - min)).clamp(0.0, 1.0);
      final bx = trackLeft + (trackWidth * bfrac);
      _drawDottedLine(canvas, Offset(bx, size.height * 0.15), Offset(bx, size.height * 0.85), color: Colors.blue);
    }
  }

  void _drawDottedLine(Canvas canvas, Offset p1, Offset p2, {Color color = Colors.blue}) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double distance = (p2.dy - p1.dy).abs();
    double startY = p1.dy;
    while (distance > 0) {
      final len = dashWidth.clamp(0.0, distance);
      canvas.drawLine(Offset(p1.dx, startY), Offset(p1.dx, startY + len), paint);
      startY += dashWidth + dashSpace;
      distance -= (dashWidth + dashSpace);
    }
  }

  @override
  bool shouldRepaint(covariant _SliderOverlayPainter oldDelegate) {
    return oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.recommendedStart != recommendedStart ||
        oldDelegate.recommendedEnd != recommendedEnd ||
        oldDelegate.bestPoint != bestPoint ||
        oldDelegate.weakStart != weakStart ||
        oldDelegate.weakEnd != weakEnd;
  }
}
