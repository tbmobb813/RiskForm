import 'package:riskform/models/option_contract.dart';

class SpreadSelection {
  final OptionContract? longLeg;
  final OptionContract? shortLeg;
  final DateTime? expiry;

  const SpreadSelection({
    this.longLeg,
    this.shortLeg,
    this.expiry,
  });

  SpreadSelection copyWith({
    OptionContract? longLeg,
    OptionContract? shortLeg,
    DateTime? expiry,
  }) {
    return SpreadSelection(
      longLeg: longLeg ?? this.longLeg,
      shortLeg: shortLeg ?? this.shortLeg,
      expiry: expiry ?? this.expiry,
    );
  }

  bool get isComplete => longLeg != null && shortLeg != null && expiry != null;
}
