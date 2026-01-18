// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import '../risk_summary/risk_summary_screen.dart';

class _RiskClassificationBanner extends StatelessWidget {
  final RiskClassification classification;

  const _RiskClassificationBanner({required this.classification});

  @override
  Widget build(BuildContext context) {
    final data = _dataFor(classification);

    final bg = data.color.withAlpha((0.15 * 255).round());
    final bdr = data.color.withAlpha((0.4 * 255).round());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: data.color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.subtitle,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  _BannerData _dataFor(RiskClassification c) {
    switch (c) {
      case RiskClassification.withinRules:
        return _BannerData(
          title: "Within Rules",
          subtitle: "This trade fits within your defined risk parameters.",
          color: Colors.greenAccent,
        );
      case RiskClassification.borderline:
        return _BannerData(
          title: "Borderline",
          subtitle: "Some aspects of this trade approach your risk limits.",
          color: Colors.amber,
        );
      case RiskClassification.outsideRules:
        return _BannerData(
          title: "Outside Rules",
          subtitle: "This trade exceeds one or more risk thresholds.",
          color: Colors.redAccent,
        );
    }
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final Color color;

  _BannerData({
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
