import '../../models/option_contract.dart';

/// A single leg of a strategy.
///
/// Conventions:
/// - For option legs (`type == 'call'` or `'put'`) `quantity` is the number
///   of option contracts (positive for long, negative for short). Each option
///   contract represents `PayoffEngine.contractSize` shares when converted to
///   dollar values.
/// - For share legs (`type == 'share'`) `quantity` is the number of shares
///   (positive for long, negative for short). In this case the contract's
///   `premium` field is used as the per-share cost basis when computing P&L.
///
/// Use the provided factories for clarity: `Leg.option(...)` and
/// `Leg.shares(...)`.
class Leg {
  final OptionContract contract;
  final int quantity;

  Leg({required this.contract, required this.quantity});

  /// Create an option leg where [quantity] is number of contracts.
  /// Example: `Leg.option(contract, quantity: 1)` means long 1 contract.
  factory Leg.option(OptionContract contract, {int quantity = 1}) {
    return Leg(contract: contract, quantity: quantity);
  }

  /// Create a share leg. [shares] is number of shares (not contracts).
  /// The returned leg contains a lightweight `OptionContract` with `type`
  /// set to `'share'` and `premium` used for per-share cost basis.
  factory Leg.shares({required String id, required int shares, required double costBasisPerShare}) {
    final c = OptionContract(
      id: id,
      strike: 0.0,
      premium: costBasisPerShare,
      expiry: DateTime.fromMillisecondsSinceEpoch(0),
      type: 'share',
    );
    return Leg(contract: c, quantity: shares);
  }
}
