import 'input_field_key.dart';

class StrategyFieldMap {
  static List<String> fieldsFor(String strategyId) {
    switch (strategyId) {
      case "csp":
        return [
          InputFieldKey.strike,
          InputFieldKey.premiumReceived,
          InputFieldKey.expiration,
          InputFieldKey.underlyingPrice,
        ];

      case "cc":
        return [
          InputFieldKey.strike,
          InputFieldKey.premiumReceived,
          InputFieldKey.underlyingPrice,
          InputFieldKey.sharesOwned,
          InputFieldKey.costBasis,
        ];

      case "credit_spread":
        return [
          InputFieldKey.shortStrike,
          InputFieldKey.longStrike,
          InputFieldKey.netCredit,
          InputFieldKey.expiration,
          InputFieldKey.underlyingPrice,
        ];

      case "protective_put":
        return [
          InputFieldKey.strike,
          InputFieldKey.premiumPaid,
          InputFieldKey.underlyingPrice,
          InputFieldKey.sharesOwned,
        ];

      case "collar":
        return [
          InputFieldKey.strike, // call strike
          InputFieldKey.premiumReceived, // call premium
          InputFieldKey.longStrike, // put strike
          InputFieldKey.premiumPaid, // put premium
          InputFieldKey.underlyingPrice,
          InputFieldKey.sharesOwned,
          InputFieldKey.costBasis,
        ];

      case "long_call":
      case "long_put":
        return [
          InputFieldKey.strike,
          InputFieldKey.premiumPaid,
          InputFieldKey.expiration,
          InputFieldKey.underlyingPrice,
        ];

      case "debit_spread":
        return [
          InputFieldKey.longStrike,
          InputFieldKey.shortStrike,
          InputFieldKey.netDebit,
          InputFieldKey.expiration,
          InputFieldKey.underlyingPrice,
        ];

      default:
        return [];
    }
  }
}