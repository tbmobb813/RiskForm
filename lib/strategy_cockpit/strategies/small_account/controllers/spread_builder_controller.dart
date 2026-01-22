import 'package:flutter_riverpod/legacy.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/models/spread_selection.dart';
import 'package:riskform/strategy_cockpit/strategies/small_account/services/spread_builder_service.dart';
import 'package:riskform/strategy_cockpit/strategies/debit_spread_strategy.dart';

class SpreadBuilderController extends StateNotifier<SpreadSelection> {
  SpreadBuilderController() : super(const SpreadSelection());

  void setExpiry(DateTime expiry) {
    state = state.copyWith(expiry: expiry);
  }

  void setLongLeg(dynamic contract) {
    state = state.copyWith(longLeg: contract as dynamic);
  }

  void setShortLeg(dynamic contract) {
    state = state.copyWith(shortLeg: contract as dynamic);
  }

  DebitSpreadStrategy? buildStrategy() {
    final service = SpreadBuilderService();
    return service.build(state);
  }
}

final spreadBuilderControllerProvider = StateNotifierProvider<SpreadBuilderController, SpreadSelection>((ref) {
  return SpreadBuilderController();
});
