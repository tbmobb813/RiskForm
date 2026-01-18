import 'package:flutter_application_2/models/wheel_cycle.dart';

class SimOption {
  final double strike;
  int dte; // days to expiration
  final bool isPut;
  final bool isShort;

  SimOption({
    required this.strike,
    required this.dte,
    required this.isPut,
    required this.isShort,
  });

  SimOption copy() => SimOption(
        strike: strike,
        dte: dte,
        isPut: isPut,
        isShort: isShort,
      );
}

class WheelSimState {
  double capital;
  int shares;
  double costBasis;
  WheelCycle cycle;

  // Active option legs in the sim
  SimOption? csp;
  SimOption? cc;

  WheelSimState({
    required this.capital,
    required this.shares,
    required this.costBasis,
    required this.cycle,
    this.csp,
    this.cc,
  });

  WheelSimState copy() {
    return WheelSimState(
      capital: capital,
      shares: shares,
      costBasis: costBasis,
      cycle: cycle,
      csp: csp?.copy(),
      cc: cc?.copy(),
    );
  }
}
