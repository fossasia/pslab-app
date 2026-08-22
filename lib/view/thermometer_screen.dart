import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/thermometer_state_provider.dart';
import 'package:pslab/providers/thermometer_config_provider.dart';
import 'package:pslab/view/thermometer_config_screen.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/export_helper.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/instruments_graph.dart';
import 'package:pslab/view/widgets/thermometer_card.dart';
import 'package:fl_chart/fl_chart.dart';

import '../l10n/app_localizations.dart';
import '../providers/locator.dart';
import '../theme/colors.dart';
import '../constants.dart';

class ThermometerScreen extends StatefulWidget {
  final List<List<dynamic>>? playbackData;

  const ThermometerScreen({super.key, this.playbackData});

  @override
  State<StatefulWidget> createState() => _ThermometerScreenState();
}

class _ThermometerScreenState extends State<ThermometerScreen> {
  AppLocalizations appLocalizations = getIt.get<AppLocalizations>();
  late ThermometerStateProvider _temperatureProvider;
  late ThermometerConfigProvider _configProvider;

  bool _showGuide = false;
  bool _snackbarShown = false;

  @override
  void initState() {
    super.initState();
    _temperatureProvider = ThermometerStateProvider();
    _configProvider = ThermometerConfigProvider();

    _temperatureProvider.onPlaybackEnd = () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.playbackData != null) {
          _temperatureProvider.startPlayback(widget.playbackData!);
        } else {
          _temperatureProvider.setConfigProvider(_configProvider);
          _temperatureProvider.initializeSensors();
        }
      }
    });
  }

  @override
  void dispose() {
    _temperatureProvider.dispose();
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
        text: appLocalizations.thermometerIntro,
      ),
      InstrumentCompatibilitySection(
        phoneSupported: true,
        pslabOptionalSensor: true,
        note: appLocalizations.thermometerCompatNote,
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
          value: 'thermometer_config',
          child: Text(appLocalizations.thermometerConfig),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'thermometer_config':
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
        builder: (context) => ChangeNotifierProvider.value(
          value: _configProvider,
          child: const ThermometerConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.thermometerTitle.toLowerCase()],
          appBarName: appLocalizations.thermometerTitle,
          instrumentIcons: [instrumentIcons[11]],
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_temperatureProvider.isRecording) {
      final data = _temperatureProvider.stopRecording();
      await ExportHelper.handleSaveData(
        context: context,
        instrumentName: appLocalizations.thermometer.toLowerCase(),
        data: data,
      );
    } else {
      await _temperatureProvider.startRecording();
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
        ChangeNotifierProvider<ThermometerStateProvider>.value(
          value: _temperatureProvider,
        ),
        ChangeNotifierProvider<ThermometerConfigProvider>.value(
          value: _configProvider,
        ),
      ],
      child: Consumer<ThermometerStateProvider>(
        builder: (context, provider, child) {
          if (!provider.isSensorAvailable() &&
              !_snackbarShown &&
              provider.isInitialized() &&
              !provider.isPlayingBack) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showSensorErrorSnackbar(
                  appLocalizations.temperatureSensorUnavailableMessage);
              _snackbarShown = true;
            });
          }

          return Stack(
            children: [
              CommonScaffold(
                title: provider.isPlayingBack
                    ? '${appLocalizations.thermometerTitle} - Playback'
                    : appLocalizations.thermometerTitle,
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
                        ? _temperatureProvider.resumePlayback
                        : _temperatureProvider.pausePlayback)
                    : null,
                onPlaybackStop: provider.isPlayingBack
                    ? () async {
                        await _temperatureProvider.stopPlayback();
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
                          child: ThermometerCard(),
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
                          child: ThermometerCard(),
                        ),
                        Expanded(
                          flex: 55,
                          child: _buildChartSection(),
                        ),
                      ],
                    );
                  }
                })),
              ),
              if (_showGuide)
                InstrumentOverviewDrawer(
                  instrumentName: appLocalizations.thermometerTitle,
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
        final unit = context.watch<ThermometerConfigProvider>().config.unit;

        List<FlSpot> spots = provider.getTemperatureChartData();
        double minY = spots.isNotEmpty
            ? spots.map((s) => s.y).reduce((a, b) => a < b ? a : b)
            : 0.0;
        double maxY = spots.isNotEmpty
            ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b)
            : 50.0;

        return InstrumentsGraph(
          spots: spots,
          minX: provider.getMinTime(),
          maxX: provider.getMaxTime(),
          timeInterval: provider.getTimeInterval(),
          minY: minY < -40 ? minY - 3 : -40,
          maxY: maxY > 50 ? maxY + 3 : 50,
          yInterval: 10,
          xAxisLabel: appLocalizations.timeAxisLabel,
          yAxisLabel: unit == "Fahrenheit"
              ? appLocalizations.fahrenheitUnit
              : appLocalizations.celsius,
        );
      },
    );
  }
}
