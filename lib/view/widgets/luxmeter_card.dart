import 'package:pslab/view/widgets/gauge_widget.dart';
import 'package:flutter/material.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/luxmeter_state_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

class LuxMeterCard extends StatefulWidget {
  const LuxMeterCard({super.key});
  @override
  State<StatefulWidget> createState() => _LuxMeterCardState();
}

class _LuxMeterCardState extends State<LuxMeterCard> {
  Widget sideTitleWidgets(double value, TitleMeta meta) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 400
        ? 7.0
        : screenWidth < 600
            ? 8.0
            : 9.0;
    final style = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
    );
    String timeText;
    if (value < 60) {
      timeText = '${value.toInt()}s';
    } else if (value < 3600) {
      int minutes = (value / 60).floor();
      int seconds = (value % 60).toInt();
      timeText = '${minutes}m${seconds}s';
    } else {
      int hours = (value / 3600).floor();
      int minutes = ((value % 3600) / 60).floor();
      timeText = '${hours}h${minutes}m';
    }
    return SideTitleWidget(
      meta: meta,
      child: Text(
        maxLines: 1,
        timeText,
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 900;
    LuxMeterStateProvider provider =
        Provider.of<LuxMeterStateProvider>(context);
    List<FlSpot> spots = provider.getLuxChartData();
    double currentLux = provider.getCurrentLux();
    double minLux = provider.getMinLux();
    double maxLux = provider.getMaxLux();
    double avgLux = provider.getAverageLux();
    double maxTime = provider.getMaxTime();
    double minTime = provider.getMinTime();
    double timeInterval = provider.getTimeInterval();
    final cardMargin = screenWidth < 400 ? 8.0 : 16.0;
    final cardPadding = screenWidth < 400 ? 12.0 : 20.0;
    final gaugeSize = isLargeScreen ? 240.0 : screenWidth * 0.45;
    final titleFontSize = isLargeScreen ? 25.0 : 20.0;
    final statFontSize = isLargeScreen ? 20.0 : 15.0;
    final luxValueFontSize = isLargeScreen ? 20.0 : 16.0;
    return Card(
      margin: EdgeInsets.all(cardMargin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              flex: screenHeight < 600 ? 50 : 45,
              child: Container(
                padding: EdgeInsets.all(cardPadding),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (screenWidth < 350) {
                      return Column(
                        children: [
                          Expanded(
                            child: _buildStatsSection(titleFontSize,
                                statFontSize, maxLux, minLux, avgLux),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: GaugeWidget(
                                gaugeSize: gaugeSize,
                                currentValue: currentLux,
                                currentValueFontSize: luxValueFontSize),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          flex: screenWidth < 500 ? 40 : 35,
                          child: _buildStatsSection(titleFontSize, statFontSize,
                              maxLux, minLux, avgLux),
                        ),
                        Expanded(
                          flex: screenWidth < 500 ? 60 : 65,
                          child: GaugeWidget(
                              gaugeSize: gaugeSize,
                              currentValue: currentLux,
                              currentValueFontSize: luxValueFontSize),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: screenHeight < 600 ? 50 : 55,
              child: Container(
                margin:
                    EdgeInsets.fromLTRB(cardMargin, 0, cardMargin, cardMargin),
                padding: EdgeInsets.all(cardMargin),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildChart(
                    screenWidth, maxLux, maxTime, minTime, timeInterval, spots),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(double titleFontSize, double statFontSize,
      double maxLux, double minLux, double avgLux) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Text(
            builtIn,
            style: TextStyle(
              color: Colors.black,
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Max (Lx)', maxLux, statFontSize),
                _buildStatItem('Min (Lx)', minLux, statFontSize),
                _buildStatItem('Avg (Lx)', avgLux, statFontSize),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart(double screenWidth, double maxLux, double maxTime,
      double minTime, double timeInterval, List<FlSpot> spots) {
    final chartFontSize = screenWidth < 400
        ? 8.0
        : screenWidth < 600
            ? 9.0
            : 10.0;
    final axisNameFontSize = screenWidth < 400 ? 9.0 : 10.0;
    final reservedSizeBottom = screenWidth < 400 ? 25.0 : 30.0;
    final reservedSizeLeft = screenWidth < 400 ? 20.0 : 25.0;
    return LineChart(
      LineChartData(
        backgroundColor: Colors.black,
        titlesData: FlTitlesData(
          show: true,
          topTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: EdgeInsets.only(left: screenWidth < 400 ? 15 : 25),
              child: Text(
                timeAxisLabel,
                style: TextStyle(
                  fontSize: axisNameFontSize,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            axisNameSize: screenWidth < 400 ? 18 : 20,
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: reservedSizeBottom,
              getTitlesWidget: sideTitleWidgets,
              interval: timeInterval,
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              lx,
              style: TextStyle(
                fontSize: axisNameFontSize,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            sideTitles: SideTitles(
              reservedSize: reservedSizeLeft,
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: chartFontSize,
                    ),
                  ),
                );
              },
              interval: maxLux > 0 ? (maxLux / 5).ceilToDouble() : 10,
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: maxLux > 0 ? (maxLux / 5).ceilToDouble() : 10,
          verticalInterval: timeInterval,
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Colors.white38),
            left: BorderSide(color: Colors.white38),
            top: BorderSide(color: Colors.white38),
            right: BorderSide(color: Colors.white38),
          ),
        ),
        minY: 0,
        maxY: maxLux > 0 ? (maxLux * 1.1) : 100,
        maxX: maxTime > 0 ? maxTime : 10,
        minX: minTime,
        clipData: const FlClipData.all(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.cyan,
            barWidth: screenWidth < 400 ? 1.5 : 2.0,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, double value, double fontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final valueFontSize = screenWidth < 400 ? 14.0 : 16.0;
    final padding = screenWidth < 400 ? 15.0 : 20.0;
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pink.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
