import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/models/oscilloscope_recording_metadata.dart';
import 'package:pslab/others/csv_service.dart';
import 'package:pslab/providers/locator.dart';
import 'package:pslab/providers/oscilloscope_config_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/oscilloscope_config_screen.dart';
import 'package:pslab/view/widgets/channel_parameters_widget.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/data_analysis_widget.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/measurements_list.dart';
import 'package:pslab/view/widgets/oscilloscope_graph.dart';
import 'package:pslab/view/widgets/oscilloscope_screen_tabs.dart';
import 'package:pslab/view/widgets/save_filename_dialog.dart';
import 'package:pslab/view/widgets/timebase_trigger_widget.dart';
import 'package:pslab/view/widgets/xyplot_widget.dart';

import '../providers/oscilloscope_state_provider.dart';

class OscilloscopeScreen extends StatefulWidget {
  final String icRecord = 'assets/icons/ic_record_white.png';
  final String oscilloscopeSchematic =
      'assets/images/oscilloscope_schematic.png';
  final String micSchematic = 'assets/images/mic_schematic.png';
  final String timebaseView = 'assets/images/timebase_view.png';
  final String dataAnalysisView = 'assets/images/data_analysis_view.png';
  final String xyPlotView = 'assets/images/xy_plot_view.png';
  final List<List<dynamic>>? playbackData;
  final String? playbackName;
  const OscilloscopeScreen({super.key, this.playbackData, this.playbackName});

  @override
  State<StatefulWidget> createState() => _OscilloscopeScreenState();
}

class _OscilloscopeScreenState extends State<OscilloscopeScreen> {
  late OscilloscopeStateProvider _provider;
  late OscilloscopeConfigProvider? _configProvider;
  final CsvService _csvService = CsvService();
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  bool _showGuide = false;
  OscilloscopeRecordingMetadata? _playbackMetadata;
  @override
  void initState() {
    _provider = OscilloscopeStateProvider();
    _configProvider = OscilloscopeConfigProvider();
    _provider.setConfigProvider(_configProvider!);

    _provider.onPlaybackEnd = () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    };

    if (widget.playbackData != null && widget.playbackData!.isNotEmpty) {
      final metaRow = widget.playbackData!.first;
      if (metaRow.length >= 4) {
        _playbackMetadata = OscilloscopeRecordingMetadata.tryDecode(metaRow[3]);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscapeOrientation();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (widget.playbackData != null) {
        _provider.startPlayback(widget.playbackData!);
      }
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (ModalRoute.of(context)?.isCurrent ?? true) {
      _setLandscapeOrientation();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    super.didChangeDependencies();
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
          value: 'oscilloscope_config',
          child: Text(appLocalizations.oscilloscopeConfigs),
        ),
        PopupMenuItem<CheckboxListTile>(
          child: CheckboxListTile(
            title: Text(appLocalizations.automatedMeasurements),
            secondary: IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(appLocalizations.automatedMeasurements),
                        content:
                            Text(appLocalizations.automatedMeasurementsInfo),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(appLocalizations.ok),
                          ),
                        ],
                      );
                    },
                  );
                }),
            value: _provider.isMeasurementsChecked,
            onChanged: (bool? newValue) {
              setState(() {
                _provider.isMeasurementsChecked = newValue ?? false;
              });
              Navigator.pop(context);
            },
          ),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'oscilloscope_config':
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
            ChangeNotifierProvider<OscilloscopeConfigProvider>.value(
          value: _configProvider!,
          child: const OscilloscopeConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.oscilloscope.toLowerCase()],
          appBarName: appLocalizations.oscilloscope,
          instrumentIcons: [instrumentIcons[0]],
        ),
      ),
    );
  }

  void _showInstrumentGuide() {
    setState(() {
      _showGuide = true;
    });
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  void _showRecordingDetailsSheet(OscilloscopeRecordingMetadata metadata) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      constraints: BoxConstraints(
        maxWidth: 640,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _RecordingDetailsSheet(metadata: metadata),
    );
  }

  List<Widget> _getOscilloscopeContent() {
    return [
      InstrumentBulletPoint(text: appLocalizations.oscilloscopeBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.oscilloscopeBulletPoint2),
      InstrumentImage(imagePath: widget.oscilloscopeSchematic),
      InstrumentBulletPoint(text: appLocalizations.oscilloscopeBulletPoint3),
      InstrumentBulletPoint(text: appLocalizations.oscilloscopeBulletPoint4),
      InstrumentHeading(text: appLocalizations.channelParameters),
      InstrumentIntroText(text: appLocalizations.channelParametersIntro),
      InstrumentBulletPoint(
          text: appLocalizations.channelParametersBulletPoint1),
      InstrumentBulletPoint(
          text: appLocalizations.channelParametersBulletPoint2),
      InstrumentBulletPoint(
          text: appLocalizations.channelParametersBulletPoint3),
      InstrumentImage(imagePath: widget.micSchematic),
      InstrumentBulletPoint(
          text: appLocalizations.channelParametersBulletPoint4),
      InstrumentHeading(text: appLocalizations.timeBaseAndTrigger),
      InstrumentIntroText(text: appLocalizations.timebaseIntro),
      InstrumentBulletPoint(text: appLocalizations.timebaseBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.timebaseBulletPoint2),
      InstrumentBulletPoint(text: appLocalizations.timebaseBulletPoint3),
      InstrumentImage(imagePath: widget.timebaseView),
      InstrumentHeading(text: appLocalizations.dataAnalysis),
      InstrumentBulletPoint(text: appLocalizations.dataAnalysisBulletPoint1),
      InstrumentBulletPoint(text: appLocalizations.dataAnalysisBulletPoint2),
      InstrumentImage(imagePath: widget.dataAnalysisView),
      InstrumentHeading(text: appLocalizations.xyPlot),
      InstrumentBulletPoint(text: appLocalizations.xyPlotBulletPoint1),
      InstrumentImage(imagePath: widget.xyPlotView),
    ];
  }

  @override
  void dispose() {
    if (widget.playbackData == null) {
      _setPortraitOrientation();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_provider.isRecording) {
      final data = _provider.stopRecording();
      await _showSaveFileDialog(data);
    } else {
      bool hasStarted = await _provider.startRecording();
      if (!mounted) return;
      if (hasStarted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${appLocalizations.recordingStarted}...',
              style: TextStyle(color: snackBarContentColor),
            ),
            backgroundColor: snackBarBackgroundColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appLocalizations.notConnected,
              style: TextStyle(color: snackBarContentColor),
            ),
            backgroundColor: snackBarBackgroundColor,
          ),
        );
      }
    }
  }

  Future<void> _showSaveFileDialog(List<List<dynamic>> data) async {
    final String? fileName = await showSaveFileNameDialog(context);

    if (fileName != null) {
      _csvService.writeMetaData(
          appLocalizations.oscilloscope.toLowerCase(), data,
          extraMetadata: _provider.recordingMetadata?.encode());
      final file = await _csvService.saveCsvFile(
          appLocalizations.oscilloscope.toLowerCase(), fileName, data);
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
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OscilloscopeStateProvider>(
          create: (_) => _provider,
        ),
      ],
      child: Consumer<OscilloscopeStateProvider>(
        builder: (context, provider, _) {
          return Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.enter):
                  DoNothingAndStopPropagationIntent(),
              SingleActivator(LogicalKeyboardKey.numpadEnter):
                  DoNothingAndStopPropagationIntent(),
              SingleActivator(LogicalKeyboardKey.arrowUp):
                  DoNothingAndStopPropagationIntent(),
              SingleActivator(LogicalKeyboardKey.arrowDown):
                  DoNothingAndStopPropagationIntent(),
            },
            child: Stack(
              children: [
                CommonScaffold(
                  title: widget.playbackData != null &&
                          widget.playbackName != null &&
                          widget.playbackName!.isNotEmpty
                      ? widget.playbackName!
                      : appLocalizations.oscilloscope,
                  key: const Key(oscilloscopeScreenTitleKey),
                  onOptionsPressed:
                      provider.isPlayingBack ? null : _showOptionsMenu,
                  onGuidePressed: _showInstrumentGuide,
                  onRecordPressed:
                      provider.isPlayingBack ? null : _toggleRecording,
                  isRecording: provider.isRecording,
                  isPlayingBack: provider.isPlayingBack,
                  isPlaybackPaused: provider.isPlaybackPaused,
                  onPlaybackPauseResume: null,
                  onPlaybackStop: null,
                  body: ColoredBox(
                    color: widget.playbackData != null
                        ? Colors.black
                        : Colors.transparent,
                    child: SafeArea(
                      left: false,
                      right: false,
                      minimum: const EdgeInsets.only(right: 0, bottom: 0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            margin: const EdgeInsets.only(left: 5, top: 5),
                            child: widget.playbackData != null
                                ? Column(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(right: 5),
                                          padding:
                                              const EdgeInsets.only(bottom: 20),
                                          color: Colors.black,
                                          child: OscilloscopeGraph(),
                                        ),
                                      ),
                                      _PlaybackControlBar(
                                        isPaused: provider.isPlaybackPaused,
                                        isComplete: provider.isPlaybackComplete,
                                        position: provider.playbackPosition,
                                        duration: provider.playbackDuration,
                                        currentFrame:
                                            provider.playbackCurrentFrame,
                                        totalFrames:
                                            provider.playbackTotalFrames,
                                        onPlayPause: () {
                                          if (provider.isPlaybackPaused) {
                                            _provider.resumePlayback();
                                          } else {
                                            _provider.pausePlayback();
                                          }
                                        },
                                        onSeek: _provider.seekToFrame,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        flex: 89,
                                        child: Container(
                                          margin:
                                              const EdgeInsets.only(right: 5),
                                          child: Stack(
                                            children: [
                                              Column(
                                                children: [
                                                  Expanded(
                                                    flex:
                                                        constraints.maxHeight <
                                                                600
                                                            ? 68
                                                            : 80,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 20),
                                                      color: Colors.black,
                                                      child:
                                                          const OscilloscopeGraph(),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex:
                                                        constraints.maxHeight <
                                                                600
                                                            ? 32
                                                            : 20,
                                                    child: Selector<
                                                        OscilloscopeStateProvider,
                                                        int>(
                                                      selector: (context,
                                                              provider) =>
                                                          provider
                                                              .selectedIndex,
                                                      builder: (context,
                                                          selectedIndex, _) {
                                                        switch (selectedIndex) {
                                                          case 0:
                                                            return const ChannelParametersWidget();
                                                          case 1:
                                                            return const TimebaseTriggerWidget();
                                                          case 2:
                                                            return const DataAnalysisWidget();
                                                          case 3:
                                                            return const XYPlotWidget();
                                                          default:
                                                            return const ChannelParametersWidget();
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              provider.isMeasurementsChecked
                                                  ? Positioned(
                                                      right: 0,
                                                      top: 0,
                                                      child: SizedBox(
                                                          width: (constraints
                                                                      .maxWidth *
                                                                  0.18)
                                                              .clamp(
                                                                  100.0, 350.0)
                                                              .toDouble(),
                                                          child: MeasurementsList(
                                                              dataParamsChannels:
                                                                  provider
                                                                      .dataParamsChannels)),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        flex: 11,
                                        child: OscilloscopeScreenTabs(),
                                      )
                                    ],
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        if ((((provider.isCH1Selected ||
                                        provider.isCH2Selected ||
                                        provider.isCH3Selected ||
                                        provider.isMICSelected) &&
                                    getIt<ScienceLab>().isConnected()) ||
                                provider.isInBuiltMICSelected) &&
                            !provider.autoScale()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(appLocalizations.noSignal),
                            ),
                          );
                        }
                      },
                      child: Text(appLocalizations.autoScale,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    if (widget.playbackData != null &&
                        _playbackMetadata != null &&
                        !_playbackMetadata!.isEmpty)
                      IconButton(
                        tooltip: 'Recording details',
                        icon: const Icon(Icons.article_outlined,
                            color: Colors.white),
                        onPressed: () =>
                            _showRecordingDetailsSheet(_playbackMetadata!),
                      ),
                    widget.playbackData == null
                        ? IconButton(
                            icon: provider.isRunning
                                ? const Icon(
                                    Icons.pause,
                                    color: Colors.white,
                                  )
                                : const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                            onPressed: () {
                              if (provider.isRunning) {
                                provider.isRunning = false;
                              } else {
                                provider.isRunning = true;
                              }
                              setState(
                                () {},
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
                if (_showGuide)
                  InstrumentOverviewDrawer(
                    instrumentName: appLocalizations.oscilloscope,
                    content: _getOscilloscopeContent(),
                    onHide: _hideInstrumentGuide,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final hours = d.inHours.toString().padLeft(2, '0');
  final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

class _PlaybackControlBar extends StatefulWidget {
  final bool isPaused;
  final bool isComplete;
  final Duration position;
  final Duration duration;
  final int currentFrame;
  final int totalFrames;
  final VoidCallback onPlayPause;
  final ValueChanged<int> onSeek;

  const _PlaybackControlBar({
    required this.isPaused,
    required this.isComplete,
    required this.position,
    required this.duration,
    required this.currentFrame,
    required this.totalFrames,
    required this.onPlayPause,
    required this.onSeek,
  });

  @override
  State<_PlaybackControlBar> createState() => _PlaybackControlBarState();
}

class _PlaybackControlBarState extends State<_PlaybackControlBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final int total = widget.totalFrames;
    final double maxValue = total > 0 ? total.toDouble() : 1;
    final double sliderValue =
        (_dragValue ?? widget.currentFrame.toDouble()).clamp(0, maxValue);

    final IconData playIcon = widget.isComplete
        ? Icons.replay
        : (widget.isPaused ? Icons.play_arrow : Icons.pause);

    final Duration shownPosition =
        widget.isComplete ? widget.duration : widget.position;

    final bool compact = MediaQuery.of(context).size.width < 400;
    final double iconSize = compact ? 20 : 24;
    final double buttonWidth = compact ? 36 : 44;
    final TextStyle timeStyle = TextStyle(
      color: Colors.white,
      fontSize: compact ? 10 : 12,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(
          left: compact ? 4 : 8, right: compact ? 8 : 16, bottom: 6, top: 2),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onPlayPause,
            padding: EdgeInsets.zero,
            constraints:
                BoxConstraints.tightFor(width: buttonWidth, height: 40),
            iconSize: iconSize,
            tooltip: widget.isComplete
                ? 'Replay'
                : (widget.isPaused ? 'Play' : 'Pause'),
            icon: Icon(playIcon, color: Colors.white),
          ),
          Text(_formatDuration(shownPosition),
              style: timeStyle, maxLines: 1, softWrap: false),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: primaryRed,
                inactiveTrackColor: Colors.white24,
                thumbColor: primaryRed,
                overlayColor: primaryRed.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: sliderValue,
                min: 0,
                max: maxValue,
                onChanged: total > 0
                    ? (v) {
                        setState(() => _dragValue = v);
                        widget.onSeek(v.round());
                      }
                    : null,
                onChangeEnd: (v) {
                  widget.onSeek(v.round());
                  setState(() => _dragValue = null);
                },
              ),
            ),
          ),
          Text(_formatDuration(widget.duration),
              style: timeStyle, maxLines: 1, softWrap: false),
        ],
      ),
    );
  }
}

class _RecordingDetailsSheet extends StatelessWidget {
  final OscilloscopeRecordingMetadata metadata;

  const _RecordingDetailsSheet({required this.metadata});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final m = metadata;
    final entries = <MapEntry<String, String>>[
      if (m.recordedAt != null)
        MapEntry('Date Recorded',
            DateFormat('yyyy-MM-dd HH:mm:ss').format(m.recordedAt!)),
      if (m.enabledChannels.isNotEmpty)
        MapEntry('Channels', m.enabledChannels.join(', ')),
      if (m.range != null && m.range!.isNotEmpty) MapEntry('Range', m.range!),
      if (m.enabledChannels.contains('CH3'))
        const MapEntry('CH3 Range', '±3.3V'),
      if (m.timebase != null) MapEntry('Timebase', m.timebase.toString()),
      MapEntry('Trigger Mode',
          m.triggerEnabled ? _prettyMode(m.triggerMode) : 'Off'),
      if (m.triggerEnabled && m.triggerLevel != null)
        MapEntry('Trigger Level', '${m.triggerLevel} V'),
      if (m.samplingRate != null)
        MapEntry('Sampling Rate', _prettyRate(m.samplingRate!)),
      if (m.samplesPerFrame != null)
        MapEntry('Samples', '${m.samplesPerFrame}'),
      if (m.sampleCount != null) MapEntry('Frames', '${m.sampleCount}'),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.article_outlined,
                  color: primaryRed,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Recording Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 4),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No details available',
                  style: TextStyle(fontSize: 14, color: hintTextColor),
                ),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 150,
                                child: Text(
                                  e.key,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: hintTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _prettyMode(String? mode) {
  if (mode == null || mode.isEmpty) return '';
  final dot = mode.lastIndexOf('.');
  return dot >= 0 ? mode.substring(dot + 1) : mode;
}

String _prettyRate(double hz) {
  if (hz >= 1e6) return '${(hz / 1e6).toStringAsFixed(2)} MHz';
  if (hz >= 1e3) return '${(hz / 1e3).toStringAsFixed(2)} kHz';
  return '${hz.toStringAsFixed(0)} Hz';
}
