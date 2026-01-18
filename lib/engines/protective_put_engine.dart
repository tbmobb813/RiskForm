import 'strategy_engine_interface.dart';

class ProtectivePutEngine implements StrategyEngineInterface {
  @override
  Future<double> estimateRisk(Map<String, dynamic> inputs) async {
    return 1.0;
  }
}
