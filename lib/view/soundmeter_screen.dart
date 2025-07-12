import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/soundmeter_state_provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/soundmeter_card.dart';
import 'package:fl_chart/fl_chart.dart';

import '../theme/colors.dart';

class SoundMeterScreen extends StatefulWidget {
  const SoundMeterScreen({super.key});
  @override
  State<StatefulWidget> createState() => _SoundMeterScreenState();
}

class _SoundMeterScreenState extends State<SoundMeterScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  bool _showGuide = false;
  static const imagePath = 'assets/images/bh1750_schematic.png';
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

  List<Widget> _getSoundMeterContent() {
    return [
      InstrumentIntroText(
        text: appLocalizations.soundMeterIntro,
      ),
      const InstrumentImage(
        imagePath: imagePath,
      ),
      InstrumentIntroText(
        text: appLocalizations.soundMeterDesc,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SoundMeterStateProvider>(
          create: (_) => SoundMeterStateProvider()..initializeSensors(),
        ),
      ],
      child: Stack(
        children: [
          CommonScaffold(
            title: appLocalizations.soundMeterTitle,
            onGuidePressed: _showInstrumentGuide,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isLargeScreen = constraints.maxWidth > 900;

                  if (isLargeScreen) {
                    return Row(
                      children: [
                        const Expanded(
                          flex: 35,
                          child: SoundMeterCard(),
                        ),
                        Expanded(
                          flex: 65,
                          child: _buildChartSection(),
                        ),
                      ],
                    );
                  } else {
                    return Column(
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
                    );
                  }
                },
              ),
            ),
          ),
          if (_showGuide)
            InstrumentOverviewDrawer(
              instrumentName: appLocalizations.soundMeterTitle,
              content: _getSoundMeterContent(),
              onHide: _hideInstrumentGuide,
            ),
        ],
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
                  appLocalizations.timeAxisLabel,
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
                appLocalizations.db,
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
            border: Border(
              bottom: BorderSide(color: chartBorderColor),
              left: BorderSide(color: chartBorderColor),
              top: BorderSide(color: chartBorderColor),
              right: BorderSide(color: chartBorderColor),
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
                color: soundMeterSafeLimitColor,
                strokeWidth: 1,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 5, bottom: 5),
                  style: TextStyle(
                    color: soundMeterSafeLimitColor,
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
