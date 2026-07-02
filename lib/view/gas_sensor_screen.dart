import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/gas_sensor_state_provider.dart';
import 'package:pslab/providers/gas_sensor_config_provider.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/export_helper.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:fl_chart/fl_chart.dart';

import 'gas_sensor_config_screen.dart';
import 'widgets/gas_sensor_card.dart';
import '../l10n/app_localizations.dart';
import '../providers/locator.dart';
import '../constants.dart';
import '../theme/colors.dart';

class GasSensorScreen extends StatefulWidget {
  final bool isExperiment;
  final List<List<dynamic>>? playbackData;

  const GasSensorScreen({
    super.key,
    this.isExperiment = false,
    this.playbackData,
  });

  @override
  State<StatefulWidget> createState() => _GasSensorScreenState();
}

class _GasSensorScreenState extends State<GasSensorScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late GasSensorStateProvider _gasProvider;
  late GasSensorConfigProvider _configProvider;
  bool _showGuide = false;

  static const imagePath = 'assets/images/mq_135_gas_sensor.png';

  @override
  void initState() {
    super.initState();
    _gasProvider = GasSensorStateProvider();
    _configProvider = GasSensorConfigProvider();

    _gasProvider.onPlaybackEnd = () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.playbackData != null) {
          _gasProvider.startPlayback(widget.playbackData!);
        } else {
          _gasProvider.initializeSensors();
        }
      }
    });
  }

  @override
  void dispose() {
    _gasProvider.disposeSensors();
    _gasProvider.dispose();
    _configProvider.dispose();
    super.dispose();
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
      InstrumentIntroText(text: appLocalizations.gasSensorGuideIntro),
      const SizedBox(height: 12),
      InstrumentIntroText(text: appLocalizations.gasSensorGuideDetail),
      const SizedBox(height: 16),
      Text(
        appLocalizations.gasSensorGuideConnectLabel,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 8),
      InstrumentIntroText(text: appLocalizations.gasSensorGuideConnectStep1),
      InstrumentIntroText(text: appLocalizations.gasSensorGuideConnectStep2),
      InstrumentIntroText(text: appLocalizations.gasSensorGuideConnectStep3),
      const SizedBox(height: 16),
      const InstrumentImage(imagePath: imagePath),
      const SizedBox(height: 16),
      InstrumentIntroText(text: appLocalizations.gasSensorGuideWarning),
    ];
  }

  void _showOptionsMenu() {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width,
        0,
        0,
        MediaQuery.of(context).size.height,
      ),
      items: [
        PopupMenuItem(
          value: 'show_logged_data',
          child: Text(appLocalizations.showLoggedData),
        ),
        PopupMenuItem(
          value: 'gas_sensor_config',
          child: Text("${appLocalizations.gasSensor} Config"),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'gas_sensor_config':
            _navigateToConfig();
            break;
        }
      }
    });
  }

  void _navigateToConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChangeNotifierProvider<GasSensorConfigProvider>.value(
          value: _configProvider,
          child: const GasSensorConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.gasSensor.toLowerCase()],
          appBarName: appLocalizations.gasSensor,
          instrumentIcons: [instrumentIcons[13]],
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_gasProvider.isRecording) {
      final data = _gasProvider.stopRecording();
      await ExportHelper.handleSaveData(
        context: context,
        instrumentName: appLocalizations.gasSensor.toLowerCase(),
        data: data,
      );
    } else {
      await _gasProvider.startRecording();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${appLocalizations.recordingStarted}...',
            style: TextStyle(color: snackBarContentColor),
          ),
          backgroundColor: snackBarBackgroundColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GasSensorStateProvider>.value(
            value: _gasProvider),
        ChangeNotifierProvider<GasSensorConfigProvider>.value(
            value: _configProvider),
      ],
      child: Stack(
        children: [
          Consumer<GasSensorStateProvider>(
            builder: (context, provider, child) {
              return CommonScaffold(
                title: provider.isPlayingData()
                    ? '${appLocalizations.gasSensor} - ${appLocalizations.playback}'
                    : appLocalizations.gasSensor,
                onOptionsPressed:
                    provider.isPlayingData() ? null : _showOptionsMenu,
                onGuidePressed: _showInstrumentGuide,
                onRecordPressed:
                    provider.isPlayingData() ? null : _toggleRecording,
                isRecording: provider.isRecording,
                isPlayingBack: provider.isPlayingData(),
                isPlaybackPaused: provider.isPlaybackPaused,
                onPlaybackPauseResume: provider.isPlayingData()
                    ? (provider.isPlaybackPaused
                        ? _gasProvider.resumePlayback
                        : _gasProvider.pausePlayback)
                    : null,
                onPlaybackStop: provider.isPlayingData()
                    ? () async {
                        await _gasProvider.stopPlayback();
                      }
                    : null,
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
              );
            },
          ),
          if (_showGuide)
            InstrumentOverviewDrawer(
              instrumentName: appLocalizations.gasSensor,
              content: _getGasSensorContent(),
              onHide: _hideInstrumentGuide,
            ),
        ],
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
          child: _buildChart(
              screenWidth,
              provider.getMaxTime(),
              provider.getMinTime(),
              provider.getTimeInterval(),
              spots,
              provider.getActiveMode()),
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
      double timeInterval, List<FlSpot> spots, String activeMode) {
    final axisNameFontSize = screenWidth < 400 ? 11.0 : 12.0;

    double yMax = 1024;
    double yInterval = 200;
    String yLabel = "Raw Data";

    final cleanedMode = activeMode.trim();
    bool isPpmMode = cleanedMode.toLowerCase() != 'raw' ||
        spots.any((spot) => spot.y > 1024);

    if (isPpmMode) {
      yMax = 5000;
      yInterval = 1000;
      if (cleanedMode.toLowerCase() == 'raw') {
        yLabel = appLocalizations.concentrationPpm;
      } else {
        yLabel = cleanedMode.toLowerCase().contains('ppm')
            ? cleanedMode
            : "$cleanedMode (ppm)";
      }
    } else {
      yMax = 1024;
      yInterval = 200;
      yLabel = appLocalizations.airQuality;
    }

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
              axisNameWidget: Text(yLabel,
                  style: TextStyle(
                      fontSize: axisNameFontSize,
                      color: chartTextColor,
                      fontWeight: FontWeight.bold)),
              sideTitles: SideTitles(
                reservedSize: 40,
                showTitles: true,
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  if (value % yInterval != 0) return const SizedBox.shrink();
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
          minY: 0,
          maxY: yMax,
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
                    chartLineColor.withValues(alpha: 0.0)
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
