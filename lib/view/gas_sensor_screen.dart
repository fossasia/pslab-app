import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/gas_sensor_state_provider.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:fl_chart/fl_chart.dart';

import 'widgets/gas_sensor_card.dart';
import '../l10n/app_localizations.dart';
import '../providers/locator.dart';
import '../theme/colors.dart';

class GasSensorScreen extends StatefulWidget {
  const GasSensorScreen({super.key});
  @override
  State<StatefulWidget> createState() => _GasSensorScreenState();
}

class _GasSensorScreenState extends State<GasSensorScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  GasSensorStateProvider? _gasProvider;
  bool _showGuide = false;
  bool _snackbarShown = false;

  static const imagePath = 'assets/images/mq_135_gas_sensor.png';

  @override
  void initState() {
    super.initState();
    _gasProvider = GasSensorStateProvider();
    _gasProvider!.initializeSensors();
  }

  @override
  void dispose() {
    _gasProvider?.dispose();
    super.dispose();
  }

  void _showSensorErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: snackBarContentColor)),
          backgroundColor: snackBarBackgroundColor,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

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

  List<Widget> _getGasSensorContent() {
    return [
      InstrumentIntroText(
        text: appLocalizations.gasSensorGuideIntro,
      ),
      const SizedBox(height: 8),
      InstrumentIntroText(
        text: appLocalizations.gasSensorGuideDetail,
      ),
      const SizedBox(height: 16),
      Text(
        appLocalizations.gasSensorGuideConnectLabel,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 8),
      InstrumentIntroText(
        text: appLocalizations.gasSensorGuideConnectStep1,
      ),
      InstrumentIntroText(
        text: appLocalizations.gasSensorGuideConnectStep2,
      ),
      InstrumentIntroText(
        text: appLocalizations.gasSensorGuideConnectStep3,
      ),
      const SizedBox(height: 16),
      const InstrumentImage(
        imagePath: imagePath,
      ),
      const SizedBox(height: 16),
      InstrumentIntroText(
        text: appLocalizations.gasSensorGuideWarning,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GasSensorStateProvider>.value(
      value: _gasProvider!,
      child: Consumer<GasSensorStateProvider>(
        builder: (context, provider, child) {
          if (!provider.isSensorAvailable() &&
              !_snackbarShown &&
              provider.isInitialized()) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSensorErrorSnackbar(appLocalizations.noGasSensor);
              _snackbarShown = true;
            });
          }

          return Stack(
            children: [
              CommonScaffold(
                title: appLocalizations.gasSensor,
                onGuidePressed: _showInstrumentGuide,
                body: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isLargeScreen = constraints.maxWidth > 900;
                      return isLargeScreen
                          ? Row(
                              children: [
                                const Expanded(
                                    flex: 35, child: GasSensorCard()),
                                Expanded(flex: 65, child: _buildChartSection()),
                              ],
                            )
                          : Column(
                              children: [
                                const Expanded(
                                    flex: 55, child: GasSensorCard()),
                                Expanded(flex: 45, child: _buildChartSection()),
                              ],
                            );
                    },
                  ),
                ),
              ),
              if (_showGuide)
                InstrumentOverviewDrawer(
                  instrumentName: appLocalizations.gasSensor,
                  content: _getGasSensorContent(),
                  onHide: _hideInstrumentGuide,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChartSection() {
    return Consumer<GasSensorStateProvider>(
      builder: (context, provider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardMargin = screenWidth < 400 ? 8.0 : 12.0;
        final cardPadding = screenWidth < 400 ? 12.0 : 16.0;

        List<FlSpot> spots = provider.getGasChartData();

        return Container(
          margin: EdgeInsets.fromLTRB(cardMargin, 0, cardMargin, cardMargin),
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: chartBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildChart(screenWidth, provider.getMaxTime(),
              provider.getMinTime(), provider.getTimeInterval(), spots),
        );
      },
    );
  }

  Widget sideTitleWidgets(double value, TitleMeta meta) {
    final style = TextStyle(
        color: chartTextColor, fontSize: 10, fontWeight: FontWeight.bold);
    String timeText =
        value < 60 ? '${value.toInt()}s' : '${(value / 60).floor()}m';
    return SideTitleWidget(
        meta: meta, space: 6, child: Text(timeText, maxLines: 1, style: style));
  }

  Widget _buildChart(double screenWidth, double maxTime, double minTime,
      double timeInterval, List<FlSpot> spots) {
    final axisNameFontSize = screenWidth < 400 ? 11.0 : 12.0;

    return Padding(
      padding: const EdgeInsets.only(right: 16.0, top: 8.0),
      child: LineChart(
        LineChartData(
          backgroundColor: chartBackgroundColor,
          titlesData: FlTitlesData(
            show: true,
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameWidget: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("Time",
                    style: TextStyle(
                        fontSize: axisNameFontSize,
                        color: chartTextColor,
                        fontWeight: FontWeight.bold)),
              ),
              axisNameSize: 24,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: timeInterval,
                getTitlesWidget: sideTitleWidgets,
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: Text(appLocalizations.ppmCO2,
                  style: TextStyle(
                      fontSize: axisNameFontSize,
                      color: chartTextColor,
                      fontWeight: FontWeight.bold)),
              sideTitles: SideTitles(
                reservedSize: 40,
                showTitles: true,
                interval: 1000,
                getTitlesWidget: (value, meta) {
                  if (value % 1000 != 0) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(value.toInt().toString(),
                        style: TextStyle(
                            color: chartTextColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: true,
            horizontalInterval: 1000,
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
          minY: 0,
          maxY: 5000,
          maxX: maxTime > 0 ? maxTime : 10,
          minX: minTime,
          clipData: const FlClipData.all(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: chartLineColor,
              barWidth: 2.0,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    chartLineColor.withValues(alpha: 0.3),
                    chartLineColor.withValues(alpha: 0.0),
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
