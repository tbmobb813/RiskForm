int deterministicHash(String s) => s.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x7FFFFFFF);

bool shouldEarlyAssign({
  required String symbol,
  required double strike,
  required int dte,
  required bool isPut,
  required double price,
}) {
  const earlyWindow = 7;
  const earlyAssignPct = 5; // percent

  final deepITM = isPut ? price < strike * 0.97 : price > strike * 1.03;
  if (!deepITM || dte > earlyWindow) return false;

  final h = deterministicHash('$symbol-${strike.toStringAsFixed(2)}-$dte');
  return h % 100 < earlyAssignPct;
}

String configSymbolOrUnknown(List<String> notes) => 'unknown';
