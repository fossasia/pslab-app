import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/barometer_state_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/barometer_card.dart';
import 'package:fl_chart/fl_chart.dart';

class BarometerScreen extends StatefulWidget {
  const BarometerScreen({super.key});
  @override
  State<StatefulWidget> createState() => _BarometerScreenState();
}

class _BarometerScreenState extends State<BarometerScreen> {
  void _showSensorErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: snackBarContentColor),
          ),
          backgroundColor: snackBarBackgroundColor,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BarometerStateProvider>(
          create: (_) => BarometerStateProvider()
            ..initializeSensors(onError: _showSensorErrorSnackbar),
        ),
      ],
      child: CommonScaffold(
        title: barometerTitle,
        body: SafeArea(
          child: Column(
            children: [
              const Expanded(
                flex: 45,
                child: BarometerCard(),
              ),
              Expanded(
                flex: 55,
                child: _buildChartSection(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Consumer<BarometerStateProvider>(
      builder: (context, provider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardMargin = screenWidth < 400 ? 8.0 : 16.0;
        final cardPadding = screenWidth < 400 ? 2.0 : 5.0;
        List<FlSpot> spots = provider.getPressureChartData();
        double maxPressure = provider.getMaxPressure();
        double maxTime = provider.getMaxTime();
        double minTime = provider.getMinTime();
        double timeInterval = provider.getTimeInterval();
        double maxAltitude = provider.getMaxAltitudeForChart();
        double minAltitude = provider.getMinAltitudeForChart();
        double altitudeInterval = provider.getAltitudeInterval();

        return Container(
            margin: EdgeInsets.fromLTRB(cardMargin, 0, cardMargin, cardMargin),
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: chartBackgroundColor,
              borderRadius: BorderRadius.zero,
            ),
            child: _buildChart(
                screenWidth,
                maxPressure,
                maxTime,
                minTime,
                timeInterval,
                spots,
                maxAltitude,
                minAltitude,
                altitudeInterval));
      },
    );
  }

  Widget sideTitleWidgets(double value, TitleMeta meta) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 400
        ? 7.0
        : screenWidth < 600
            ? 8.0
            : 9.0;
    final style = TextStyle(
      color: chartTextColor,
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

  Widget altitudeTitleWidgets(double value, TitleMeta meta) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 400
        ? 7.0
        : screenWidth < 600
            ? 8.0
            : 9.0;
    final style = TextStyle(
      color: chartTextColor,
      fontSize: fontSize,
    );

    const double seaLevelPressureAtm = 1.0;
    const double temperatureK = 288.15;
    const double lapseRate = 0.0065;
    const double gasConstant = 287.05;
    const double gravity = 9.80665;

    double pressureAtm = value;
    double altitude = 0.0;

    if (pressureAtm > 0) {
      altitude = (temperatureK / lapseRate) *
          (1 -
              pow(pressureAtm / seaLevelPressureAtm,
                  (gasConstant * lapseRate) / gravity));
    }

    String altitudeText;
    if (altitude < 1000) {
      altitudeText = '${altitude.round()}';
    } else {
      altitudeText = altitude.toStringAsFixed(0);
    }

    return SideTitleWidget(
      meta: meta,
      child: Text(
        altitudeText,
        style: style,
      ),
    );
  }

  Widget _buildChart(
      double screenWidth,
      double maxPressure,
      double maxTime,
      double minTime,
      double timeInterval,
      List<FlSpot> spots,
      double maxAltitude,
      double minAltitude,
      double altitudeInterval) {
    final chartFontSize = screenWidth < 400
        ? 8.0
        : screenWidth < 600
            ? 9.0
            : 10.0;
    final axisNameFontSize = screenWidth < 400 ? 9.0 : 10.0;
    final reservedSizeBottom = screenWidth < 400 ? 25.0 : 30.0;
    final reservedSizeLeft = screenWidth < 400 ? 29.0 : 32.0;
    final reservedSizeRight = screenWidth < 400 ? 29.0 : 32.0;

    return LineChart(
      LineChartData(
        backgroundColor: chartBackgroundColor,
        titlesData: FlTitlesData(
          show: true,
          topTitles: AxisTitles(
            axisNameWidget: Padding(
              padding: EdgeInsets.only(left: screenWidth < 400 ? 15 : 25),
              child: Text(
                timeAxisLabel,
                style: TextStyle(
                  fontSize: axisNameFontSize,
                  color: chartTextColor,
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
              atm,
              style: TextStyle(
                fontSize: axisNameFontSize,
                color: chartTextColor,
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
                    value.toStringAsFixed(2),
                    style: TextStyle(
                      color: chartTextColor,
                      fontSize: chartFontSize,
                    ),
                  ),
                );
              },
              interval: maxPressure > 0 ? (maxPressure / 5) : 0.2,
            ),
          ),
          rightTitles: AxisTitles(
            axisNameWidget: Text(
              meterUnit,
              style: TextStyle(
                fontSize: axisNameFontSize,
                color: chartTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            sideTitles: SideTitles(
              reservedSize: reservedSizeRight,
              showTitles: true,
              getTitlesWidget: (value, meta) =>
                  altitudeTitleWidgets(value, meta),
              interval: maxPressure > 0 ? (maxPressure / 5) : 0.2,
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: maxPressure > 0 ? (maxPressure / 5) : 0.2,
          verticalInterval: timeInterval,
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: chartBorderColor),
            left: BorderSide(color: chartBorderColor),
            top: BorderSide(color: chartBorderColor),
            right: BorderSide(color: chartBorderColor),
          ),
        ),
        minY: 0,
        maxY: maxPressure > 0 ? (maxPressure * 1.1) : 2.0,
        maxX: maxTime > 0 ? maxTime : 10,
        minX: minTime,
        clipData: const FlClipData.all(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: xOrientationChartLineColor,
            barWidth: screenWidth < 400 ? 1.5 : 2.0,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}
