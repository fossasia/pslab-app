import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pslab/theme/colors.dart';

import '../l10n/app_localizations.dart';
import '../providers/locator.dart';

class LoggedDataChartScreen extends StatefulWidget {
  final List<List<dynamic>> data;
  final String fileName;
  final String xAxisLabel;
  final String yAxisLabel;
  final int xDataColumnIndex;
  final int yDataColumnIndex;

  const LoggedDataChartScreen({
    super.key,
    required this.data,
    required this.fileName,
    this.xAxisLabel = 'Time (s)',
    this.yAxisLabel = 'Value',
    this.xDataColumnIndex = 0,
    this.yDataColumnIndex = 2,
  });

  @override
  State<LoggedDataChartScreen> createState() => _LoggedDataChartScreenState();
}

class _LoggedDataChartScreenState extends State<LoggedDataChartScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  double _getSafeInterval(double maxValue, {int divisions = 5}) {
    if (maxValue <= 0) return 1.0;
    final double interval = (maxValue / divisions).ceilToDouble();
    return interval > 0 ? interval : 1.0;
  }

  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Widget _buildChart(double screenWidth, double maxY, double maxX, double minX,
      double timeInterval, List<FlSpot> spots) {
    final chartFontSize = screenWidth < 400
        ? 8.0
        : screenWidth < 600
            ? 9.0
            : 10.0;
    final axisNameFontSize = screenWidth < 400 ? 9.0 : 10.0;
    final reservedSizeBottom = screenWidth < 400 ? 25.0 : 30.0;
    final reservedSizeLeft = screenWidth < 400 ? 27.0 : 30.0;
    final reservedSizeRight = screenWidth < 400 ? 27.0 : 30.0;

    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: LineChart(
        LineChartData(
          backgroundColor: chartBackgroundColor,
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: EdgeInsets.only(left: screenWidth < 400 ? 15 : 25),
                child: Text(
                  widget.xAxisLabel,
                  style: TextStyle(
                    fontSize: axisNameFontSize,
                    color: blackTextColor,
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
                getTitlesWidget: _sideTitleWidgets,
                interval: timeInterval,
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                widget.yAxisLabel,
                style: TextStyle(
                  fontSize: axisNameFontSize,
                  color: blackTextColor,
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
                        color: blackTextColor,
                        fontSize: chartFontSize,
                      ),
                    ),
                  );
                },
                interval: maxY > 0 ? (maxY / 5).ceilToDouble() : 10,
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: false, reservedSize: reservedSizeRight),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: true,
            horizontalInterval: maxY > 0 ? (maxY / 5).ceilToDouble() : 10,
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
          maxY: maxY > 0 ? (maxY * 1.1) : 100,
          maxX: maxX > 0 ? maxX : 10,
          minX: minX,
          clipData: const FlClipData.all(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: chartLineColor,
              barWidth: screenWidth < 400 ? 1.5 : 2.0,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = [];
    double maxY = 0;
    double maxX = 0;
    double minX = 0;
    double? startTime;

    for (int i = 1; i < widget.data.length; i++) {
      final row = widget.data[i];
      if (row.length > widget.xDataColumnIndex &&
          row.length > widget.yDataColumnIndex) {
        final xValue = _parseDouble(row[widget.xDataColumnIndex]);
        final yValue = _parseDouble(row[widget.yDataColumnIndex]);

        if (xValue != null && yValue != null) {
          if (startTime == null) {
            startTime = xValue;
            minX = 0;
          }

          final relativeTime = ((xValue - startTime) / 1000.0);

          spots.add(FlSpot(relativeTime, yValue));
          if (yValue > maxY) maxY = yValue;
          if (relativeTime > maxX) maxX = relativeTime;
        }
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final timeInterval = _getSafeInterval(maxX, divisions: 10);

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.fileName,
          style: TextStyle(color: appBarContentColor, fontSize: 15),
        ),
        backgroundColor: primaryRed,
        iconTheme: IconThemeData(color: appBarContentColor),
      ),
      body: SafeArea(
        child: spots.isEmpty
            ? Center(child: Text(appLocalizations.noValidData))
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: InteractiveViewer(
                  constrained: false,
                  scaleEnabled: false,
                  panEnabled: true,
                  child: SizedBox(
                    width: spots.length * 12.0 < screenWidth
                        ? screenWidth
                        : spots.length * 12.0,
                    height: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        48,
                    child: _buildChart(
                        screenWidth, maxY, maxX, minX, timeInterval, spots),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _sideTitleWidgets(double value, TitleMeta meta) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 400
        ? 7.0
        : screenWidth < 600
            ? 8.0
            : 9.0;
    final style = TextStyle(
      color: blackTextColor,
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
}
