import 'package:flutter_test/flutter_test.dart';
import 'package:riskform/services/engines/payoff_engine.dart';
import 'package:riskform/models/option_contract.dart';
import 'package:riskform/strategy_cockpit/strategies/leg.dart';

void main() {
  group('PayoffEngine multi-leg', () {
    final engine = PayoffEngine();

    test('Long call + short call (call spread) payoff at points', () {
      final long = OptionContract(id: 'L', strike: 50.0, premium: 2.0, expiry: DateTime.now(), type: 'call');
      final short = OptionContract(id: 'S', strike: 60.0, premium: 1.0, expiry: DateTime.now(), type: 'call');

      // quantities: long +1, short -1
      final contracts = [long, short];
      final quantities = [1, -1];

      // At S=45 -> both OTM -> long = -2*100, short = +1*100 => net -100
      expect(engine.payoffForContractsWithQuantities(contracts: contracts, quantities: quantities, underlyingPrice: 45.0), -1.0 * PayoffEngine.contractSize);

      // At S=55 -> long intrinsic 5 -> (5 - 2)=3*100; short receives premium 1*100 => net 400
      expect(engine.payoffForContractsWithQuantities(contracts: contracts, quantities: quantities, underlyingPrice: 55.0), 4.0 * PayoffEngine.contractSize);

      // At S=65 -> net should be 900
      expect(engine.payoffForContractsWithQuantities(contracts: contracts, quantities: quantities, underlyingPrice: 65.0), 9.0 * PayoffEngine.contractSize);
    });

    test('Short put + shares (synthetic covered put) at price', () {
      final put = OptionContract(id: 'P', strike: 50.0, premium: 2.0, expiry: DateTime.now(), type: 'put');
      final shareLeg = Leg.shares(id: 'SHARES', shares: 100, costBasisPerShare: 55.0);

      final contracts = [put, shareLeg.contract];
      final quantities = [-1, shareLeg.quantity]; // short 1 put, long 100 shares

      // Compute expected using contractSize for option and raw per-share for shares:
      // short put: (2 - 10) * 100 = -800
      // shares: 100 * (40 - 55) = -1500
      // total = -2300
      expect(engine.payoffForContractsWithQuantities(contracts: contracts, quantities: quantities, underlyingPrice: 40.0), -2300.0);
    });
  });
}
