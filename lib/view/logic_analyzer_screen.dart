import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pslab/communication/science_lab.dart';
import 'package:pslab/constants.dart';
import 'package:pslab/providers/logic_analyzer_config_provider.dart';
import 'package:pslab/providers/logic_analyzer_state_provider.dart';
import 'package:pslab/theme/colors.dart';
import 'package:pslab/view/logged_data_screen.dart';
import 'package:pslab/view/logic_analyzer_config_screen.dart';
import 'package:pslab/view/widgets/common_scaffold_widget.dart';
import 'package:pslab/view/widgets/export_helper.dart';
import 'package:pslab/view/widgets/guide_widget.dart';
import 'package:pslab/view/widgets/logic_analyzer_channel_selection.dart';
import 'package:pslab/view/widgets/logic_analyzer_graph.dart';
import 'package:pslab/l10n/app_localizations.dart';
import 'package:pslab/providers/locator.dart';

class LogicAnalyzerScreen extends StatefulWidget {
  const LogicAnalyzerScreen({super.key, this.playbackData, this.fileName});
  final List<List<dynamic>>? playbackData;
  final String? fileName;
  final logicAnalyzerCircuit = 'assets/images/logic_analyzer_circuit.png';

  @override
  State<StatefulWidget> createState() => _LogicAnalyzerScreenState();
}

class _LogicAnalyzerScreenState extends State<LogicAnalyzerScreen> {
  AppLocalizations get appLocalizations => getIt.get<AppLocalizations>();
  late LogicAnalyzerStateProvider _provider;
  late LogicAnalyzerConfigProvider? _configProvider;
  bool _showGuide = false;

  void _hideInstrumentGuide() {
    setState(() {
      _showGuide = false;
    });
  }

  List<Widget> _getLogicAnalyzerContent() {
    return [
      InstrumentIntroText(
        text: appLocalizations.logicAnalyzerIntro,
      ),
      InstrumentImage(
        imagePath: widget.logicAnalyzerCircuit,
      ),
      InstrumentIntroText(
        text: appLocalizations.logicAnalyzerWaveGenCaption,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerWaveGenBulletPoint1,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerWaveGenBulletPoint2,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerWaveGenBulletPoint3,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerWaveGenBulletPoint4,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerWaveGenBulletPoint5,
      ),
      InstrumentIntroText(
        text: appLocalizations.logicAnalyzerConnectionCaption,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerConnectionBulletPoint1,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerConnectionBulletPoint2,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerConnectionBulletPoint3,
      ),
      InstrumentIntroText(
        text: appLocalizations.logicAnalyzerUsageCaption,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerUsageBulletPoint1,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerUsageBulletPoint2,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerUsageBulletPoint3,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerUsageBulletPoint4,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerUsageBulletPoint5,
      ),
      InstrumentIntroText(
        text: appLocalizations.logicAnalyzerEdgeCaption,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerEdgeBulletPoint1,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerEdgeBulletPoint2,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerEdgeBulletPoint3,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerEdgeBulletPoint4,
      ),
      InstrumentIntroText(
        text: appLocalizations.logicAnalyzerMeasurementCaption,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerMeasurementBulletPoint1,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerMeasurementBulletPoint2,
      ),
      InstrumentBulletPoint(
        text: appLocalizations.logicAnalyzerMeasurementBulletPoint3,
      ),
    ];
  }

  @override
  void initState() {
    _provider = LogicAnalyzerStateProvider();
    _configProvider = LogicAnalyzerConfigProvider();
    _provider.setConfigProvider(_configProvider!);
    if (widget.playbackData != null) {
      _provider.loadPlaybackData(widget.playbackData!);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscapeOrientation();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
    super.initState();
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _setPortraitOrientation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
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
          value: 'logic_analyzer_config',
          child: Text(appLocalizations.logicAnalyzerConfigs),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'show_logged_data':
            _navigateToLoggedData();
            break;
          case 'logic_analyzer_config':
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
            ChangeNotifierProvider<LogicAnalyzerConfigProvider>.value(
          value: _configProvider!,
          child: const LogicAnalyzerConfigScreen(),
        ),
      ),
    );
  }

  Future<void> _navigateToLoggedData() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoggedDataScreen(
          instrumentNames: [appLocalizations.logicAnalyzer.toLowerCase()],
          appBarName: appLocalizations.logicAnalyzer,
          instrumentIcons: [instrumentIcons[2]],
        ),
      ),
    );
  }

  void _showInstrumentGuide() {
    setState(() {
      _showGuide = true;
    });
  }

  String _formatDuration(double micros) {
    if (micros >= 1e6) return '${(micros / 1e6).toStringAsFixed(3)} s';
    if (micros >= 1e3) return '${(micros / 1e3).toStringAsFixed(3)} ms';
    return '${micros.toStringAsFixed(2)} µs';
  }

  Widget _buildPlaybackBar(LogicAnalyzerStateProvider provider) {
    final double total =
        provider.recordingDurationUs <= 0 ? 1.0 : provider.recordingDurationUs;
    final double position = provider.playbackPositionUs.clamp(0.0, total);
    final bool atEnd = position >= total;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: provider.isPlaybackPaused
                ? appLocalizations.play
                : appLocalizations.pause,
            icon: Icon(
              provider.isPlaybackPaused || atEnd
                  ? Icons.play_arrow
                  : Icons.pause,
              color: Colors.white,
            ),
            onPressed: provider.togglePlaybackPause,
          ),
          Text(
            _formatDuration(position),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: position,
                min: 0,
                max: total,
                activeColor: primaryRed,
                inactiveColor: Colors.white24,
                onChanged: provider.seekPlayback,
              ),
            ),
          ),
          Text(
            _formatDuration(total),
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showRecordingDetails() {
    final entries = <MapEntry<String, String>>[];
    if (_provider.recordedAt != null) {
      entries.add(MapEntry(
        'Date Recorded',
        DateFormat('yyyy-MM-dd HH:mm:ss').format(_provider.recordedAt!),
      ));
    }
    if (widget.fileName != null) {
      entries.add(MapEntry('File', widget.fileName!));
    }
    entries.add(MapEntry('Channels', '${_provider.channelMode}'));
    if (_provider.analysisChannelNames.isNotEmpty) {
      entries.add(
          MapEntry('Channel Names', _provider.analysisChannelNames.join(', ')));
    }
    if (_provider.analysisEdgesNames.isNotEmpty) {
      entries.add(MapEntry('Edges', _provider.analysisEdgesNames.join(', ')));
    }
    entries.add(
        MapEntry('Duration', _formatDuration(_provider.recordingDurationUs)));
    final points =
        _provider.dataSets.fold<int>(0, (sum, set) => sum + set.length);
    entries.add(MapEntry('Data Points', '$points'));

    showModalBottomSheet(
      context: context,
      backgroundColor: scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final onSurface = Theme.of(context).colorScheme.onSurface;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.article_outlined, color: primaryRed, size: 24),
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
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final e in entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    e.key,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: onSurface,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    e.value,
                                    style: TextStyle(
                                        fontSize: 14, color: onSurface),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => _provider,
        ),
      ],
      child: Consumer<LogicAnalyzerStateProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              CommonScaffold(
                title: widget.playbackData != null
                    ? (widget.fileName ?? appLocalizations.logicAnalyzerTitle)
                    : appLocalizations.logicAnalyzerTitle,
                onOptionsPressed:
                    widget.playbackData != null ? null : _showOptionsMenu,
                onGuidePressed: _showInstrumentGuide,
                isPlayingBack: widget.playbackData != null,
                onPlaybackStop: widget.playbackData != null
                    ? () => Navigator.maybePop(context)
                    : null,
                body: SafeArea(
                  left: false,
                  right: false,
                  minimum: const EdgeInsets.only(right: 0, bottom: 0),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: chartBackgroundColor,
                          ),
                          padding: const EdgeInsets.only(bottom: 5, top: 5),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 73,
                                child: LogicAnalyzerGraph(),
                              ),
                              Expanded(
                                flex: 27,
                                child: LogicAnalyzerChannelSelection(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (provider.isPlayingBack) _buildPlaybackBar(provider),
                    ],
                  ),
                ),
                actions: widget.playbackData != null
                    ? [
                        IconButton(
                          tooltip: 'Recording details',
                          icon: const Icon(Icons.article_outlined,
                              color: Colors.white),
                          onPressed: _showRecordingDetails,
                        ),
                      ]
                    : [
                        IconButton(
                          icon: Icon(Icons.save, color: Colors.white),
                          tooltip: appLocalizations.saveData,
                          onPressed: () async {
                            if (!getIt.get<ScienceLab>().isConnected()) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      appLocalizations.notConnected,
                                      style: TextStyle(
                                          color: snackBarContentColor),
                                    ),
                                    backgroundColor: snackBarBackgroundColor,
                                  ),
                                );
                              }
                              return;
                            }
                            await _provider.logData();
                            if (!context.mounted) return;
                            final data = _provider.recordedData;
                            await ExportHelper.handleSaveData(
                              context: context,
                              instrumentName:
                                  appLocalizations.logicAnalyzer.toLowerCase(),
                              data: data,
                            );
                          },
                        ),
                      ],
              ),
              if (_showGuide)
                InstrumentOverviewDrawer(
                  instrumentName: appLocalizations.logicAnalyzer,
                  content: _getLogicAnalyzerContent(),
                  onHide: _hideInstrumentGuide,
                ),
            ],
          );
        },
      ),
    );
  }
}
