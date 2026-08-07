import 'package:flutter/material.dart';

import '../../models/analytics/market_regime.dart';

Color regimeColor(MarketRegime regime) {
  switch (regime) {
    case MarketRegime.uptrend:
      return Colors.green;
    case MarketRegime.downtrend:
      return Colors.red;
    case MarketRegime.sideways:
      return Colors.grey;
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
