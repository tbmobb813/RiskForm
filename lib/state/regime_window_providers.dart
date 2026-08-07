import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/historical/regime_window_catalog.dart';
import 'historical_providers.dart';

final regimeWindowCatalogProvider = Provider<RegimeWindowCatalog>((ref) {
  return RegimeWindowCatalog(
    repository: ref.read(historicalRepositoryProvider),
  );
});

/// Historical regime windows for [symbol] over the trailing 5 years.
final regimeCatalogProvider = FutureProvider.family<RegimeCatalog, String>((
  ref,
  symbol,
) {
  final now = DateTime.now();
  return ref
      .read(regimeWindowCatalogProvider)
      .build(
        symbol: symbol,
        start: now.subtract(const Duration(days: 365 * 5)),
        end: now,
      );
});
