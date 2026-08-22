import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/luxmeter_state_provider.dart';
import 'package:pslab/providers/luxmeter_config_provider.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/export_helper.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/instruments_graph.dart';
import 'package:pslab/view/widgets/luxmeter_card.dart';
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
  bool _showGuide = false;
  static const imagePath = 'assets/images/guide_images/i2_sensor_guides.png';

  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();

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
      InstrumentCompatibilitySection(
        phoneSupported: true,
        pslabOptionalSensor: true,
        note: appLocalizations.luxMeterCompatNote,
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
      await ExportHelper.handleSaveData(
        context: context,
        instrumentName: appLocalizations.luxMeter.toLowerCase(),
        data: data,
      );
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
                await ExportHelper.handleSaveData(
                  context: context,
                  instrumentName: appLocalizations.luxMeter.toLowerCase(),
                  data: data,
                );
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
        double maxLux = provider.getMaxLux();

        return InstrumentsGraph(
          spots: provider.getLuxChartData(),
          minX: provider.getMinTime(),
          maxX: provider.getMaxTime(),
          timeInterval: provider.getTimeInterval(),
          minY: 0,
          maxY: maxLux > 0 ? (maxLux * 1.1) : 100,
          yInterval: maxLux > 0 ? (maxLux / 5).ceilToDouble() : 10,
          xAxisLabel: appLocalizations.timeAxisLabel,
          yAxisLabel: appLocalizations.lx,
        );
      },
    );
  }
}
