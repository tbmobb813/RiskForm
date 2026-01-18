class Account {
  final double accountSize;
  final double buyingPower;

  const Account({
    required this.accountSize,
    required this.buyingPower,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accountSize: (json["accountSize"] ?? 0).toDouble(),
      buyingPower: (json["buyingPower"] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "accountSize": accountSize,
      "buyingPower": buyingPower,
    };
  }
}
