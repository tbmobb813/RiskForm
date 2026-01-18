import 'strategy_engine_interface.dart';

class CreditSpreadEngine implements StrategyEngineInterface {
  @override
  Future<double> estimateRisk(Map<String, dynamic> inputs) async {
    return 1.0;
  }
}
