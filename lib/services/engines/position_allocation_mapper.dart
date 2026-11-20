import '../../models/position.dart';
import 'capital_allocation_engine.dart';

class AllocationImport {
  final List<AllocationHolding> holdings;

  /// Open positions that could not be converted (missing strike, contracts or
  /// premium, or plain shares).
  final int skipped;

  const AllocationImport({required this.holdings, required this.skipped});
}

/// Converts saved positions into allocation holdings. Closed positions and
/// positions without enough data are skipped and counted.
AllocationImport holdingsFromPositions(List<Position> positions) {
  final holdings = <AllocationHolding>[];
  var skipped = 0;

  for (final p in positions.where((p) => p.isOpen)) {
    final capital = p.capitalLocked;
    final premium = p.totalPremium;
    if (capital == null || premium == null) {
      skipped++;
      continue;
    }

    final dte = p.dte;
    final opened = p.openedAt;
    final originalDays = opened == null
        ? dte
        : p.expiration.difference(opened).inDays.clamp(0, 999);

    holdings.add(
      AllocationHolding(
        symbol: p.symbol,
        strategy: switch (p.type) {
          PositionType.csp => HoldingStrategy.csp,
          PositionType.coveredCall => HoldingStrategy.coveredCall,
          PositionType.shares => HoldingStrategy.other,
        },
        capital: capital,
        premium: premium,
        originalDays: originalDays,
        dte: dte,
      ),
    );
  }

  return AllocationImport(holdings: holdings, skipped: skipped);
}
