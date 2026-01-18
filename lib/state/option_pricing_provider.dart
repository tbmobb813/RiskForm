import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/engines/option_pricing_engine.dart';

final optionPricingEngineProvider = Provider<OptionPricingEngine>((ref) {
  return OptionPricingEngine(riskFreeRate: 0.02);
});
