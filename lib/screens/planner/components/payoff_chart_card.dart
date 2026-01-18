import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/planner/payoff/components/payoff_chart_card.dart' as new_card;
import '../../../models/payoff_result.dart';

class PayoffChartCard extends StatelessWidget {
  final PayoffResult payoff;

  const PayoffChartCard({super.key, required this.payoff});

  @override
  Widget build(BuildContext context) {
    // Delegate to the new PayoffChartCard which reads planner state directly.
    return new_card.PayoffChartCard(payoff: payoff);
  }
}
