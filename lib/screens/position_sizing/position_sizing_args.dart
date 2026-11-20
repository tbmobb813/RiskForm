/// Values another screen can hand to the position sizing screen. Anything left
/// null falls back to the saved account or stays blank.
class PositionSizingArgs {
  final double? buyingPower;
  final double? strike;

  /// Premium per share.
  final double? premium;

  const PositionSizingArgs({this.buyingPower, this.strike, this.premium});
}
