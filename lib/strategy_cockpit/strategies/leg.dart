import '../../models/option_contract.dart';

class Leg {
  final OptionContract contract;
  final int quantity; // +1 long, -1 short

  Leg({required this.contract, required this.quantity});
}
