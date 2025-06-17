import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/soundmeter_state_provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/soundmeter_card.dart';
import 'package:fl_chart/fl_chart.dart';

class SoundMeterScreen extends StatefulWidget {
  const SoundMeterScreen({super.key});
  @override
  State<StatefulWidget> createState() => _SoundMeterScreenState();
}

class _SoundMeterScreenState extends State<SoundMeterScreen> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SoundMeterStateProvider>(
          create: (_) => SoundMeterStateProvider()..initializeSensors(),
        ),
      ],
      child: CommonScaffold(
        title: soundMeterTitle,
        body: SafeArea(
          child: Column(
            children: [
              const Expanded(
                flex: 45,
                child: SoundMeterCard(),
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
    return Consumer<SoundMeterStateProvider>(
      builder: (context, provider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardMargin = screenWidth < 400 ? 8.0 : 12.0;
        final cardPadding = screenWidth < 400 ? 2.0 : 5.0;
        List<FlSpot> spots = provider.getDbChartData();
        double maxTime = provider.getMaxTime();
        double minTime = provider.getMinTime();
        double timeInterval = provider.getTimeInterval();

        return Container(
          margin: EdgeInsets.fromLTRB(cardMargin, 0, cardMargin, cardMargin),
          padding: EdgeInsets.all(cardPadding),
          decoration: const BoxDecoration(
            color: Colors.black,
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
                db,
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
                interval: 10,
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
            horizontalInterval: 30,
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
          maxY: 200,
          maxX: maxTime > 0 ? maxTime : 10,
          minX: minTime,
          clipData: const FlClipData.all(),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 100,
                color: Colors.red,
                strokeWidth: 1,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 5, bottom: 5),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                  labelResolver: (line) => '"Dangerous"',
                ),
              ),
            ],
          ),
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
      ),
    );
  }
}
