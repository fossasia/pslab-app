import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/thermometer_state_provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/thermometer_card.dart';
import 'package:fl_chart/fl_chart.dart';

import '../theme/colors.dart';

class ThermometerScreen extends StatefulWidget {
  const ThermometerScreen({super.key});
  @override
  State<StatefulWidget> createState() => _ThermometerScreenState();
}

class _ThermometerScreenState extends State<ThermometerScreen> {
  void _showSensorErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.grey[700],
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _showGuide = false;
  bool _snackbarShown = false;

  void _showInstrumentGuide() {
    setState(() {
      _showGuide = true;
    });
  }

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getThermometerContent() {
    return [
      InstrumentIntroText(
        text: thermometerIntro,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThermometerStateProvider>(
          create: (_) => ThermometerStateProvider()..initializeSensors(),
        ),
      ],
      child: Consumer<ThermometerStateProvider>(
        builder: (context, provider, child) {
          if (!provider.isSensorAvailable() && !_snackbarShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSensorErrorSnackbar(temperatureSensorUnavailableMessage);
              _snackbarShown = true;
            });
          }

          return Stack(
            children: [
              CommonScaffold(
                title: thermometerTitle,
                onGuidePressed: _showInstrumentGuide,
                body: SafeArea(
                  child: Column(
                    children: [
                      const Expanded(
                        flex: 45,
                        child: ThermometerCard(),
                      ),
                      Expanded(
                        flex: 55,
                        child: _buildChartSection(),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showGuide)
                InstrumentOverviewDrawer(
                  instrumentName: thermometerTitle,
                  content: _getThermometerContent(),
                  onHide: _hideInstrumentGuide,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChartSection() {
    return Consumer<ThermometerStateProvider>(
      builder: (context, provider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardMargin = screenWidth < 400 ? 8.0 : 12.0;
        final cardPadding = screenWidth < 400 ? 2.0 : 5.0;
        List<FlSpot> spots = provider.getTemperatureChartData();
        double maxTime = provider.getMaxTime();
        double minTime = provider.getMinTime();
        double timeInterval = provider.getTimeInterval();
        return Container(
          margin: EdgeInsets.fromLTRB(cardMargin, 0, cardMargin, cardMargin),
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: chartBackgroundColor,
            borderRadius: BorderRadius.zero,
          ),
          child:
              _buildChart(screenWidth, maxTime, minTime, timeInterval, spots),
        );
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

  Widget _buildChart(double screenWidth, double maxTime, double minTime,
      double timeInterval, List<FlSpot> spots) {
    final chartFontSize = screenWidth < 400
        ? 8.0
        : screenWidth < 600
            ? 9.0
            : 10.0;
    final axisNameFontSize = screenWidth < 400 ? 9.0 : 10.0;
    final reservedSizeBottom = screenWidth < 400 ? 25.0 : 30.0;
    final reservedSizeLeft = screenWidth < 400 ? 25.0 : 30.0;
    final reservedSizeRight = screenWidth < 400 ? 25.0 : 30.0;
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
                celsius,
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
                      value.toInt().toString(),
                      style: TextStyle(
                        color: chartTextColor,
                        fontSize: chartFontSize,
                      ),
                    ),
                  );
                },
                interval: 5,
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
            horizontalInterval: 10,
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
          maxY: 60,
          maxX: maxTime > 0 ? maxTime : 10,
          minX: minTime,
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
}
