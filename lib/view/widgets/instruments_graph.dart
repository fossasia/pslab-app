import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/colors.dart';

class InstrumentsGraph extends StatelessWidget {
  final List<FlSpot> spots;
  final double minX;
  final double maxX;
  final double timeInterval;
  final double minY;
  final double maxY;
  final double yInterval;
  final String yAxisLabel;
  final String xAxisLabel;
  final List<HorizontalLine>? extraLines;
  final Color? lineColor;
  final String? rightAxisLabel;
  final Widget Function(double, TitleMeta)? rightTitlesWidget;

  const InstrumentsGraph({
    super.key,
    required this.spots,
    required this.minX,
    required this.maxX,
    required this.timeInterval,
    required this.minY,
    required this.maxY,
    required this.yInterval,
    required this.yAxisLabel,
    required this.xAxisLabel,
    this.extraLines,
    this.lineColor,
    this.rightAxisLabel,
    this.rightTitlesWidget,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardMargin = screenWidth < 400 ? 4.0 : 8.0;
    final cardPadding = screenWidth < 400 ? 8.0 : 10.0;

    return Container(
      margin: EdgeInsets.fromLTRB(cardMargin, 0, cardMargin, cardMargin),
      padding: EdgeInsets.fromLTRB(2.0, cardPadding, cardPadding, cardPadding),
      decoration: BoxDecoration(
        color: chartBackgroundColor,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildChart(screenWidth),
    );
  }

  Widget _sideTitleWidgets(double value, TitleMeta meta, double labelFontSize) {
    final style = TextStyle(
      color: chartTextColor,
      fontSize: labelFontSize,
      fontWeight: FontWeight.bold,
    );

    String timeText;
    if (value < 60) {
      timeText = '${value.toInt()}s';
    } else if (value < 3600) {
      int minutes = (value / 60).floor();
      int seconds = (value % 60).toInt();
      timeText = seconds == 0 ? '${minutes}m' : '${minutes}m${seconds}s';
    } else {
      int hours = (value / 3600).floor();
      int minutes = ((value % 3600) / 60).floor();
      timeText = minutes == 0 ? '${hours}h' : '${hours}h${minutes}m';
    }

    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text(timeText, maxLines: 1, style: style),
    );
  }

  Widget _buildChart(double screenWidth) {
    final axisNameFontSize = screenWidth < 400 ? 10.0 : 11.0;
    final labelFontSize = screenWidth < 400 ? 8.0 : 9.0;
    final rightReservedSize = rightTitlesWidget != null ? 28.0 : 0.0;
    final rightAxisNameSize = rightAxisLabel != null ? 16.0 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0, top: 4.0, left: 0.0),
      child: LineChart(
        LineChartData(
          backgroundColor: chartBackgroundColor,
          titlesData: FlTitlesData(
            show: true,
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              axisNameSize: rightAxisNameSize,
              axisNameWidget: rightAxisLabel != null
                  ? Text(
                      rightAxisLabel!,
                      style: TextStyle(
                        fontSize: axisNameFontSize,
                        color: chartTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const SizedBox.shrink(),
              sideTitles: SideTitles(
                showTitles: rightTitlesWidget != null,
                reservedSize: rightReservedSize,
                interval: yInterval,
                getTitlesWidget: rightTitlesWidget ??
                    (value, meta) => const SizedBox.shrink(),
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  xAxisLabel,
                  style: TextStyle(
                    fontSize: axisNameFontSize,
                    color: chartTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              axisNameSize: 18,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                interval: timeInterval,
                getTitlesWidget: (value, meta) =>
                    _sideTitleWidgets(value, meta, labelFontSize),
              ),
            ),
            leftTitles: AxisTitles(
              axisNameSize: 16,
              axisNameWidget: Text(
                yAxisLabel,
                style: TextStyle(
                  fontSize: axisNameFontSize,
                  color: chartTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              sideTitles: SideTitles(
                reservedSize: 22,
                showTitles: true,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if (value % yInterval != 0) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    space: 2,
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: chartTextColor,
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: true,
            horizontalInterval: yInterval,
            verticalInterval: timeInterval,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: chartBorderColor, strokeWidth: 1),
            getDrawingVerticalLine: (value) =>
                FlLine(color: chartBorderColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: chartBorderColor, width: 1.5),
              left: BorderSide(color: chartBorderColor, width: 1.5),
              top: BorderSide(color: chartBorderColor, width: 1.5),
              right: BorderSide(color: chartBorderColor, width: 1.5),
            ),
          ),
          minY: minY,
          maxY: maxY,
          maxX: maxX > 0 ? maxX : 10,
          minX: minX,
          clipData: const FlClipData.all(),
          extraLinesData: extraLines != null
              ? ExtraLinesData(horizontalLines: extraLines!)
              : const ExtraLinesData(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: lineColor ?? chartLineColor,
              barWidth: 2.0,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    (lineColor ?? chartLineColor).withValues(alpha: 0.3),
                    (lineColor ?? chartLineColor).withValues(alpha: 0.0)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
