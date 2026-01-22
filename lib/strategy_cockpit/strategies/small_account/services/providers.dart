import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cheap_options_scanner.dart';

/// Family provider so callers can supply their own OptionsChainService implementation.
final cheapOptionsScannerProvider = Provider.family<CheapOptionsScanner, OptionsChainService>((ref, svc) {
  return CheapOptionsScanner(svc);
});
