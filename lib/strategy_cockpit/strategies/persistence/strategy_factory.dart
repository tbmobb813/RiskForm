import 'persisted_strategy.dart';
import '../long_call_strategy.dart';
import '../debit_spread_strategy.dart';
import '../wheel_strategy_adapter.dart';
import '../../../models/option_contract.dart';

class StrategyFactory {
  static dynamic fromPersisted(PersistedStrategy p) {
    switch (p.type) {
      case 'long_call':
        return LongCallStrategy(OptionContract.fromJson(Map<String, dynamic>.from(p.data['contract'])));
      case 'debit_spread':
        return DebitSpreadStrategy(
          longLeg: OptionContract.fromJson(Map<String, dynamic>.from(p.data['longLeg'])),
          shortLeg: OptionContract.fromJson(Map<String, dynamic>.from(p.data['shortLeg'])),
        );
      case 'wheel':
        return WheelStrategyAdapter(
          id: p.data['id'] as String,
          label: p.data['label'] as String,
          putContract: OptionContract.fromJson(Map<String, dynamic>.from(p.data['putContract'])),
          callContract: p.data['callContract'] == null
              ? null
              : OptionContract.fromJson(Map<String, dynamic>.from(p.data['callContract'])),
          shareQuantity: (p.data['shareQuantity'] as num?)?.toInt() ?? 100,
          putPremiumReceived: (p.data['putPremiumReceived'] as num?)?.toDouble(),
          callPremiumReceived: (p.data['callPremiumReceived'] as num?)?.toDouble(),
        );
      default:
        throw Exception('Unknown strategy type: ${p.type}');
    }
  }
}
