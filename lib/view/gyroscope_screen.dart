import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pslab/providers/gyroscope_config_provider.dart';
import 'package:pslab/providers/gyroscope_state_provider.dart';
import 'package:pslab/view/widgets/export_helper.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/gyroscope_card.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/view/logged_data_screen.dart';
import '../theme/colors.dart';
import '../constants.dart';
import 'gyroscope_config_screen.dart';

class GyroscopeScreen extends StatefulWidget {
  final List<List<dynamic>>? playbackData;
  const GyroscopeScreen({super.key, this.playbackData});

  @override
  State<StatefulWidget> createState() => _GyroscopeScreenState();
}

class _GyroscopeScreenState extends State<GyroscopeScreen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  bool _showGuide = false;
  static const imagePath = 'assets/images/gyroscope_axes_orientation.png';
  late GyroscopeProvider _provider;
  late GyroscopeConfigProvider _configProvider;

  String? _lastActiveSensor;

  @override
  void initState() {
    super.initState();
    _provider = GyroscopeProvider();
    _configProvider = GyroscopeConfigProvider();

    _provider.onPlaybackEnd = () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    };

    _configProvider.addListener(_handleConfigChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.playbackData != null) {
          _provider.startPlayback(widget.playbackData!);
        } else {
          _provider.setConfigProvider(_configProvider);
        }
      }
    });
  }

  void _handleConfigChange() {
    if (!mounted || widget.playbackData != null) return;

    final currentSensor = _configProvider.config.activeSensor;

    if (_lastActiveSensor != currentSensor) {
      _lastActiveSensor = currentSensor;
      _provider.initializeSensors();
    }
  }

  @override
  void dispose() {
    _configProvider.removeListener(_handleConfigChange);
    _provider.disposeSensors();
    _provider.dispose();
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

  List<Widget> _getGyroscopeContent() {
    return [
      InstrumentIntroText(
        text: appLocalizations.gyroscopeIntro,
      ),
      const InstrumentImage(
        imagePath: imagePath,
        height: 200.0,
      ),
      InstrumentIntroText(
        text: appLocalizations.gyroscopeDesc,
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
          value: 'gyroscope_config',
          child: Text(appLocalizations.gyroscopeConfigurations),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'gyroscope_config':
            _navigateToConfig();
            break;
        }
      }
    });
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.gyroscope.toLowerCase()],
          appBarName: appLocalizations.gyroscope,
          instrumentIcons: [instrumentIcons[10]],
        ),
      ),
    );
  }

  void _navigateToConfig() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: _configProvider,
          child: const GyroscopeConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_provider.isRecording) {
      final data = _provider.stopRecording();
      await ExportHelper.handleSaveData(
        context: context,
        instrumentName: appLocalizations.gyroscope.toLowerCase(),
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GyroscopeProvider>.value(
      value: _provider,
      child: Stack(children: [
        Consumer<GyroscopeProvider>(
          builder: (context, provider, child) {
            return CommonScaffold(
              title: provider.isPlayingBack
                  ? '${appLocalizations.gyroscopeTitle} - ${appLocalizations.playback}'
                  : appLocalizations.gyroscopeTitle,
              onGuidePressed: _showInstrumentGuide,
              onOptionsPressed:
                  provider.isPlayingBack ? null : _showOptionsMenu,
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const double kPerCardMin = 155.0;
                    const double kPerCardScrollHeight = 220.0;

                    final double available = constraints.maxHeight;
                    final bool needsScroll = available < kPerCardMin * 3;

                    final List<Widget> cards = [
                      GyroscopeCard(
                          color: xOrientationChartLineColor,
                          axis: appLocalizations.xAxis),
                      GyroscopeCard(
                          color: yOrientationChartLineColor,
                          axis: appLocalizations.yAxis),
                      GyroscopeCard(
                          color: zOrientationChartLineColor,
                          axis: appLocalizations.zAxis),
                    ];

                    if (needsScroll) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          children: [
                            for (final card in cards)
                              SizedBox(
                                height: kPerCardScrollHeight,
                                child: card,
                              ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (final card in cards) Expanded(child: card),
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
            instrumentName: appLocalizations.gyroscopeTitle,
            content: _getGyroscopeContent(),
            onHide: _hideInstrumentGuide,
          ),
      ]),
    );
  }
}
