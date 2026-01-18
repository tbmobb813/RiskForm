import 'strategy_engine_interface.dart';

class CspEngine implements StrategyEngineInterface {
  @override
  Future<double> estimateRisk(Map<String, dynamic> inputs) async {
    // placeholder calculation
    return 1.0;
  }
}
