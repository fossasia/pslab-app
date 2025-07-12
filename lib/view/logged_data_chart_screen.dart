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
    this.xDataColumnIndex = 1,
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

  @override
  Widget build(BuildContext context) {
    final List<FlSpot> spots = [];
    double maxY = 0;
    double maxX = 0;

    for (int i = 1; i < widget.data.length; i++) {
      final row = widget.data[i];
      if (row.length > widget.xDataColumnIndex &&
          row.length > widget.yDataColumnIndex) {
        final x = (row[widget.xDataColumnIndex] as num).toDouble();
        final y = (row[widget.yDataColumnIndex] as num).toDouble();
        spots.add(FlSpot(x, y));
        if (y > maxY) maxY = y;
        if (x > maxX) maxX = x;
      }
    }

    double chartWidth = spots.length * 12.0;
    final screenWidth = MediaQuery.of(context).size.width;
    if (chartWidth < screenWidth) {
      chartWidth = screenWidth;
    }

    return Scaffold(
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
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: chartWidth,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: LineChart(
                    LineChartData(
                      backgroundColor: chartBackgroundColor,
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: Text(widget.xAxisLabel),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _getSafeInterval(maxX, divisions: 10),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: Text(widget.yAxisLabel),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            interval: _getSafeInterval(maxY, divisions: 5),
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawHorizontalLine: true,
                        drawVerticalLine: true,
                        horizontalInterval:
                            _getSafeInterval(maxY, divisions: 5),
                        verticalInterval: _getSafeInterval(maxX, divisions: 10),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: chartBorderColor),
                      ),
                      minY: 0,
                      maxY: maxY > 0 ? maxY * 1.1 : 10,
                      minX: 0,
                      maxX: maxX,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: chartLineColor,
                          barWidth: 2.0,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
