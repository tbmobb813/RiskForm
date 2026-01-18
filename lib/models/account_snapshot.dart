class AccountSnapshot {
  final double accountSize;
  final double buyingPower;
  final Map<String, int> sharesOwned;
  final double totalRiskExposurePercent;
  final String wheelState; // "cash", "short_put", "shares_owned", "covered_call"

  AccountSnapshot({
    required this.accountSize,
    required this.buyingPower,
    required this.sharesOwned,
    required this.totalRiskExposurePercent,
    required this.wheelState,
  });

  String get accountSizeString => "\$${accountSize.toStringAsFixed(2)}";
  String get buyingPowerString => "\$${buyingPower.toStringAsFixed(2)}";

  String get wheelStateLabel {
    switch (wheelState) {
      case "cash":
        return "Cash";
      case "short_put":
        return "Short Put Active";
      case "shares_owned":
        return "Shares Owned";
      case "covered_call":
        return "Covered Call Active";
      default:
        return wheelState;
    }
  }
}