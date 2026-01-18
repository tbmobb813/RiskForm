import 'package:flutter/material.dart';
import '../../../models/trade_inputs.dart';

class InputsRecap extends StatelessWidget {
  final TradeInputs? inputs;

  const InputsRecap({super.key, required this.inputs});

  @override
  Widget build(BuildContext context) {
    if (inputs == null) return const SizedBox.shrink();

    return ExpansionTile(
      title: const Text("Trade Inputs"),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: inputs!.toMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(entry.value.toString()),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}