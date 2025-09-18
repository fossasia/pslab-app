import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/luxmeter_state_provider.dart';
import 'package:pslab/providers/luxmeter_config_provider.dart';
import 'package:pslab/others/csv_service.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/luxmeter_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pslab/view/luxmeter_config_screen.dart';
import '../providers/experiment_provider.dart';
import './widgets/experiment_overlay_widget.dart';
import '../constants.dart';
import '../theme/colors.dart';

class LuxMeterScreen extends StatefulWidget {
  final bool isExperiment;
  final List<List<dynamic>>? playbackData;

  const LuxMeterScreen({
    super.key,
    this.isExperiment = false,
    this.playbackData,
  });
  @override
  State<StatefulWidget> createState() => _LuxMeterScreenState();
}

class _LuxMeterScreenState extends State<LuxMeterScreen> {
  late LuxMeterStateProvider _provider;
  late LuxMeterConfigProvider _configProvider;
  final CsvService _csvService = CsvService();
  bool _showGuide = false;
  static const imagePath = 'assets/images/bh1750_schematic.png';
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();

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

  List<Widget> _getLuxMeterContent() {
    return [
      InstrumentBulletPoint(
        text: appLocalizations.luxMeterDesc,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.luxMeterSensorIntro,
      ),
      const InstrumentImage(
        imagePath: imagePath,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.luxMeterBulletPoint1,
      ),
      InstrumentBulletPoint(text: appLocalizations.luxMeterBulletPoint2),
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
          value: 'lux_meter_config',
          child: Text(appLocalizations.showLuxmeterConfig),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'lux_meter_config':
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
            ChangeNotifierProvider<LuxMeterConfigProvider>.value(
          value: _configProvider,
          child: const LuxMeterConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.luxMeter.toLowerCase()],
          appBarName: appLocalizations.luxMeterTitle,
          instrumentIcons: [instrumentIcons[6]],
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_provider.isRecording) {
      final data = _provider.stopRecording();
      await _showSaveFileDialog(data);
    } else {
      await _provider.startRecording();
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

  Future<void> _showSaveFileDialog(List<List<dynamic>> data) async {
    final TextEditingController filenameController = TextEditingController();
    final String defaultFilename =
        '${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.csv';
    filenameController.text = defaultFilename;

    final String? fileName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(appLocalizations.saveRecording),
          content: TextField(
            controller: filenameController,
            decoration: InputDecoration(
              hintText: appLocalizations.enterFileName,
              labelText: appLocalizations.fileName,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(appLocalizations.cancel.toUpperCase()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, filenameController.text);
              },
              child: Text(appLocalizations.save),
            ),
          ],
        );
      },
    );

    if (fileName != null) {
      _csvService.writeMetaData(appLocalizations.luxMeter.toLowerCase(), data);
      final file = await _csvService.saveCsvFile(
          appLocalizations.luxMeter.toLowerCase(), fileName, data);
      if (mounted) {
        if (file != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${appLocalizations.fileSaved}: ${file.path.split('/').last}',
                style: TextStyle(color: snackBarContentColor),
              ),
              backgroundColor: snackBarBackgroundColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                appLocalizations.failedToSave,
                style: TextStyle(color: snackBarContentColor),
              ),
              backgroundColor: snackBarBackgroundColor,
            ),
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _provider = LuxMeterStateProvider();
    _configProvider = LuxMeterConfigProvider();

    _provider.onPlaybackEnd = () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _provider.onSensorError = (msg) {
          _showSensorErrorSnackbar(msg);
        };
        if (widget.playbackData != null) {
          _provider.startPlayback(widget.playbackData!);
        } else {
          _provider.setConfigProvider(_configProvider);
        }
      }
    });
    if (widget.isExperiment) {
      _experimentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _checkExperimentConditions();
      });
    }
  }

  Timer? _experimentTimer;

  void _checkExperimentConditions() {
    if (!widget.isExperiment) return;

    final experimentProvider = context.read<ExperimentProvider>();
    if (experimentProvider.state == ExperimentState.running) {
      final luxData =
          _provider.getLuxChartData().map((spot) => spot.y).toList();
      final timeData =
          _provider.getLuxChartData().map((spot) => spot.x).toList();

      experimentProvider.checkStepCondition(luxData, timeData);
    }
  }

  @override
  void dispose() {
    _experimentTimer?.cancel();
    _provider.disposeSensors();
    _provider.dispose();
    _configProvider.dispose();
    super.dispose();
  }

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
        ChangeNotifierProvider<LuxMeterStateProvider>.value(value: _provider),
        ChangeNotifierProvider<LuxMeterConfigProvider>.value(
            value: _configProvider),
      ],
      child: Stack(children: [
        Consumer<LuxMeterStateProvider>(
          builder: (context, provider, child) {
            return CommonScaffold(
              title: provider.isPlayingBack
                  ? '${appLocalizations.luxMeterTitle} - ${appLocalizations.playback}'
                  : appLocalizations.luxMeterTitle,
              onOptionsPressed:
                  provider.isPlayingBack ? null : _showOptionsMenu,
              onGuidePressed: _showInstrumentGuide,
              onRecordPressed: provider.isPlayingBack ? null : _toggleRecording,
              isRecording: provider.isRecording,
              isPlayingBack: provider.isPlayingBack,
              isPlaybackPaused: provider.isPlaybackPaused,
              onPlaybackPauseResume: provider.isPlayingBack
                  ? (provider.isPlaybackPaused
                      ? _provider.resumePlayback
                      : _provider.pausePlayback)
                  : null,
              onPlaybackStop: provider.isPlayingBack
                  ? () async {
                      await _provider.stopPlayback();
                    }
                  : null,
              body: SafeArea(
                  child: LayoutBuilder(builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth > 900;
                if (isLargeScreen) {
                  return Row(
                    children: [
                      const Expanded(
                        flex: 35,
                        child: LuxMeterCard(),
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
                        child: LuxMeterCard(),
                      ),
                      Expanded(
                        flex: 55,
                        child: _buildChartSection(),
                      ),
                    ],
                  );
                }
              })),
            );
          },
        ),
        if (_showGuide)
          InstrumentOverviewDrawer(
            instrumentName: appLocalizations.luxMeterTitle,
            content: _getLuxMeterContent(),
            onHide: _hideInstrumentGuide,
          ),
        if (widget.isExperiment)
          ExperimentOverlayWidget(
            onExperimentComplete: () async {
              if (_provider.isRecording) {
                final data = _provider.stopRecording();
                await _showSaveFileDialog(data);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
      ]),
    );
  }

  Widget _buildChartSection() {
    return Consumer<LuxMeterStateProvider>(
      builder: (context, provider, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final cardMargin = screenWidth < 400 ? 8.0 : 16.0;
        final cardPadding = screenWidth < 400 ? 2.0 : 5.0;
        List<FlSpot> spots = provider.getLuxChartData();
        double maxLux = provider.getMaxLux();
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
          child: _buildChart(
              screenWidth, maxLux, maxTime, minTime, timeInterval, spots),
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

  Widget _buildChart(double screenWidth, double maxLux, double maxTime,
      double minTime, double timeInterval, List<FlSpot> spots) {
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
                appLocalizations.lx,
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
                interval: maxLux > 0 ? (maxLux / 5).ceilToDouble() : 10,
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
            horizontalInterval: maxLux > 0 ? (maxLux / 5).ceilToDouble() : 10,
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
          maxY: maxLux > 0 ? (maxLux * 1.1) : 100,
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
