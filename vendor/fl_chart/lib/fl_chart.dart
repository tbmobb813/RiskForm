library;

import 'package:flutter/widgets.dart';

class FlSpot {
  final double x;
  final double y;
  FlSpot(this.x, this.y);
}

class FlGridData {
  final bool show;
  FlGridData({this.show = true});
}

class FlTitlesData {
  final bool show;
  FlTitlesData({this.show = true});
}

class FlBorderData {
  final bool show;
  FlBorderData({this.show = true});
}

class LineTouchTooltipData {
  final Color? tooltipBgColor;
  final double? tooltipRoundedRadius;
  final List<LineTooltipItem> Function(List<LineBarSpot>)? getTooltipItems;
  LineTouchTooltipData({this.tooltipBgColor, this.tooltipRoundedRadius, this.getTooltipItems});
}

class LineTooltipItem {
  final String text;
  final TextStyle style;
  LineTooltipItem(this.text, this.style);
}

class LineBarSpot {
  final FlSpot spot;
  LineBarSpot(this.spot);
  double get x => spot.x;
  double get y => spot.y;
}

class LineTouchData {
  final bool enabled;
  final bool handleBuiltInTouches;
  final LineTouchTooltipData? touchTooltipData;
  LineTouchData({this.enabled = false, this.handleBuiltInTouches = false, this.touchTooltipData});
}

class FlDotData {
  final bool show;
  FlDotData({this.show = true});
}

class BarAreaData {
  final bool show;
  final Color? color;
  BarAreaData({this.show = false, this.color});
}

class LineChartBarData {
  final List<FlSpot>? spots;
  final bool isCurved;
  final Color? color;
  final double? barWidth;
  final FlDotData? dotData;
  final BarAreaData? belowBarData;
  LineChartBarData({this.spots, this.isCurved = false, this.color, this.barWidth, this.dotData, this.belowBarData});
}

class LineChartData {
  final FlGridData? gridData;
  final FlTitlesData? titlesData;
  final FlBorderData? borderData;
  final LineTouchData? lineTouchData;
  final List<LineChartBarData>? lineBarsData;
  final double? minY;
  final double? maxY;
  LineChartData({this.gridData, this.titlesData, this.borderData, this.lineTouchData, this.lineBarsData, this.minY, this.maxY});
}

class LineChart extends StatelessWidget {
  final LineChartData data;
  const LineChart(this.data, {super.key});

  @override
  Widget build(BuildContext context) => SizedBox.shrink();
}
