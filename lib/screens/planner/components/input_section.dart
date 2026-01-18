import 'package:flutter/material.dart';
import '../../../models/trade_inputs.dart';
import '../../../models/strategy_field_map.dart';
import '../../../models/input_field_key.dart';
import 'input_field.dart';

class InputSection extends StatefulWidget {
  final String strategyId;
  final ValueChanged<TradeInputs> onInputsChanged;

  const InputSection({
    super.key,
    required this.strategyId,
    required this.onInputsChanged,
  });

  @override
  State<InputSection> createState() => _InputSectionState();
}

class _InputSectionState extends State<InputSection> {
  final Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    final fields = StrategyFieldMap.fieldsFor(widget.strategyId);
    for (final key in fields) {
      controllers[key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fields = StrategyFieldMap.fieldsFor(widget.strategyId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Trade Inputs",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        ...fields.map((key) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InputField(
              label: _labelFor(key),
              controller: controllers[key]!,
              onChanged: (_) => _emitInputs(),
            ),
          );
        }),
      ],
    );
  }

  void _emitInputs() {
    widget.onInputsChanged(
      TradeInputs.fromControllers(controllers),
    );
  }

  String _labelFor(String key) {
    switch (key) {
      case InputFieldKey.strike:
        return "Strike Price";
      case InputFieldKey.longStrike:
        return "Long Strike";
      case InputFieldKey.shortStrike:
        return "Short Strike";
      case InputFieldKey.premiumPaid:
        return "Premium Paid";
      case InputFieldKey.premiumReceived:
        return "Premium Received";
      case InputFieldKey.netDebit:
        return "Net Debit";
      case InputFieldKey.netCredit:
        return "Net Credit";
      case InputFieldKey.underlyingPrice:
        return "Underlying Price";
      case InputFieldKey.costBasis:
        return "Cost Basis";
      case InputFieldKey.sharesOwned:
        return "Shares Owned";
      case InputFieldKey.expiration:
        return "Expiration Date (YYYY-MM-DD)";
      default:
        return key;
    }
  }
}