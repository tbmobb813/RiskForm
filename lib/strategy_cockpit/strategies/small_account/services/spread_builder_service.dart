import 'package:riskform/models/option_contract.dart';
import 'package:riskform/strategy_cockpit/strategies/debit_spread_strategy.dart';
import '../models/spread_selection.dart';

class SpreadBuilderService {
  DebitSpreadStrategy? build(SpreadSelection selection) {
    if (!selection.isComplete) return null;

    final longLeg = selection.longLeg!;
    final shortLeg = selection.shortLeg!;

    // Validation: short strike must be higher than long for a call debit spread
    if (shortLeg.strike <= longLeg.strike) {
      throw Exception('Short strike must be higher than long strike for a call debit spread.');
    }

    return DebitSpreadStrategy(longLeg: longLeg, shortLeg: shortLeg);
  }
}
