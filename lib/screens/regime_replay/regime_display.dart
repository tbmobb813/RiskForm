import 'package:flutter/material.dart';
import 'package:riskform/app.dart';

import '../../models/analytics/market_regime.dart';

Color regimeColor(MarketRegime regime) {
  switch (regime) {
    case MarketRegime.uptrend:
      return AppColors.profit;
    case MarketRegime.downtrend:
      return AppColors.loss;
    case MarketRegime.sideways:
      return AppColors.textMuted;
  }
}

String regimeLabel(MarketRegime regime) {
  switch (regime) {
    case MarketRegime.uptrend:
      return 'Uptrend';
    case MarketRegime.downtrend:
      return 'Downtrend';
    case MarketRegime.sideways:
      return 'Sideways';
  }
}
