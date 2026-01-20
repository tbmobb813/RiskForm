class ParameterRange {
  final double start;
  final double end;
  final double step;

  const ParameterRange({
    required this.start,
    required this.end,
    required this.step,
  });

  List<double> expand() {
    final values = <double>[];
    double v = start;
    // protect against infinite loops when step is 0
    if (step <= 0) return values;
    while (v <= end + 1e-9) {
      values.add(double.parse(v.toStringAsFixed(6)));
      v += step;
    }
    return values;
  }
}
