import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:pslab/theme/colors.dart';

class WaveGeneratorGraph extends StatefulWidget {
  const WaveGeneratorGraph({super.key});
  @override
  State<StatefulWidget> createState() => _WaveGeneratorGraphState();
}

class _WaveGeneratorGraphState extends State<WaveGeneratorGraph> {
  Widget topTitleWidgets(double value, TitleMeta meta) {
    final style = TextStyle(
      color: chartTextColor,
      fontSize: 9,
    );
    return SideTitleWidget(
      meta: meta,
      child: Text(
        maxLines: 1,
        meta.formattedValue,
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: LineChart(
        LineChartData(
          backgroundColor: chartBackgroundColor,
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                interval: 1000.0,
                reservedSize: 20,
                showTitles: true,
                getTitlesWidget: topTitleWidgets,
              ),
            ),
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 1.0,
            drawHorizontalLine: true,
            drawVerticalLine: true,
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(
                color: chartBorderColor,
              ),
              left: BorderSide(
                color: chartBorderColor,
              ),
              top: BorderSide(
                color: chartBorderColor,
              ),
              right: BorderSide(
                color: chartBorderColor,
              ),
            ),
          ),
          clipData: const FlClipData.all(),
          maxY: 5.0,
          minY: -5.0,
          maxX: 5000.0,
          minX: 0.0,
        ),
      ),
    );
  }
}
