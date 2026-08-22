import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/soundmeter_state_provider.dart';
import 'package:pslab/view/soundmeter_config_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/export_helper.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/instruments_graph.dart';
import 'package:pslab/view/widgets/soundmeter_card.dart';
import 'package:fl_chart/fl_chart.dart';
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
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  late SoundMeterStateProvider _provider;
  late SoundMeterConfigProvider _configProvider;
  bool _showGuide = false;
  static const imagePath = 'assets/images/guide_images/i2_sensor_guides.png';

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
      const InstrumentCompatibilitySection(
        phoneSupported: true,
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
        builder: (context) => ChangeNotifierProvider.value(
          value: _configProvider,
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
          instrumentIcons: [instrumentIcons[14]],
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_provider.isRecording) {
      final data = _provider.stopRecording();
      await ExportHelper.handleSaveData(
        context: context,
        instrumentName: appLocalizations.soundMeter.toLowerCase(),
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
        return InstrumentsGraph(
          spots: provider.getDbChartData(),
          minX: provider.getMinTime(),
          maxX: provider.getMaxTime(),
          timeInterval: provider.getTimeInterval(),
          minY: 0,
          maxY: 200,
          yInterval: 30,
          yAxisLabel: appLocalizations.db,
          xAxisLabel: appLocalizations.timeAxisLabel,
          extraLines: [
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
        );
      },
    );
  }
}
