import 'package:equatable/equatable.dart';
import '../utils/parse_date.dart' as pd;
import '../utils/validation.dart';

class TradeInputs extends Equatable {
  final double? strike;
  final double? longStrike;
  final double? shortStrike;

  final double? premiumPaid;
  final double? premiumReceived;
  final double? netDebit;
  final double? netCredit;

  final double? underlyingPrice;
  final double? costBasis;

  final int? sharesOwned;

  final DateTime? expiration;

  const TradeInputs({
    this.strike,
    this.longStrike,
    this.shortStrike,
    this.premiumPaid,
    this.premiumReceived,
    this.netDebit,
    this.netCredit,
    this.underlyingPrice,
    this.costBasis,
    this.sharesOwned,
    this.expiration,
  });

  // Construct from UI controllers
  factory TradeInputs.fromControllers(Map<String, dynamic> c) {
    double? d(String key) {
      final v = c[key]?.text.trim();
      if (v == null || v.isEmpty) return null;
      return double.tryParse(v);
    }

    int? i(String key) {
      final v = c[key]?.text.trim();
      if (v == null || v.isEmpty) return null;
      return int.tryParse(v);
    }

    DateTime? date(String key) {
      final v = c[key]?.text.trim();
      if (v == null || v.isEmpty) return null;
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }

    return TradeInputs(
      strike: d("Strike Price"),
      longStrike: d("Long Strike"),
      shortStrike: d("Short Strike"),
      premiumPaid: d("Premium Paid"),
      premiumReceived: d("Premium Received"),
      netDebit: d("Net Debit"),
      netCredit: d("Net Credit"),
      underlyingPrice: d("Underlying Price"),
      costBasis: d("Cost Basis"),
      sharesOwned: i("Shares Owned"),
      expiration: date("Expiration Date"),
    );
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      "strike": strike,
      "longStrike": longStrike,
      "shortStrike": shortStrike,
      "premiumPaid": premiumPaid,
      "premiumReceived": premiumReceived,
      "netDebit": netDebit,
      "netCredit": netCredit,
      "underlyingPrice": underlyingPrice,
      "costBasis": costBasis,
      "sharesOwned": sharesOwned,
      "expiration": expiration?.toIso8601String(),
    };
  }

  factory TradeInputs.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      return pd.parseDate(v);
    }

    return TradeInputs(
      strike: (json['strike'] as num?)?.toDouble(),
      longStrike: (json['longStrike'] as num?)?.toDouble(),
      shortStrike: (json['shortStrike'] as num?)?.toDouble(),
      premiumPaid: (json['premiumPaid'] as num?)?.toDouble(),
      premiumReceived: (json['premiumReceived'] as num?)?.toDouble(),
      netDebit: (json['netDebit'] as num?)?.toDouble(),
      netCredit: (json['netCredit'] as num?)?.toDouble(),
      underlyingPrice: (json['underlyingPrice'] as num?)?.toDouble(),
      costBasis: (json['costBasis'] as num?)?.toDouble(),
      sharesOwned: (json['sharesOwned'] as num?)?.toInt(),
      expiration: parseDate(json['expiration']),
    );
  }

  // Provide a human-friendly map for UI recap components
  Map<String, Object?> toMap() {
    return {
      'Strike': strike,
      'Long Strike': longStrike,
      'Short Strike': shortStrike,
      'Premium Paid': premiumPaid,
      'Premium Received': premiumReceived,
      'Net Debit': netDebit,
      'Net Credit': netCredit,
      'Underlying Price': underlyingPrice,
      'Cost Basis': costBasis,
      'Shares Owned': sharesOwned,
      'Expiration': expiration?.toIso8601String(),
    };
  }

  /// Validates all fields and returns a ValidationResult.
  /// Use [validateForStrategy] for strategy-specific validation.
  ValidationResult validateBasic() {
    return ValidationBuilder()
        .add(validate('strike', strike).nonNegative().finite())
        .add(validate('longStrike', longStrike).nonNegative().finite())
        .add(validate('shortStrike', shortStrike).nonNegative().finite())
        .add(validate('premiumPaid', premiumPaid).nonNegative().finite())
        .add(validate('premiumReceived', premiumReceived).nonNegative().finite())
        .add(validate('netDebit', netDebit).nonNegative().finite())
        .add(validate('netCredit', netCredit).nonNegative().finite())
        .add(validate('underlyingPrice', underlyingPrice).positive().finite())
        .add(validate('costBasis', costBasis).nonNegative().finite())
        .add(validate('sharesOwned', sharesOwned).nonNegative())
        .build();
  }

  /// Validates inputs for a specific strategy.
  /// Returns a ValidationResult with strategy-specific errors.
  ValidationResult validateForStrategy(String strategyId) {
    final builder = ValidationBuilder();

    // Common validations
    builder.add(validate('underlyingPrice', underlyingPrice).positive().finite());

    switch (strategyId) {
      case 'csp': // Cash-Secured Put
        builder
            .add(validate('strike', strike).required().positive().finite())
            .add(validate('premiumReceived', premiumReceived).required().nonNegative().finite());
        break;

      case 'cc': // Covered Call
        builder
            .add(validate('strike', strike).required().positive().finite())
            .add(validate('premiumReceived', premiumReceived).required().nonNegative().finite())
            .add(validate('costBasis', costBasis).required().positive().finite())
            .add(validate('sharesOwned', sharesOwned).required().positive());
        break;

      case 'credit_spread':
        builder
            .add(validate('shortStrike', shortStrike).required().positive().finite())
            .add(validate('longStrike', longStrike).required().positive().finite())
            .add(validate('netCredit', netCredit).required().nonNegative().finite());
        // Validate spread relationship
        if (shortStrike != null && longStrike != null && shortStrike! <= longStrike!) {
          builder.add(
            validate('shortStrike', shortStrike).custom(
              (_) => false,
              'Short strike must be greater than long strike for credit spreads',
            ),
          );
        }
        break;

      case 'debit_spread':
        builder
            .add(validate('longStrike', longStrike).required().positive().finite())
            .add(validate('shortStrike', shortStrike).required().positive().finite())
            .add(validate('netDebit', netDebit).required().nonNegative().finite());
        break;

      case 'long_call':
      case 'long_put':
        builder
            .add(validate('strike', strike).required().positive().finite())
            .add(validate('premiumPaid', premiumPaid).required().nonNegative().finite());
        break;

      case 'protective_put':
        builder
            .add(validate('strike', strike).required().positive().finite())
            .add(validate('premiumPaid', premiumPaid).required().nonNegative().finite())
            .add(validate('costBasis', costBasis).required().positive().finite());
        break;

      case 'collar':
        builder
            .add(validate('strike', strike).required().positive().finite()) // call strike
            .add(validate('longStrike', longStrike).required().positive().finite()) // put strike
            .add(validate('premiumReceived', premiumReceived).nonNegative().finite())
            .add(validate('premiumPaid', premiumPaid).nonNegative().finite())
            .add(validate('costBasis', costBasis).required().positive().finite());
        break;
    }

    return builder.build();
  }

  /// Throws ValidationException if inputs are invalid for the given strategy.
  void throwIfInvalidForStrategy(String strategyId) {
    validateForStrategy(strategyId).throwIfInvalid();
  }

  @override
  List<Object?> get props => [
        strike,
        longStrike,
        shortStrike,
        premiumPaid,
        premiumReceived,
        netDebit,
        netCredit,
        underlyingPrice,
        costBasis,
        sharesOwned,
        expiration,
      ];
}