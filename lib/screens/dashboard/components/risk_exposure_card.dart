import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/risk_exposure_provider.dart';
import '../../../models/risk_exposure.dart';

class RiskExposureCard extends ConsumerWidget {
  const RiskExposureCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exposure = ref.watch(riskExposureProvider);

    return exposure.when(
      loading: () => const _LoadingCard(),
      error: (_, __) => const _ErrorCard(),
      data: (risk) => _RiskCard(risk: risk),
    );
  }
}

class _RiskCard extends StatelessWidget {
  final RiskExposure risk;

  const _RiskCard({required this.risk});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Risk Exposure",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text("Total Risk: ${risk.totalRiskPercent.toStringAsFixed(1)}%"),
            Text("Assignment Exposure: ${risk.assignmentExposure ? "Yes" : "No"}"),
            const SizedBox(height: 12),
            if (risk.warnings.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Warnings:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...risk.warnings.map((w) => Text("- $w")),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text("Calculating risk exposure..."),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text("Unable to calculate risk exposure"),
      ),
    );
  }
}
