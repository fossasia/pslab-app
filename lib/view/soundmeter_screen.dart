import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/soundmeter_state_provider.dart';
import 'package:pslab/view/soundmeter_config_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/soundmeter_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pslab/others/csv_service.dart';
import 'package:pslab/view/logged_data_screen.dart';
import '../providers/soundmeter_config_provider.dart';
import '../constants.dart';
import '../theme/colors.dart';

class SoundMeterScreen extends StatefulWidget {
  final List<List<dynamic>>? playbackData;
  const SoundMeterScreen({super.key, this.playbackData});

  @override
  State<StatefulWidget> createState() => _SoundMeterScreenState();
}

class _SoundMeterScreenState extends State<SoundMeterScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  final CsvService _csvService = CsvService();
  late SoundMeterStateProvider _provider;
  late SoundMeterConfigProvider _configProvider;
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
          value: 'sound_meter_config',
          child: Text(appLocalizations.soundmeterConfig),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'sound_meter_config':
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
        builder: (context) => ChangeNotifierProvider(
          create: (context) => _configProvider,
          child: const SoundMeterConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.soundMeter.toLowerCase()],
          appBarName: appLocalizations.soundMeter,
          instrumentIcons: [instrumentIcons[15]],
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
              child: Text(appLocalizations.cancel),
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
      _csvService.writeMetaData(
          appLocalizations.soundMeter.toLowerCase(), data);
      final file = await _csvService.saveCsvFile(
          appLocalizations.soundMeter.toLowerCase(), fileName, data);
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
    _provider = SoundMeterStateProvider();
    _configProvider = SoundMeterConfigProvider();
    _provider.onPlaybackEnd = () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.playbackData != null) {
          _provider.startPlayback(widget.playbackData!);
        } else {
          _provider.setConfigProvider(_configProvider);
          _provider.initializeSensors(onError: _showSensorErrorSnackbar);
        }
      }
    });
  }

  @override
  void dispose() {
    _provider.dispose();
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
    return ChangeNotifierProvider<SoundMeterStateProvider>.value(
      value: _provider,
      child: Stack(
        children: [
          Consumer<SoundMeterStateProvider>(
            builder: (context, provider, child) {
              return CommonScaffold(
                title: provider.isPlayingBack
                    ? '${appLocalizations.soundMeter} - ${appLocalizations.playback}'
                    : appLocalizations.soundMeterTitle,
                onGuidePressed: _showInstrumentGuide,
                onOptionsPressed:
                    provider.isPlayingBack ? null : _showOptionsMenu,
                onRecordPressed:
                    provider.isPlayingBack ? null : _toggleRecording,
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
              );
            },
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
                  labelResolver: (line) => appLocalizations.dangerous,
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
